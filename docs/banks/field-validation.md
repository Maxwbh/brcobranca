# Validação de Campos por Banco - Referência Rápida

> **Tabela de Referência Rápida para Validação de Campos**
>
> Versão: 2025-11-25
>
> Use este documento para validar rapidamente os campos necessários para cada banco

---

## 📋 Índice

1. [Campos Base Obrigatórios](#campos-base-obrigatórios)
2. [Tabela Geral de Validações](#tabela-geral-de-validações)
3. [Campos Específicos por Banco](#campos-específicos-por-banco)
4. [Validação de Tamanhos](#validação-de-tamanhos)
5. [Checklist de Validação](#checklist-de-validação)

---

## Campos Base Obrigatórios

**Fonte:** `lib/brcobranca/boleto/base.rb:97-98`

Estes campos são obrigatórios para **TODOS** os bancos:

```
✅ agencia
✅ conta_corrente
✅ moeda (padrão: '9')
✅ especie_documento (padrão: 'DM', exceto Sicredi='A')
✅ especie (padrão: 'R$')
✅ aceite (padrão: 'S', exceto Sicoob/Unicred='N')
✅ nosso_numero
✅ sacado
✅ sacado_documento
```

**Campos com valor padrão aplicado automaticamente:**
- `data_processamento` → Date.current
- `data_vencimento` → Date.current
- `quantidade` → 1
- `valor` → 0.0
- `local_pagamento` → 'QUALQUER BANCO ATÉ O VENCIMENTO'

---

## Tabela Geral de Validações

| Banco | Código | Agência | Conta | Convenio | Nosso Nº | Campos Específicos |
|-------|--------|---------|-------|----------|----------|-------------------|
| Ailos | 085 | 4 | 8 | 6 (exato) | 9 | - |
| Banco do Brasil | 001 | 4 | 8 | 4-8 | 4-17* | - |
| BRB | 070 | **3** | 7 | - | 6 | nosso_numero_incremento (3) |
| Banco do Nordeste | 004 | 4 | 7 | - | 7 | digito_conta_corrente (1) |
| Banestes | 021 | 4 | **10** | - | 8 | digito_conta_corrente (1), variacao (1) |
| Banrisul | 041 | 4 | 8 | 7 | 8 | digito_convenio (2) |
| Bradesco | 237 | 4 | 7 | - | **11** | - |
| Caixa | 104 | 4 | - | 6 (exato) | **15** (exato) | emissao (1 exato) |
| Citibank | 745 | 4 | - | 10 (exato) | **11** (exato) | portfolio (3 exato) |
| Credisis | 097 | 4 | 7 | 6 (exato) | 6 | documento_cedente |
| HSBC | 399 | 4 | 7 | - | **13** | carteira in ['CNR','CSB'] |
| Itaú | 341 | 4 | **5** | 5 | 8 | seu_numero (7)** |
| Safra | 422 | 4 | 8 | - | 8 | agencia_dv (1), conta_corrente_dv (1) |
| Santander | 033 | 4 | 9 | 7 | 7 | convenio obrigatório |
| Sicoob | 756 | 4 | 8 | 7 | 7 | variacao (2), quantidade (3) |
| Sicredi | 748 | 4 | **5** | 5 | **5** | posto (2), byte_idt (1 exato) |
| Unicred | 136 | 4 | **9** | - | **10** | conta_corrente_dv |

**Legenda:**
- Números indicam quantidade máxima de dígitos
- **Negrito**: valores diferentes do padrão
- (exato): tamanho exato, não máximo
- \*Banco do Brasil: varia com tamanho do convenio
- \*\*Itaú: `seu_numero` apenas para carteiras especiais (198, 106, 107, 122, 142, 143, 195, 196)

---

## Campos Específicos por Banco

### Ailos (085)
```yaml
Obrigatórios específicos: nenhum
Validações:
  convenio: exatamente 6 dígitos
  carteira: exatamente 2 dígitos
Padrões:
  carteira: '1'
```

### Banco do Brasil (001)
```yaml
Obrigatórios específicos: nenhum
Validações complexas:
  convenio: entre 4 e 8 dígitos
  nosso_numero: tamanho varia com convenio
    - Conv 8 dígitos → Nosso Nº máx 9
    - Conv 7 dígitos → Nosso Nº máx 10
    - Conv 6 s/servico → Nosso Nº máx 5
    - Conv 6 c/servico → Nosso Nº máx 17
    - Conv 4 dígitos → Nosso Nº máx 7
Padrões:
  carteira: '18'
  codigo_servico: false
```

### Banco de Brasília - BRB (070)
```yaml
Obrigatórios específicos:
  - nosso_numero_incremento: 3 dígitos (obrigatório)
Validações:
  agencia: exatamente 3 dígitos (⚠️ diferente!)
  carteira: exatamente 1 dígito (1=Sem Registro, 2=Registrada)
  nosso_numero: máximo 6 dígitos
Padrões:
  carteira: '2'
  nosso_numero_incremento: '000'
```

### Banco do Nordeste (004)
```yaml
Obrigatórios específicos:
  - digito_conta_corrente: 1 dígito (obrigatório)
Validações:
  conta_corrente: máximo 7 dígitos
  nosso_numero: máximo 7 dígitos
Padrões:
  carteira: '21'
```

### Banestes (021)
```yaml
Obrigatórios específicos:
  - digito_conta_corrente: 1 dígito (obrigatório)
  - variacao: máximo 1 dígito (obrigatório)
Validações:
  conta_corrente: máximo 10 dígitos (⚠️ maior!)
  nosso_numero: máximo 8 dígitos
Padrões:
  carteira: '11'
  variacao: '2'
Observações:
  - Nosso número tem duplo DV (2 dígitos)
```

### Banrisul (041)
```yaml
Obrigatórios específicos:
  - digito_convenio: máximo 2 dígitos (obrigatório)
Validações:
  convenio: máximo 7 dígitos
  carteira: máximo 1 dígito (1=Normal, 2=Direta)
Padrões:
  carteira: '2'
Observações:
  - Usa método duplo_digito
```

### Bradesco (237)
```yaml
Obrigatórios específicos: nenhum
Validações:
  nosso_numero: máximo 11 dígitos (⚠️ grande!)
  carteira: máximo 2 dígitos
Padrões:
  carteira: '06'
Observações:
  - DV usa 'P' para resto 10
```

### Caixa Econômica Federal (104)
```yaml
Obrigatórios específicos:
  - emissao: exatamente 1 dígito (obrigatório, padrão='4')
Validações:
  convenio: exatamente 6 dígitos
  nosso_numero: exatamente 15 dígitos (⚠️ fixo!)
  carteira: exatamente 1 dígito (1=Registrada, 2=Sem Registro)
Padrões:
  carteira: '1'
  emissao: '4'
Observações:
  - Padrão SIGCB
  - Código de barras com montagem complexa
```

### Citibank (745)
```yaml
Obrigatórios específicos:
  - portfolio: exatamente 3 dígitos (obrigatório)
Validações:
  convenio: exatamente 10 dígitos (Conta Cosmos)
  nosso_numero: exatamente 11 dígitos
Padrões:
  carteira: '3'
Observações:
  - Convenio = Conta Cosmos (10 dígitos)
  - Portfolio = 3 últimos dígitos ID empresa
```

### Credisis (097)
```yaml
Obrigatórios específicos:
  - documento_cedente: CPF/CNPJ (obrigatório, validado)
Validações:
  convenio: exatamente 6 dígitos
  carteira: exatamente 2 dígitos
  nosso_numero: máximo 6 dígitos
  documento_cedente: numérico
Padrões:
  carteira: '18'
Observações:
  - DV documento usa mult 8 (CNPJ) ou 9 (CPF)
```

### HSBC (399)
```yaml
Obrigatórios específicos: nenhum
Validações:
  carteira: deve estar em ['CNR', 'CSB']
  nosso_numero: máximo 13 dígitos (⚠️ grande!)
  data_vencimento: obrigatória para CNR
Padrões:
  carteira: 'CNR'
Observações:
  - CNR usa dias julianos
  - Lógica diferente por carteira
```

### Itaú (341)
```yaml
Obrigatórios específicos:
  - seu_numero: 7 dígitos (apenas carteiras especiais)
Validações:
  conta_corrente: máximo 5 dígitos (⚠️ menor!)
  convenio: máximo 5 dígitos
  nosso_numero: máximo 8 dígitos
Padrões:
  carteira: '175'
Carteiras especiais (requerem seu_numero):
  - 198, 106, 107, 122, 142, 143, 195, 196
Observações:
  - Usa modulo10 para DVs
```

### Safra (422)
```yaml
Obrigatórios específicos:
  - agencia_dv: exatamente 1 dígito (obrigatório)
  - conta_corrente_dv: exatamente 1 dígito (obrigatório)
Validações:
  conta_corrente: máximo 8 dígitos
  nosso_numero: máximo 8 dígitos
Observações:
  - DVs fornecidos manualmente pelo banco
  - Modulo11 com reverse: false
```

### Santander (033)
```yaml
Obrigatórios específicos:
  - convenio: máximo 7 dígitos (obrigatório)
Validações:
  convenio: máximo 7 dígitos (Código do Cedente)
  nosso_numero: máximo 7 dígitos
Padrões:
  carteira: '102'
Observações:
  - Convenio = Código do Cedente
  - Conta corrente não exibida no boleto
```

### Sicoob (756)
```yaml
Obrigatórios específicos:
  - variacao: máximo 2 dígitos (obrigatório)
  - quantidade: máximo 3 dígitos (obrigatório)
Validações:
  convenio: máximo 7 dígitos
  nosso_numero: máximo 7 dígitos
Padrões:
  carteira: '1'
  variacao: '01'
  quantidade: '001'
  aceite: 'N' (⚠️ diferente do base!)
Observações:
  - DV usa constante 3197
  - quantidade = número da parcela
```

### Sicredi (748)
```yaml
Obrigatórios específicos:
  - posto: máximo 2 dígitos (obrigatório)
  - byte_idt: exatamente 1 dígito (obrigatório)
Validações:
  conta_corrente: máximo 5 dígitos (⚠️ pequena!)
  convenio: máximo 5 dígitos (Código Beneficiário)
  nosso_numero: máximo 5 dígitos
  carteira: máximo 1 dígito (1=Registro, 3=Sem Registro)
  byte_idt: 1=agência, 2-9=beneficiário
Padrões:
  carteira: '3'
  especie_documento: 'A' (⚠️ diferente!)
Observações:
  - Nosso número formato: AA/BXXXXX-D
  - Usa ano atual no nosso número
```

### Unicred (136)
```yaml
Obrigatórios específicos:
  - conta_corrente_dv: máximo 1 dígito (obrigatório)
Validações:
  conta_corrente: máximo 9 dígitos
  nosso_numero: máximo 10 dígitos (⚠️ grande!)
  carteira: sempre '21'
Padrões:
  carteira: '21'
  aceite: 'N' (⚠️ diferente do base!)
Observações:
  - Carteira sempre 21
```

---

## Validação de Tamanhos

### Campos com Tamanho EXATO (not máximo)

#### Agência
- **BRB (070)**: 3 dígitos (única exceção!)
- **Demais**: máximo 4 dígitos

#### Conta Corrente
| Tamanho | Bancos |
|---------|--------|
| 5 dígitos | Itaú, Sicredi |
| 7 dígitos | Padrão (Bradesco, Nordeste, Credisis, HSBC) |
| 8 dígitos | Ailos, BB, Banrisul, Safra, Sicoob |
| 9 dígitos | Santander, Unicred |
| 10 dígitos | Banestes, Citibank |

#### Nosso Número
| Tamanho | Bancos |
|---------|--------|
| 5 dígitos | BB (conv 6 s/serv), Sicredi |
| 6 dígitos | BRB, Credisis |
| 7 dígitos | BB (conv 4), Nordeste, Santander, Sicoob |
| 8 dígitos | Banestes, Banrisul, Itaú, Safra |
| 9 dígitos | Ailos, BB (conv 8) |
| 10 dígitos | BB (conv 7), Unicred |
| 11 dígitos | Bradesco, Citibank |
| 13 dígitos | HSBC |
| 15 dígitos (exato) | Caixa |
| 17 dígitos | BB (conv 6 c/serv) |

#### Convenio/Código Beneficiário
| Tamanho | Banco | Observação |
|---------|-------|------------|
| 4-8 dígitos | Banco do Brasil | Variável |
| 5 dígitos | Itaú, Sicredi | - |
| 6 dígitos (exato) | Ailos, Caixa, Credisis | Tamanho fixo |
| 7 dígitos | Banrisul, Sicoob, Santander | - |
| 10 dígitos (exato) | Citibank | Conta Cosmos |

---

## Checklist de Validação

### ✅ Antes de Enviar para API

#### 1. Campos Base Obrigatórios
```
☐ agencia (preenchida)
☐ conta_corrente (preenchida)
☐ moeda (padrão: '9')
☐ especie_documento (padrão: 'DM' ou 'A' para Sicredi)
☐ especie (padrão: 'R$')
☐ aceite (padrão: 'S', 'N' para Sicoob/Unicred)
☐ nosso_numero (preenchido)
☐ sacado (nome do pagador)
☐ sacado_documento (CPF/CNPJ)
☐ cedente (nome do beneficiário)
☐ documento_cedente (CPF/CNPJ)
☐ valor (maior que 0)
☐ data_vencimento (válida)
```

#### 2. Campos Específicos do Banco
```
☐ Verificar tabela acima para campos específicos obrigatórios
☐ Validar tamanhos (máximo vs exato)
☐ Verificar se carteiras especiais requerem campos adicionais
☐ Validar formato de DVs quando necessários
```

#### 3. Campos Opcionais
```
☐ documento_numero (incluir se disponível)
☐ cedente_endereco (recomendado)
☐ sacado_endereco (recomendado)
☐ instrucoes (incluir se fornecido)
☐ Não remover campos opcionais que tenham valor!
```

#### 4. Validações de Formato
```
☐ CPF/CNPJ são numéricos
☐ Valores monetários com 2 decimais
☐ Datas no formato correto
☐ Strings sem caracteres especiais problemáticos
```

---

## Erros Comuns

### ❌ Erro 1: Remover campos opcionais com valor
```python
# ERRADO!
payload = {k: v for k, v in data.items() if k not in ['documento_numero']}

# CORRETO!
payload = {k: v for k, v in data.items() if v is not None and v != ''}
```

### ❌ Erro 2: Não fornecer campos específicos obrigatórios
```python
# ERRADO! (Sicoob sem variacao/quantidade)
boleto = Sicoob.new(agencia: '1234', conta: '12345678')

# CORRETO!
boleto = Sicoob.new(
  agencia: '1234',
  conta: '12345678',
  variacao: '01',      # obrigatório
  quantidade: '001'    # obrigatório
)
```

### ❌ Erro 3: Confundir tamanho máximo com exato
```python
# ERRADO! (Caixa precisa de 15 dígitos exatos)
nosso_numero: '123'  # vai dar erro

# CORRETO!
nosso_numero: '000000000000123'  # 15 dígitos
```

### ❌ Erro 4: Usar aceite errado
```python
# CUIDADO! Sicoob e Unicred usam 'N' por padrão
# ERRADO para Sicoob:
aceite: 'S'  # vai funcionar mas não é padrão

# CORRETO para Sicoob:
aceite: 'N'  # padrão correto
```

---

## API Response - Campos Esperados no Retorno

Quando a API retorna sucesso, você receberá:

```json
{
  "codigo_barras": "string",
  "linha_digitavel": "string",
  "nosso_numero_dv": "string",
  "nosso_numero_boleto": "string",
  "agencia_conta_boleto": "string",
  "pdf_base64": "string"  // se solicitado
}
```

---

## Matriz de Compatibilidade

| Recurso | Bancos que Suportam |
|---------|---------------------|
| Convênio obrigatório | BB, Ailos, Caixa, Citibank, Credisis, Banrisul, Santander, Sicoob, Sicredi |
| DV manual de conta | Nordeste, Banestes, Safra, Unicred |
| DV manual de agência | Safra |
| Carteiras específicas | HSBC (CNR/CSB), Itaú (várias) |
| Campo adicional obrigatório | BRB, Nordeste, Banestes, Banrisul, Caixa, Citibank, Credisis, Safra, Sicoob, Sicredi, Unicred |
| Aceite='N' padrão | Sicoob, Unicred |
| Espécie Doc diferente | Sicredi ('A') |

---

## 🔗 Referências

- **Documentação Completa**: `CAMPOS_COMPLETOS_POR_BANCO.md`
- **Política de Campos**: `POLITICA_CAMPOS_BOLETO.md`
- **Correção Sicoob**: `BANCO_756_API_FIX.md`
- **Código Base**: `lib/brcobranca/boleto/base.rb`
- **Implementações**: `lib/brcobranca/boleto/{banco}.rb`

---

**Criado em:** 2025-11-25
**Última atualização:** 2025-11-25
**Bancos validados:** 17
**Status:** Documentação completa e validada
