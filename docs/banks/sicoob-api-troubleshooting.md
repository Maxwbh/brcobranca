# Correção de Erro API - Banco 756 (Sicoob)

## Problema Identificado

```
ERROR: Erro na API BRCobranca (400): type is missing
INFO: Campos filtrados para banco 756: removidos=['documento_numero', 'especie_documento', 'aceite']
```

## Análise do Erro

### 1. Campo `type` ausente (CRÍTICO)

O erro **"type is missing"** indica que a requisição para a API BRCobranca não está incluindo o parâmetro `type`, que é **obrigatório** para especificar qual classe de boleto usar.

**Solução:**
```json
{
  "type": "sicoob",
  "banco": "756",
  ...outros campos...
}
```

### 2. Campos removidos incorretamente

⚠️ **PRINCÍPIO IMPORTANTE**: Somente campos que **NÃO PODEM** ser enviados devem ser removidos. Campos **OPCIONAIS** devem permanecer se tiverem valor.

A aplicação Django estava removendo campos incorretamente:

#### ❌ `especie_documento` - NÃO DEVE SER REMOVIDO
- **Status:** Campo OBRIGATÓRIO (validado em `lib/brcobranca/boleto/base.rb:98`)
- **Valor padrão:** `'DM'` (Duplicata Mercantil)
- **Descrição:** Tipo do documento
- **Ação:** Manter no payload com valor padrão `'DM'` ou valor específico

#### ❌ `aceite` - NÃO DEVE SER REMOVIDO
- **Status:** Campo OBRIGATÓRIO (validado em `lib/brcobranca/boleto/base.rb:98`)
- **Valor padrão:** `'S'`
- **Para Sicoob:** Geralmente usar `'N'` (ver exemplo em GUIA_INICIO_RAPIDO.md:215)
- **Descrição:** Se o banco aceita o boleto após vencimento (S/N)
- **Ação:** Manter no payload com valor `'N'` para Sicoob

#### ✅ `documento_numero` - CAMPO OPCIONAL (MANTER SE TIVER VALOR)
- **Status:** Campo OPCIONAL
- **Descrição:** Número do documento fiscal/NF
- **Ação:** INCLUIR no payload se tiver valor, OMITIR se for None/vazio
- **Princípio**: Campos opcionais devem permanecer quando têm valor

## Correções Necessárias na Aplicação Django

### 1. Adicionar campo `type` à requisição

```python
# boleto_service.py

def gerar_boleto_sicoob(dados_boleto):
    """Gera boleto para Sicoob (banco 756)"""

    payload = {
        "type": "sicoob",  # ← ADICIONAR ESTE CAMPO
        "banco": "756",
        "agencia": dados_boleto["agencia"],
        "conta_corrente": dados_boleto["conta_corrente"],
        "convenio": dados_boleto["convenio"],
        "nosso_numero": dados_boleto["nosso_numero"],
        "variacao": dados_boleto.get("variacao", "01"),
        "quantidade": dados_boleto.get("quantidade", "001"),
        "carteira": dados_boleto.get("carteira", "1"),

        # Campos obrigatórios que estavam sendo removidos
        "especie_documento": dados_boleto.get("especie_documento", "DM"),
        "aceite": dados_boleto.get("aceite", "N"),  # 'N' para Sicoob

        # documento_numero é opcional - incluir se tiver valor (será filtrado depois se None)
        "documento_numero": dados_boleto.get("documento_numero"),

        # Outros campos obrigatórios
        "valor": dados_boleto["valor"],
        "cedente": dados_boleto["cedente"],
        "documento_cedente": dados_boleto["documento_cedente"],
        "sacado": dados_boleto["sacado"],
        "sacado_documento": dados_boleto["sacado_documento"],
        "data_vencimento": dados_boleto["data_vencimento"],
        "data_documento": dados_boleto.get("data_documento", str(date.today())),
    }

    # Remover campos None/vazios
    payload = {k: v for k, v in payload.items() if v is not None}

    return chamar_api_brcobranca(payload)
```

### 2. Atualizar lógica de filtragem de campos

