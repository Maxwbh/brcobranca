# Política de Campos em Boletos - BRCobranca

## Princípio Fundamental

> **IMPORTANTE**: Somente campos que **NÃO PODEM** ser enviados devem ser removidos do payload. Campos **OPCIONAIS** devem permanecer se tiverem valor.

## Categorias de Campos

### 1. 🔴 Campos OBRIGATÓRIOS
Definidos em `lib/brcobranca/boleto/base.rb:98` via `validates_presence_of`:

```ruby
validates_presence_of :agencia, :conta_corrente, :moeda, :especie_documento,
                      :especie, :aceite, :nosso_numero, :sacado, :sacado_documento
```

**Ação**: NUNCA remover. Sempre devem ter valor (padrão ou fornecido).

**Exemplos**:
- ✅ `aceite`: 'S' ou 'N' (para Sicoob use 'N')
- ✅ `especie_documento`: 'DM', 'DS', 'NP', etc.
- ✅ `especie`: 'R$'
- ✅ `moeda`: '9'

### 2. 🟡 Campos OPCIONAIS
Campos não listados em `validates_presence_of`.

**Ação**: INCLUIR se tiverem valor, OMITIR se forem None/vazios/null.

**Exemplos**:
- 🟡 `documento_numero`: Número NF/Pedido - incluir se disponível
- 🟡 `instrucoes`: Instruções adicionais - incluir se fornecido
- 🟡 `cedente_endereco`: Endereço do beneficiário - recomendado
- 🟡 `sacado_endereco`: Endereço do pagador - recomendado

### 3. 🔵 Campos Específicos do Banco
Cada banco pode ter campos específicos obrigatórios ou opcionais.

**Sicoob (756)**:
```ruby
# Campos específicos obrigatórios
- agencia (até 4 dígitos)
- conta_corrente (até 8 dígitos)
- convenio (até 7 dígitos)
- variacao (padrão: '01')
- quantidade (padrão: '001')
- carteira (padrão: '1')
```

### 4. ⛔ Campos que NÃO PODEM ser Enviados
Apenas estes devem ser explicitamente removidos:
- Campos que causam erro 400/422 na API
- Campos deprecados para um banco específico
- Campos incompatíveis com o tipo de boleto

## Lógica de Filtragem Correta

### ❌ INCORRETO - Remover campos opcionais válidos
```python
# NÃO FAÇA ISSO!
CAMPOS_REMOVER_POR_BANCO = {
    '756': ['documento_numero', 'especie_documento', 'aceite'],  # ERRADO!
}
```

### ✅ CORRETO - Manter campos opcionais, remover apenas inválidos
```python
# Abordagem 1: Usar valores padrão para obrigatórios
VALORES_PADRAO_POR_BANCO = {
    '756': {  # Sicoob
        'aceite': 'N',              # Obrigatório - valor específico Sicoob
        'especie_documento': 'DM',  # Obrigatório - valor padrão
        'variacao': '01',           # Específico Sicoob
        'quantidade': '001',        # Específico Sicoob
        'carteira': '1',            # Específico Sicoob
    }
}

# Abordagem 2: Remover apenas campos inválidos (se houver)
CAMPOS_INVALIDOS_POR_BANCO = {
    '756': [],  # Sicoob aceita todos os campos base
    # Exemplo hipotético:
    # '001': ['campo_x', 'campo_y'],  # Se banco 001 não aceitar estes
}

def preparar_payload(dados, banco):
    payload = {
        **VALORES_PADRAO_POR_BANCO.get(banco, {}),
        **dados,  # Sobrescreve padrões com valores fornecidos
    }

    # Remover apenas campos None/vazios E campos inválidos para o banco
    campos_invalidos = CAMPOS_INVALIDOS_POR_BANCO.get(banco, [])

    payload_limpo = {
        k: v for k, v in payload.items()
        if v is not None and v != '' and k not in campos_invalidos
    }

    return payload_limpo
```

## Exemplos Práticos

### Exemplo 1: Sicoob com documento_numero
```python
dados = {
    'banco': '756',
    'agencia': '4327',
    'conta_corrente': '417270',
    'convenio': '229385',
    'nosso_numero': '2',
    'documento_numero': 'NF-001234',  # ← OPCIONAL, mas tem valor
    'valor': 75.00,
    # ... outros campos
}

payload = preparar_payload_sicoob(dados)

# Resultado CORRETO:
{
    'type': 'sicoob',
    'banco': '756',
    'aceite': 'N',              # Adicionado (obrigatório)
    'especie_documento': 'DM',  # Adicionado (obrigatório)
    'documento_numero': 'NF-001234',  # ← MANTIDO (opcional com valor)
    # ... outros campos
}
```

### Exemplo 2: Sicoob sem documento_numero
```python
dados = {
    'banco': '756',
    'agencia': '4327',
    'conta_corrente': '417270',
    'convenio': '229385',
    'nosso_numero': '2',
    'documento_numero': None,  # ← OPCIONAL, sem valor
    'valor': 75.00,
    # ... outros campos
}

payload = preparar_payload_sicoob(dados)

# Resultado CORRETO:
{
    'type': 'sicoob',
    'banco': '756',
    'aceite': 'N',              # Adicionado (obrigatório)
    'especie_documento': 'DM',  # Adicionado (obrigatório)
    # documento_numero omitido (None)  # ← OMITIDO (opcional sem valor)
    # ... outros campos
}
```

## Fluxograma de Decisão

```
Para cada campo no payload:
│
├─ É obrigatório (validates_presence_of)?
│  ├─ SIM → INCLUIR sempre (com valor padrão se necessário)
│  └─ NÃO → Continuar
│
├─ É inválido para este banco específico?
│  ├─ SIM → REMOVER
│  └─ NÃO → Continuar
│
├─ Tem valor (not None, not '')?
│  ├─ SIM → INCLUIR
│  └─ NÃO → OMITIR
```

## Resumo

| Tipo de Campo | Ação | Exemplo |
|---------------|------|---------|
| 🔴 Obrigatório | SEMPRE incluir | `aceite`, `especie_documento` |
| 🟡 Opcional com valor | INCLUIR | `documento_numero: 'NF-001'` |
| 🟡 Opcional sem valor | OMITIR | `documento_numero: None` |
| ⛔ Inválido para banco | REMOVER | (depende do banco) |

## Referências

- Validações obrigatórias: `lib/brcobranca/boleto/base.rb:98`
- Campos Sicoob: `lib/brcobranca/boleto/sicoob.rb`
- Documentação campos: `CAMPOS_BANCOS.md`
- Correção erro 756: `BANCO_756_API_FIX.md`

---

**Última atualização**: 2025-11-25
**Princípio**: Incluir campos opcionais com valor, remover apenas o que é inválido