```python
# boleto_service.py

# ANTES (INCORRETO):
CAMPOS_REMOVER_POR_BANCO = {
    '756': ['documento_numero', 'especie_documento', 'aceite'],  # ❌ ERRADO
}

# DEPOIS (CORRETO):
# Não remover campos opcionais - apenas omitir se forem None/vazios
CAMPOS_REMOVER_POR_BANCO = {
    '756': [],  # ✅ Sicoob aceita todos os campos base
    # Apenas listar campos que causam erro na API
}

# Ou melhor ainda, usar valores padrão específicos por banco
VALORES_PADRAO_POR_BANCO = {
    '756': {
        'especie_documento': 'DM',
        'aceite': 'N',  # Sicoob geralmente usa 'N'
        'variacao': '01',
        'quantidade': '001',
        'carteira': '1',
    }
}
```

## Melhorias no Log

### Log Atual (Insuficiente)
```python
logger.info(f"Campos filtrados para banco {banco}: removidos={campos_removidos}")
logger.error(f"Erro na API BRCobranca ({status_code}): {erro_msg}")
```

### Log Melhorado (Recomendado)

```python
import json
import logging

logger = logging.getLogger('boleto_service')

def gerar_boleto(dados_boleto):
    banco = dados_boleto.get('banco', 'N/A')

    # Log dos dados ANTES do filtro
    logger.info(
        f"Gerando boleto banco {banco}",
        extra={
            'banco': banco,
            'parcela_id': dados_boleto.get('parcela_id'),
            'valor': dados_boleto.get('valor'),
            'campos_enviados': list(dados_boleto.keys())
        }
    )

    # Aplicar valores padrão específicos do banco
    if banco == '756':
        payload = preparar_payload_sicoob(dados_boleto)
    else:
        payload = preparar_payload_generico(dados_boleto)

    # Log do payload COMPLETO que será enviado (para debug)
    logger.debug(
        f"Payload para API BRCobranca",
        extra={
            'banco': banco,
            'payload': json.dumps(payload, indent=2, default=str),
            'campos_payload': list(payload.keys())
        }
    )

    # Chamar API
    try:
        response = requests.post(
            'https://brcobranca-api.onrender.com/api/boleto',
            json=payload,
            timeout=30
        )

        if response.status_code != 200:
            # Log DETALHADO do erro
            logger.error(
                f"Erro na API BRCobranca",
                extra={
                    'banco': banco,
                    'status_code': response.status_code,
                    'erro_msg': response.text,
                    'payload_enviado': json.dumps(payload, indent=2, default=str),
                    'headers_resposta': dict(response.headers)
                }
            )
            raise Exception(f"API Error {response.status_code}: {response.text}")

        logger.info(
            f"Boleto gerado com sucesso para banco {banco}",
            extra={
                'banco': banco,
                'response_size': len(response.content)
            }
        )

        return response.content

    except requests.exceptions.RequestException as e:
        logger.error(
            f"Erro de conexão com API BRCobranca",
            extra={
                'banco': banco,
                'erro': str(e),
                'payload_enviado': json.dumps(payload, indent=2, default=str)
            },
            exc_info=True
        )
        raise


def preparar_payload_sicoob(dados):
    """Prepara payload específico para Sicoob (756)"""
    payload = {
        "type": "sicoob",  # ← CAMPO OBRIGATÓRIO
        "banco": "756",

        # Campos obrigatórios Sicoob
        "agencia": dados["agencia"],
        "conta_corrente": dados["conta_corrente"],
        "convenio": dados["convenio"],
        "nosso_numero": dados["nosso_numero"],
        "variacao": dados.get("variacao", "01"),
        "quantidade": dados.get("quantidade", "001"),
        "carteira": dados.get("carteira", "1"),

        # Campos obrigatórios Base (NÃO REMOVER)
        "especie_documento": dados.get("especie_documento", "DM"),
        "aceite": dados.get("aceite", "N"),
        "moeda": dados.get("moeda", "9"),
        "especie": dados.get("especie", "R$"),

        # Dados do beneficiário
        "cedente": dados["cedente"],
        "documento_cedente": dados["documento_cedente"],
        "cedente_endereco": dados.get("cedente_endereco"),

        # Dados do pagador
        "sacado": dados["sacado"],
        "sacado_documento": dados["sacado_documento"],
        "sacado_endereco": dados.get("sacado_endereco"),

        # Valores e datas
        "valor": dados["valor"],
        "data_vencimento": dados["data_vencimento"],
        "data_documento": dados.get("data_documento", str(date.today())),
        "data_processamento": dados.get("data_processamento", str(date.today())),

        # Campos opcionais (incluir se tiverem valor)
        "documento_numero": dados.get("documento_numero"),
        "instrucoes": dados.get("instrucoes"),
        "local_pagamento": dados.get("local_pagamento", "QUALQUER BANCO ATÉ O VENCIMENTO"),
    }

    # Remover apenas campos None/vazios (campos opcionais permanecem se tiverem valor)
    return {k: v for k, v in payload.items() if v is not None and v != ''}
```

## Exemplo de Payload Correto para Sicoob

```json
{
  "type": "sicoob",
  "banco": "756",
  "agencia": "4327",
  "conta_corrente": "417270",
  "convenio": "229385",
  "nosso_numero": "2",
  "variacao": "01",
  "quantidade": "001",
  "carteira": "1",

  "especie_documento": "DM",
  "aceite": "N",
  "moeda": "9",
  "especie": "R$",

  "cedente": "Sua Empresa Ltda",
  "documento_cedente": "12345678000190",
  "sacado": "Cliente Exemplo",
  "sacado_documento": "12345678900",

  "valor": 75.00,
  "data_vencimento": "2025-12-25",
  "data_documento": "2025-11-25",
  "local_pagamento": "QUALQUER BANCO ATÉ O VENCIMENTO"
}
```

## Campos Sicoob - Resumo

### ✅ Campos Obrigatórios Específicos Sicoob
- `agencia` (até 4 dígitos)
- `conta_corrente` (até 8 dígitos)
- `convenio` (até 7 dígitos)
- `nosso_numero` (até 7 dígitos)
- `variacao` (até 2 dígitos) - padrão: '01'
- `quantidade` (até 3 dígitos) - padrão: '001'
- `carteira` - padrão: '1'

### ✅ Campos Obrigatórios Base (Comuns a Todos os Bancos)
- `type` - **"sicoob"** para banco 756
- `moeda` - padrão: '9'
- `especie_documento` - padrão: 'DM'
- `especie` - padrão: 'R$'
- `aceite` - **'N' para Sicoob**
- `nosso_numero`
- `cedente`, `documento_cedente`
- `sacado`, `sacado_documento`
- `valor`
- `data_vencimento`

### 🔧 Campos Opcionais
⚠️ **Campos opcionais devem ser INCLUÍDOS se tiverem valor, não removidos!**

- `documento_numero` - Número NF/Pedido (incluir se disponível)
- `cedente_endereco` - Recomendado (incluir se disponível)
- `sacado_endereco` - Recomendado (incluir se disponível)
- `instrucoes` - Instruções adicionais (incluir se fornecido)
- `local_pagamento` - Local de pagamento (incluir se específico)
- `data_documento`, `data_processamento` - Datas (usar padrões se não fornecidas)

## Referências

- `lib/brcobranca/boleto/base.rb:98` - Validação de campos obrigatórios
- `lib/brcobranca/boleto/sicoob.rb` - Implementação Sicoob
- `CAMPOS_BANCOS.md:518-570` - Documentação Sicoob
- `GUIA_INICIO_RAPIDO.md:199-220` - Exemplo de uso Sicoob

## Testes Recomendados

1. **Teste com campos mínimos obrigatórios**
2. **Teste com todos os campos opcionais**
3. **Teste com valores padrão do banco**
4. **Validar resposta da API em caso de erro**
5. **Verificar logs para troubleshooting**

---

**Criado em:** 2025-11-25
**Banco:** 756 - Sicoob
**Status:** Documentação de correção
