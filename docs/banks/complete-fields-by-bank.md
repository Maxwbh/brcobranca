# Campos Completos por Banco - BRCobranca

> **Documentação Completa e Validada de Todos os Campos para Cada Banco**
>
> Versão: 2025-11-25
>
> 📋 **17 Bancos Documentados**

---

## 📖 Índice

1. [Campos Base (Comuns a Todos os Bancos)](#campos-base)
2. [Ailos - 085](#banco-085---ailos)
3. [Banco do Brasil - 001](#banco-001---banco-do-brasil)
4. [Banco de Brasília (BRB) - 070](#banco-070---banco-de-brasília-brb)
5. [Banco do Nordeste - 004](#banco-004---banco-do-nordeste)
6. [Banestes - 021](#banco-021---banestes)
7. [Banrisul - 041](#banco-041---banrisul)
8. [Bradesco - 237](#banco-237---bradesco)
9. [Caixa Econômica Federal - 104](#banco-104---caixa-econômica-federal)
10. [Citibank - 745](#banco-745---citibank)
11. [Credisis - 097](#banco-097---credisis)
12. [HSBC - 399](#banco-399---hsbc)
13. [Itaú - 341](#banco-341---itaú)
14. [Safra - 422](#banco-422---safra)
15. [Santander - 033](#banco-033---santander)
16. [Sicoob - 756](#banco-756---sicoob)
17. [Sicredi - 748](#banco-748---sicredi)
18. [Unicred - 136](#banco-136---unicred)

---

## Campos Base

Definidos em `lib/brcobranca/boleto/base.rb`

### 🔴 Campos Base OBRIGATÓRIOS

Validados em `base.rb:97-98`:
```ruby
validates_presence_of :agencia, :conta_corrente, :moeda, :especie_documento,
                      :especie, :aceite, :nosso_numero, :sacado, :sacado_documento
```

| Campo | Tipo | Descrição | Valor Padrão | Validação |
|-------|------|-----------|--------------|-----------|
| `agencia` | String | Número da agência (sem DV) | - | Obrigatório |
| `conta_corrente` | String | Número da conta corrente (sem DV) | - | Obrigatório |
| `moeda` | String | Tipo de moeda (Real = 9) | '9' | Obrigatório |
| `especie_documento` | String | Tipo do documento (DM, DS, NP, etc.) | 'DM' | Obrigatório |
| `especie` | String | Símbolo da moeda | 'R$' | Obrigatório |
| `aceite` | String | Aceite após vencimento (S/N) | 'S' | Obrigatório |
| `nosso_numero` | String | Identificador único do boleto | - | Obrigatório |
| `sacado` | String | Nome do pagador | - | Obrigatório |
| `sacado_documento` | String | CPF/CNPJ do pagador | - | Obrigatório |

**Campos adicionais obrigatórios (padrão aplicado em `base.rb:105-114`):**
- `data_processamento` - Padrão: Date.current
- `data_vencimento` - Padrão: Date.current
- `quantidade` - Padrão: 1
- `valor` - Padrão: 0.0
- `local_pagamento` - Padrão: 'QUALQUER BANCO ATÉ O VENCIMENTO'

### 🟡 Campos Base OPCIONAIS

| Campo | Tipo | Descrição | Validação |
|-------|------|-----------|-----------|
| `convenio` | String | Número do convênio/contrato | Numérico (allow_nil: true) |
| `carteira` | String | Tipo de carteira | - |
| `carteira_label` | String | Rótulo da carteira (RG/SR) | - |
| `variacao` | String | Variação da carteira | - |
| `data_documento` | Date | Data do documento origem | - |
| `documento_numero` | String | Número NF/Pedido/Contrato | - |
| `codigo_servico` | Boolean/String | Código do serviço | - |
| `demonstrativo` | String | Informação ao sacado | - |
| `instrucoes` | String | Instruções ao caixa | - |
| `instrucao1` a `instrucao7` | String | Instruções individuais | - |
| `cedente` | String | Nome do beneficiário | - |
| `documento_cedente` | String | CPF/CNPJ do beneficiário | Numérico (allow_nil: true) |
| `cedente_endereco` | String | Endereço do beneficiário | - |
| `sacado_endereco` | String | Endereço do pagador | - |
| `avalista` | String | Nome do avalista | - |
| `avalista_documento` | String | Documento do avalista | - |
| `emv` | String | QRCode PIX | - |
| `descontos_e_abatimentos` | String | Descontos/abatimentos | - |

---

## Banco 085 - Ailos

**Nome:** Ailos
**Código:** 085
**DV Banco:** 1 (fixo)
**Arquivo:** `lib/brcobranca/boleto/ailos.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 4 dígitos | String | Número da agência (máx 4) |
| `conta_corrente` | 8 dígitos | String | Número da conta (máx 8) |
| `convenio` | 6 dígitos | String | Código do convênio (exato: 6) |
| `nosso_numero` | 9 dígitos | String | Número do boleto (máx 9) |
| `carteira` | 2 dígitos | String | Tipo de carteira (exato: 2) |

**Campos obrigatórios herdados do base:**
- moeda, especie_documento, especie, aceite, sacado, sacado_documento

### 🟡 Campos Opcionais
- Todos os campos opcionais do base.rb

### ⚙️ Valores Padrão
```ruby
{
  carteira: '1',
  local_pagamento: 'Pagar preferencialmente nas cooperativas do Sistema AILOS.'
}
```

### ✅ Exemplo de Uso
```ruby
boleto = Brcobranca::Boleto::Ailos.new(
  # Obrigatórios
  agencia: '1234',
  conta_corrente: '12345678',
  convenio: '123456',
  nosso_numero: '123456789',
  valor: 100.00,
  cedente: 'Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Nome',
  sacado_documento: '12345678900',
  data_vencimento: Date.today + 30,

  # Opcionais
  documento_numero: 'NF-001',
  instrucoes: 'Não receber após vencimento'
)
```

**Referência:** `lib/brcobranca/boleto/ailos.rb`

---

## Banco 001 - Banco do Brasil

**Nome:** Banco do Brasil
**Código:** 001
**DV Banco:** calculado (modulo11, mapeamento {10 => 'X'})
**Arquivo:** `lib/brcobranca/boleto/banco_brasil.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 4 dígitos | String | Número da agência (máx 4) |
| `conta_corrente` | 8 dígitos | String | Número da conta (máx 8) |
| `convenio` | 4-8 dígitos | Integer | Convênio (in: 4..8) |
| `nosso_numero` | Variável | String | Depende do tamanho do convênio |
| `carteira` | 2 dígitos | String | Tipo de carteira (máx 2) |

**Campos obrigatórios herdados do base:**
- moeda, especie_documento, especie, aceite, sacado, sacado_documento

### 📏 Validação Complexa - Nosso Número

O tamanho do `nosso_numero` varia conforme o convênio:

| Convênio | Tamanho Nosso Número | Observações |
|----------|---------------------|-------------|
| 8 dígitos | máx 9 dígitos | Formato mais comum |
| 7 dígitos | máx 10 dígitos | - |
| 6 dígitos (sem codigo_servico) | máx 5 dígitos | - |
| 6 dígitos (com codigo_servico) | máx 17 dígitos | Carteiras 16 ou 18 apenas |
| 4 dígitos | máx 7 dígitos | Convênios antigos |

### 🟡 Campos Opcionais

| Campo | Descrição | Padrão |
|-------|-----------|--------|
| `codigo_servico` | Código de serviço | false |
| Todos os campos opcionais do base.rb | - | - |

### ⚙️ Valores Padrão
```ruby
{
  carteira: '18',
  codigo_servico: false,
  local_pagamento: 'PAGÁVEL EM QUALQUER BANCO.'
}
```

### ✅ Exemplo de Uso - Convênio 8 Dígitos
```ruby
boleto = Brcobranca::Boleto::BancoBrasil.new(
  # Obrigatórios
  agencia: '4042',
  conta_corrente: '61900',
  convenio: 12387989,  # 8 dígitos
  nosso_numero: '777700168',  # máx 9 dígitos
  carteira: '18',
  valor: 135.00,
  cedente: 'Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Nome',
  sacado_documento: '12345678900',
  data_vencimento: Date.parse('2025-12-25'),

  # Opcionais
  documento_numero: 'NF-001234',
  instrucoes: 'Multa de 2% após vencimento'
)
```

### ✅ Exemplo de Uso - Convênio 6 Dígitos com Código Serviço
```ruby
boleto = Brcobranca::Boleto::BancoBrasil.new(
  agencia: '4042',
  conta_corrente: '61900',
  convenio: 123456,  # 6 dígitos
  carteira: '16',  # ou '18'
  codigo_servico: true,
  nosso_numero: '12345678901234567',  # até 17 dígitos
  # ... outros campos
)
```

**Referência:** `lib/brcobranca/boleto/banco_brasil.rb`

---

## Banco 070 - Banco de Brasília (BRB)

**Nome:** Banco de Brasília (BRB)
**Código:** 070
**DV Banco:** calculado (modulo11)
**Arquivo:** `lib/brcobranca/boleto/banco_brasilia.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 3 dígitos | String | Número da agência (**exato: 3**) |
| `conta_corrente` | 7 dígitos | String | Número da conta (máx 7) |
| `carteira` | 1 dígito | String | Modalidade (**exato: 1**) |
| `nosso_numero` | 6 dígitos | String | Número do boleto (máx 6) |
| `nosso_numero_incremento` | 3 dígitos | String | Incremento Campo Livre (**obrigatório**) |

**Modalidade (carteira):**
- 1 = Sem Registro
- 2 = Registrada

**Campos obrigatórios herdados do base:**
- moeda, especie_documento, especie, aceite, sacado, sacado_documento

### 🟡 Campos Opcionais
- Todos os campos opcionais do base.rb

### ⚙️ Valores Padrão
```ruby
{
  carteira: '2',
  nosso_numero_incremento: '000',
  local_pagamento: 'PAGÁVEL EM QUALQUER BANCO ATÉ O VENCIMENTO'
}
```

### ✅ Exemplo de Uso
```ruby
boleto = Brcobranca::Boleto::BancoBrasilia.new(
  # Obrigatórios
  agencia: '123',  # 3 dígitos apenas!
  conta_corrente: '1234567',
  carteira: '2',  # 1=Sem Registro, 2=Registrada
  nosso_numero: '123456',
  nosso_numero_incremento: '000',
  valor: 100.00,
  cedente: 'Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Nome',
  sacado_documento: '12345678900',
  data_vencimento: Date.today + 30
)
```

**⚠️ Observações Importantes:**
- Agência tem apenas 3 dígitos (diferente do padrão de 4)
- Campo `nosso_numero_incremento` é exclusivo do BRB e obrigatório
- Usa método `duplo_digito` para calcular 2 DVs

**Referência:** `lib/brcobranca/boleto/banco_brasilia.rb`

---

## Banco 004 - Banco do Nordeste

**Nome:** Banco do Nordeste
**Código:** 004
**DV Banco:** calculado (modulo11)
**Arquivo:** `lib/brcobranca/boleto/banco_nordeste.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 4 dígitos | String | Número da agência (máx 4) |
| `conta_corrente` | 7 dígitos | String | Número da conta (máx 7) |
| `digito_conta_corrente` | 1 dígito | String | DV da conta (**exato: 1, obrigatório**) |
| `carteira` | 2 dígitos | String | Tipo de carteira (máx 2) |
| `nosso_numero` | 7 dígitos | String | Número do boleto (máx 7) |

**Campos obrigatórios herdados do base:**
- moeda, especie_documento, especie, aceite, sacado, sacado_documento

### 🟡 Campos Opcionais
- Todos os campos opcionais do base.rb

### ⚙️ Valores Padrão
```ruby
{
  carteira: '21'
}
```

### ✅ Exemplo de Uso
```ruby
boleto = Brcobranca::Boleto::BancoNordeste.new(
  # Obrigatórios
  agencia: '1234',
  conta_corrente: '1234567',
  digito_conta_corrente: '5',  # DV fornecido pelo banco
  carteira: '21',
  nosso_numero: '1234567',
  valor: 100.00,
  cedente: 'Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Nome',
  sacado_documento: '12345678900',
  data_vencimento: Date.today + 30
)
```

**⚠️ Observações Importantes:**
- Requer `digito_conta_corrente` fornecido manualmente
- DV do nosso número usa multiplicador (2..8)

**Referência:** `lib/brcobranca/boleto/banco_nordeste.rb`

---

## Banco 021 - Banestes

**Nome:** Banestes (Banco do Estado do Espírito Santo)
**Código:** 021
**DV Banco:** 3 (fixo)
**Arquivo:** `lib/brcobranca/boleto/banestes.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 4 dígitos | String | Número da agência (máx 4) |
| `conta_corrente` | 10 dígitos | String | Número da conta (máx 10) |
| `digito_conta_corrente` | 1 dígito | String | DV da conta (**exato: 1, obrigatório**) |
| `nosso_numero` | 8 dígitos | String | Número do boleto (máx 8) |
| `variacao` | 1 dígito | String | Variação (máx 1) |
| `carteira` | 2 dígitos | String | Tipo de carteira (máx 2) |

**Campos obrigatórios herdados do base:**
- moeda, especie_documento, especie, aceite, sacado, sacado_documento

### 🟡 Campos Opcionais
- Todos os campos opcionais do base.rb

### ⚙️ Valores Padrão
```ruby
{
  carteira: '11',
  variacao: '2'
}
```

### ✅ Exemplo de Uso
```ruby
boleto = Brcobranca::Boleto::Banestes.new(
  # Obrigatórios
  agencia: '1234',
  conta_corrente: '1234567890',  # 10 dígitos
  digito_conta_corrente: '5',
  nosso_numero: '12345678',  # 8 dígitos
  variacao: '2',
  valor: 100.00,
  cedente: 'Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Nome',
  sacado_documento: '12345678900',
  data_vencimento: Date.today + 30
)
```

**⚠️ Observações Importantes:**
- Conta corrente tem 10 dígitos (maior que o padrão)
- Nosso número tem duplo DV (2 dígitos verificadores)
- Requer `digito_conta_corrente` fornecido manualmente

**Referência:** `lib/brcobranca/boleto/banestes.rb`

---

## Banco 041 - Banrisul

**Nome:** Banrisul (Banco do Estado do Rio Grande do Sul)
**Código:** 041
**DV Banco:** 8 (fixo)
**Arquivo:** `lib/brcobranca/boleto/banrisul.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 4 dígitos | String | Número da agência (máx 4) |
| `conta_corrente` | 8 dígitos | String | Número da conta (máx 8) |
| `convenio` | 7 dígitos | String | Código do convênio (máx 7) |
| `digito_convenio` | 2 dígitos | String | DV do convênio (**obrigatório**) |
| `nosso_numero` | 8 dígitos | String | Número do boleto (máx 8) |
| `carteira` | 1 dígito | String | Produto (máx 1) |

**Produto (carteira):**
- 1 = Cobrança Normal (fichário Banrisul)
- 2 = Cobrança Direta (fichário cliente)

**Campos obrigatórios herdados do base:**
- moeda, especie_documento, especie, aceite, sacado, sacado_documento

### 🟡 Campos Opcionais
- Todos os campos opcionais do base.rb

### ⚙️ Valores Padrão
```ruby
{
  carteira: '2'
}
```

### ✅ Exemplo de Uso
```ruby
boleto = Brcobranca::Boleto::Banrisul.new(
  # Obrigatórios
  agencia: '1234',
  conta_corrente: '12345678',
  convenio: '1234567',
  digito_convenio: '12',  # 2 dígitos
  nosso_numero: '12345678',
  carteira: '2',  # 1=Normal, 2=Direta
  valor: 100.00,
  cedente: 'Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Nome',
  sacado_documento: '12345678900',
  data_vencimento: Date.today + 30
)
```

**⚠️ Observações Importantes:**
- Requer `digito_convenio` com 2 dígitos
- Usa método `duplo_digito`
- Usa constante "40" no código de barras

**Referência:** `lib/brcobranca/boleto/banrisul.rb`

---

## Banco 237 - Bradesco

**Nome:** Bradesco
**Código:** 237
**DV Banco:** calculado (modulo11)
**Arquivo:** `lib/brcobranca/boleto/bradesco.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 4 dígitos | String | Número da agência (máx 4) |
| `conta_corrente` | 7 dígitos | String | Número da conta (máx 7) |
| `nosso_numero` | 11 dígitos | String | Número do boleto (máx 11) |
| `carteira` | 2 dígitos | String | Tipo de carteira (máx 2) |

**Campos obrigatórios herdados do base:**
- moeda, especie_documento, especie, aceite, sacado, sacado_documento

### 🟡 Campos Opcionais
- Todos os campos opcionais do base.rb

### ⚙️ Valores Padrão
```ruby
{
  carteira: '06',
  local_pagamento: 'Pagável preferencialmente na Rede Bradesco ou Bradesco Expresso'
}
```

### ✅ Exemplo de Uso
```ruby
boleto = Brcobranca::Boleto::Bradesco.new(
  # Obrigatórios
  agencia: '1234',
  conta_corrente: '1234567',
  nosso_numero: '12345678901',  # 11 dígitos
  carteira: '06',
  valor: 100.00,
  cedente: 'Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Nome',
  sacado_documento: '12345678900',
  data_vencimento: Date.today + 30
)
```

**⚠️ Observações Importantes:**
- Nosso número tem 11 dígitos (um dos maiores)
- DV usa 'P' como mapeamento para resto 10
- Formato nosso número no boleto: `carteira/nosso_numero-DV`

**Referência:** `lib/brcobranca/boleto/bradesco.rb`

---

## Banco 104 - Caixa Econômica Federal

**Nome:** Caixa Econômica Federal
**Código:** 104
**DV Banco:** 0 (fixo)
**Arquivo:** `lib/brcobranca/boleto/caixa.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 4 dígitos | String | Número da agência (máx 4) |
| `convenio` | 6 dígitos | String | Código do beneficiário (**exato: 6**) |
| `nosso_numero` | 15 dígitos | String | Número do boleto (**exato: 15**) |
| `carteira` | 1 dígito | String | Tipo de carteira (**exato: 1**) |
| `emissao` | 1 dígito | String | Emissão (**exato: 1, obrigatório**) |

**Carteira:**
- 1 = Registrada
- 2 = Sem Registro

**Emissão:**
- 4 = Beneficiário (padrão)

**Campos obrigatórios herdados do base:**
- moeda, especie_documento, especie, aceite, sacado, sacado_documento

### 🟡 Campos Opcionais
- Todos os campos opcionais do base.rb

### ⚙️ Valores Padrão
```ruby
{
  carteira: '1',
  carteira_label: 'RG',
  emissao: '4',
  local_pagamento: 'PREFERENCIALMENTE NAS CASAS LOTÉRICAS ATÉ O VALOR LIMITE'
}
```

### ✅ Exemplo de Uso
```ruby
boleto = Brcobranca::Boleto::Caixa.new(
  # Obrigatórios
  agencia: '1234',
  convenio: '123456',  # exatamente 6 dígitos
  nosso_numero: '123456789012345',  # exatamente 15 dígitos
  carteira: '1',  # 1 dígito: 1=Registrada, 2=Sem Registro
  emissao: '4',  # 1 dígito: 4=Beneficiário
  valor: 100.00,
  cedente: 'Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Nome',
  sacado_documento: '12345678900',
  data_vencimento: Date.today + 30
)
```

**⚠️ Observações Importantes:**
- Padrão SIGCB (substitui SICOB)
- Nosso número tem 15 dígitos fixos
- Código de barras tem montagem complexa "embaralhando" posições
- Formato nosso número completo: `carteira + emissao + 15 dígitos + DV` = 18 caracteres

**Referência:** `lib/brcobranca/boleto/caixa.rb`

---

## Banco 745 - Citibank

**Nome:** Citibank
**Código:** 745
**DV Banco:** 5 (fixo)
**Arquivo:** `lib/brcobranca/boleto/citibank.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 4 dígitos | String | Número da agência (máx 4) |
| `convenio` | 10 dígitos | String | Conta Cosmos (**exato: 10**) |
| `nosso_numero` | 11 dígitos | String | Número do boleto (**exato: 11**) |
| `portfolio` | 3 dígitos | String | Portfolio (**exato: 3, obrigatório**) |

**Conta Cosmos:** Formato Índice.Base.Sequência.DV (ex: 0.123456.78.9)

**Portfolio:** 3 últimos dígitos da identificação da empresa

**Campos obrigatórios herdados do base:**
- moeda, especie_documento, especie, aceite, sacado, sacado_documento

### 🟡 Campos Opcionais
- Todos os campos opcionais do base.rb

### ⚙️ Valores Padrão
```ruby
{
  carteira: '3',
  carteira_label: '3'
}
```

### ✅ Exemplo de Uso
```ruby
boleto = Brcobranca::Boleto::Citibank.new(
  # Obrigatórios
  agencia: '1234',
  convenio: '0123456789',  # 10 dígitos - Conta Cosmos
  nosso_numero: '12345678901',  # 11 dígitos
  portfolio: '123',  # 3 dígitos
  valor: 100.00,
  cedente: 'Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Nome',
  sacado_documento: '12345678900',
  data_vencimento: Date.today + 30
)
```

**⚠️ Observações Importantes:**
- Campo `portfolio` é específico do Citibank e obrigatório
- Convenio é a "Conta Cosmos" com 10 dígitos fixos
- Nosso número tem 11 dígitos fixos

**Referência:** `lib/brcobranca/boleto/citibank.rb`

---

## Banco 097 - Credisis

**Nome:** CrediSIS
**Código:** 097
**DV Banco:** 3 (fixo)
**Arquivo:** `lib/brcobranca/boleto/credisis.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 4 dígitos | String | Número da agência (máx 4) |
| `conta_corrente` | 7 dígitos | String | Número da conta (máx 7) |
| `carteira` | 2 dígitos | String | Tipo de carteira (**exato: 2**) |
| `convenio` | 6 dígitos | String | Código do convênio (**exato: 6**) |
| `nosso_numero` | 6 dígitos | String | Número do boleto (máx 6) |
| `documento_cedente` | CPF/CNPJ | String | Documento do beneficiário (**obrigatório**) |

**Campos obrigatórios herdados do base:**
- moeda, especie_documento, especie, aceite, sacado, sacado_documento

### 🟡 Campos Opcionais
- Todos os campos opcionais do base.rb

### ⚙️ Valores Padrão
```ruby
{
  carteira: '18'
}
```

### ✅ Exemplo de Uso
```ruby
boleto = Brcobranca::Boleto::Credisis.new(
  # Obrigatórios
  agencia: '1234',
  conta_corrente: '1234567',
  carteira: '18',  # 2 dígitos
  convenio: '123456',  # 6 dígitos
  nosso_numero: '123456',
  documento_cedente: '12345678000190',  # obrigatório e validado
  valor: 100.00,
  cedente: 'Empresa Ltda',
  sacado: 'Cliente Nome',
  sacado_documento: '12345678900',
  data_vencimento: Date.today + 30
)
```

**⚠️ Observações Importantes:**
- `documento_cedente` é obrigatório e validado (deve ser numérico)
- DV do documento usa multiplicador 8 para CNPJ, 9 para CPF
- Usa 'X' como mapeamento para resto 10 nos DVs

**Referência:** `lib/brcobranca/boleto/credisis.rb`

---

## Banco 399 - HSBC

**Nome:** HSBC
**Código:** 399
**DV Banco:** calculado (modulo11)
**Arquivo:** `lib/brcobranca/boleto/hsbc.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 4 dígitos | String | Número da agência (máx 4) |
| `conta_corrente` | 7 dígitos | String | Número da conta (máx 7) |
| `nosso_numero` | 13 dígitos | String | Número do boleto (máx 13) |
| `carteira` | CNR/CSB | String | Tipo de carteira (**in: ['CNR', 'CSB']**) |
| `data_vencimento` | Date | Date | **Obrigatório para CNR** |

**Carteiras:**
- CNR = Cobrança Não Registrada
- CSB = Cobrança Sem Registro

**Campos obrigatórios herdados do base:**
- moeda, especie_documento, especie, aceite, sacado, sacado_documento

### 🟡 Campos Opcionais
- Todos os campos opcionais do base.rb

### ⚙️ Valores Padrão
```ruby
{
  carteira: 'CNR'
}
```

### ✅ Exemplo de Uso - CNR
```ruby
boleto = Brcobranca::Boleto::Hsbc.new(
  # Obrigatórios
  agencia: '1234',
  conta_corrente: '1234567',
  nosso_numero: '1234567890123',  # 13 dígitos
  carteira: 'CNR',
  data_vencimento: Date.parse('2025-12-25'),  # obrigatório para CNR
  valor: 100.00,
  cedente: 'Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Nome',
  sacado_documento: '12345678900'
)
```

### ✅ Exemplo de Uso - CSB
```ruby
boleto = Brcobranca::Boleto::Hsbc.new(
  # Obrigatórios
  agencia: '1234',
  conta_corrente: '1234567',
  nosso_numero: '1234567890123',  # 13 dígitos
  carteira: 'CSB',
  # ... outros campos
)
```

**⚠️ Observações Importantes:**
- Suporta apenas carteiras CNR e CSB
- Carteira CNR usa dias julianos e requer data_vencimento
- Nosso número tem 13 dígitos (maior que o padrão)
- Cálculo de DV varia por carteira

**Referência:** `lib/brcobranca/boleto/hsbc.rb`

---

## Banco 341 - Itaú

**Nome:** Itaú
**Código:** 341
**DV Banco:** calculado (modulo11)
**Arquivo:** `lib/brcobranca/boleto/itau.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 4 dígitos | String | Número da agência (máx 4) |
| `conta_corrente` | 5 dígitos | String | Número da conta (máx 5) |
| `convenio` | 5 dígitos | String | Código do beneficiário (máx 5) |
| `nosso_numero` | 8 dígitos | String | Número do boleto (máx 8) |

**Campos obrigatórios herdados do base:**
- moeda, especie_documento, especie, aceite, sacado, sacado_documento

### 🔵 Campos Específicos por Carteira

**Carteiras Especiais** (198, 106, 107, 122, 142, 143, 195, 196):
- `seu_numero` (7 dígitos) - **OBRIGATÓRIO**

**Carteiras com DV Diferente** (112, 126, 131, 146, 150, 168):
- DV calculado sobre `carteira + nosso_numero` apenas

### 🟡 Campos Opcionais

| Campo | Tamanho | Descrição |
|-------|---------|-----------|
| `seu_numero` | 7 dígitos | Usado em carteiras especiais |
| Todos os campos opcionais do base.rb | - | - |

### ⚙️ Valores Padrão
```ruby
{
  carteira: '175'
}
```

### ✅ Exemplo de Uso - Carteira Normal
```ruby
boleto = Brcobranca::Boleto::Itau.new(
  # Obrigatórios
  agencia: '1234',
  conta_corrente: '12345',  # 5 dígitos
  convenio: '12345',  # 5 dígitos
  nosso_numero: '12345678',  # 8 dígitos
  carteira: '175',
  valor: 100.00,
  cedente: 'Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Nome',
  sacado_documento: '12345678900',
  data_vencimento: Date.today + 30
)
```

### ✅ Exemplo de Uso - Carteira Especial (com seu_numero)
```ruby
boleto = Brcobranca::Boleto::Itau.new(
  agencia: '1234',
  conta_corrente: '12345',
  convenio: '12345',
  nosso_numero: '12345678',
  carteira: '198',  # Carteira especial
  seu_numero: '1234567',  # OBRIGATÓRIO para esta carteira
  # ... outros campos
)
```

**⚠️ Observações Importantes:**
- Conta corrente tem apenas 5 dígitos
- Carteiras especiais (198, 106, 107, 122, 142, 143, 195, 196) requerem `seu_numero`
- Algumas carteiras calculam DV de forma diferente
- Usa modulo10 para cálculo de DVs

**Referência:** `lib/brcobranca/boleto/itau.rb`

---

## Banco 422 - Safra

**Nome:** Safra
**Código:** 422
**DV Banco:** calculado (modulo11)
**Arquivo:** `lib/brcobranca/boleto/safra.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 4 dígitos | String | Número da agência (máx 4) |
| `agencia_dv` | 1 dígito | String | DV da agência (**exato: 1, obrigatório**) |
| `conta_corrente` | 8 dígitos | String | Número da conta (máx 8) |
| `conta_corrente_dv` | 1 dígito | String | DV da conta (**exato: 1, obrigatório**) |
| `nosso_numero` | 8 dígitos | String | Número do boleto (máx 8) |

**Campos obrigatórios herdados do base:**
- moeda, especie_documento, especie, aceite, sacado, sacado_documento

### 🟡 Campos Opcionais
- Todos os campos opcionais do base.rb

### ⚙️ Valores Padrão
Nenhum valor padrão específico

### ✅ Exemplo de Uso
```ruby
boleto = Brcobranca::Boleto::Safra.new(
  # Obrigatórios
  agencia: '1234',
  agencia_dv: '5',  # DV fornecido pelo banco
  conta_corrente: '12345678',
  conta_corrente_dv: '9',  # DV fornecido pelo banco
  nosso_numero: '12345678',
  valor: 100.00,
  cedente: 'Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Nome',
  sacado_documento: '12345678900',
  data_vencimento: Date.today + 30
)
```

**⚠️ Observações Importantes:**
- Requer DVs de agência e conta fornecidos manualmente
- Usa "7" como código fixo no início do campo livre (Sistema)
- Usa "2" no final (tipo cobrança registrada)
- Modulo11 com `reverse: false`

**Referência:** `lib/brcobranca/boleto/safra.rb`

---

## Banco 033 - Santander

**Nome:** Santander
**Código:** 033
**DV Banco:** calculado (modulo11)
**Arquivo:** `lib/brcobranca/boleto/santander.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 4 dígitos | String | Número da agência (máx 4) |
| `convenio` | 7 dígitos | String | Código do Cedente (máx 7) |
| `nosso_numero` | 7 dígitos | String | Número do boleto (máx 7) |
| `carteira` | - | String | Tipo de carteira |

**Campos obrigatórios herdados do base:**
- moeda, especie_documento, especie, aceite, sacado, sacado_documento

### 🟡 Campos Opcionais

| Campo | Descrição |
|-------|-----------|
| `conta_corrente` | 9 dígitos, mas não exibida no boleto |
| Todos os campos opcionais do base.rb | - |

### ⚙️ Valores Padrão
```ruby
{
  carteira: '102'
}
```

### ✅ Exemplo de Uso
```ruby
boleto = Brcobranca::Boleto::Santander.new(
  # Obrigatórios
  agencia: '1234',
  convenio: '1234567',  # Código do Cedente
  nosso_numero: '1234567',
  carteira: '102',
  valor: 100.00,
  cedente: 'Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Nome',
  sacado_documento: '12345678900',
  data_vencimento: Date.today + 30,

  # Opcional
  conta_corrente: '123456789'  # não exibida no boleto
)
```

**⚠️ Observações Importantes:**
- Convenio é chamado de "Código do Cedente"
- Conta corrente tem 9 dígitos mas não é exibida no boleto
- Usa "9" fixo no início do campo livre
- IOF fixo como "0"

**Referência:** `lib/brcobranca/boleto/santander.rb`

---

## Banco 756 - Sicoob

**Nome:** Sicoob (Bancoob)
**Código:** 756
**DV Banco:** 0 (fixo)
**Arquivo:** `lib/brcobranca/boleto/sicoob.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 4 dígitos | String | Número da agência (máx 4) |
| `conta_corrente` | 8 dígitos | String | Número da conta (máx 8) |
| `convenio` | 7 dígitos | String | Código do convênio (máx 7) |
| `nosso_numero` | 7 dígitos | String | Número do boleto (máx 7) |
| `variacao` | 2 dígitos | String | Modalidade de cobrança (máx 2) |
| `quantidade` | 3 dígitos | String | Número da parcela (máx 3) |
| `carteira` | - | String | Tipo de carteira |

**Campos obrigatórios herdados do base:**
- moeda, especie_documento, especie, aceite, sacado, sacado_documento

### 🟡 Campos Opcionais
- Todos os campos opcionais do base.rb

### ⚙️ Valores Padrão
```ruby
{
  carteira: '1',
  variacao: '01',
  quantidade: '001',
  aceite: 'N'  # Diferente do base ('S')
}
```

### ✅ Exemplo de Uso
```ruby
boleto = Brcobranca::Boleto::Sicoob.new(
  # Obrigatórios
  agencia: '4327',
  conta_corrente: '417270',
  convenio: '229385',
  nosso_numero: '2',
  variacao: '01',  # modalidade de cobrança
  quantidade: '001',  # parcela única
  aceite: 'N',  # Sicoob usa 'N'
  valor: 50.00,
  cedente: 'Kivanio Barbosa',
  documento_cedente: '12345678912',
  sacado: 'Claudio Pozzebom',
  sacado_documento: '12345678900',
  data_vencimento: Date.parse('2025-12-25'),

  # Opcionais
  documento_numero: 'NF-001234'
)
```

**⚠️ Observações Importantes:**
- Define `aceite` padrão como 'N' (diferente do base que é 'S')
- DV usa constante 3197 com multiplicador [3, 1, 9, 7]
- `quantidade` refere-se ao número da parcela ("001" se parcela única)
- `variacao` é a modalidade de cobrança

**Referência:** `lib/brcobranca/boleto/sicoob.rb`

---

## Banco 748 - Sicredi

**Nome:** Sicredi
**Código:** 748
**DV Banco:** X (fixo)
**Arquivo:** `lib/brcobranca/boleto/sicredi.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 4 dígitos | String | Número da agência (máx 4) |
| `posto` | 2 dígitos | String | Código do posto (**obrigatório, máx 2**) |
| `conta_corrente` | 5 dígitos | String | Número da conta (máx 5) |
| `convenio` | 5 dígitos | String | Código do beneficiário (máx 5) |
| `nosso_numero` | 5 dígitos | String | Número do boleto (máx 5) |
| `byte_idt` | 1 dígito | String | Byte identificação (**exato: 1, obrigatório**) |
| `carteira` | 1 dígito | String | Tipo de carteira (máx 1) |
| `data_processamento` | Date | Date | **Usado no nosso número** |

**Carteira:**
- 1 = Com Registro
- 3 = Sem Registro

**Byte IDT:**
- 1 = Boleto gerado pela agência
- 2-9 = Boleto gerado pelo beneficiário

**Campos obrigatórios herdados do base:**
- moeda, especie, aceite, sacado, sacado_documento

### 🟡 Campos Opcionais
- Todos os campos opcionais do base.rb

### ⚙️ Valores Padrão
```ruby
{
  carteira: '3',
  especie_documento: 'A'  # Específico Sicredi
}
```

### ✅ Exemplo de Uso
```ruby
boleto = Brcobranca::Boleto::Sicredi.new(
  # Obrigatórios
  agencia: '1234',
  posto: '12',  # código do posto da cooperativa
  conta_corrente: '12345',  # 5 dígitos
  convenio: '12345',  # código do beneficiário
  nosso_numero: '12345',
  byte_idt: '2',  # 2-9 = gerado pelo beneficiário
  carteira: '3',  # 1=Com Registro, 3=Sem Registro
  data_processamento: Date.today,
  valor: 100.00,
  cedente: 'Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Nome',
  sacado_documento: '12345678900',
  data_vencimento: Date.today + 30
)
```

**⚠️ Observações Importantes:**
- Nosso número formato: AA/BXXXXX-D (ano/byte/sequencial-DV)
- `byte_idt`: 1=boleto gerado pela agência, 2-9=gerado pelo beneficiário
- Usa ano atual (YY) no nosso número
- Campo livre termina com "10" (indica valor expresso)
- Espécie documento padrão: 'A' (diferente de 'DM')

**Referência:** `lib/brcobranca/boleto/sicredi.rb`

---

## Banco 136 - Unicred

**Nome:** Unicred
**Código:** 136
**DV Banco:** calculado (modulo11)
**Arquivo:** `lib/brcobranca/boleto/unicred.rb`

### 🔴 Campos Obrigatórios

| Campo | Tamanho | Formato | Descrição |
|-------|---------|---------|-----------|
| `agencia` | 4 dígitos | String | Número da agência (máx 4) |
| `conta_corrente` | 9 dígitos | String | Número da conta (máx 9) |
| `conta_corrente_dv` | 1 dígito | String | DV da conta (**obrigatório**) |
| `nosso_numero` | 10 dígitos | String | Número do boleto (máx 10) |
| `carteira` | - | String | Sempre '21' |

**Campos obrigatórios herdados do base:**
- moeda, especie_documento, especie, aceite, sacado, sacado_documento

### 🟡 Campos Opcionais
- Todos os campos opcionais do base.rb

### ⚙️ Valores Padrão
```ruby
{
  carteira: '21',
  aceite: 'N',  # Diferente do base ('S')
  local_pagamento: 'PAGÁVEL PREFERENCIALMENTE NAS AGÊNCIAS DA UNICRED'
}
```

### ✅ Exemplo de Uso
```ruby
boleto = Brcobranca::Boleto::Unicred.new(
  # Obrigatórios
  agencia: '1234',
  conta_corrente: '123456789',  # 9 dígitos
  conta_corrente_dv: '5',  # DV fornecido pelo banco
  nosso_numero: '1234567890',  # 10 dígitos
  aceite: 'N',
  valor: 100.00,
  cedente: 'Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Nome',
  sacado_documento: '12345678900',
  data_vencimento: Date.today + 30
)
```

**⚠️ Observações Importantes:**
- Carteira é sempre '21'
- Define `aceite` padrão como 'N'
- Conta corrente tem 9 dígitos
- Nosso número tem 10 dígitos
- Requer `conta_corrente_dv` fornecido manualmente

**Referência:** `lib/brcobranca/boleto/unicred.rb`

---

## 📊 Tabela Comparativa - Campos Específicos

| Banco | Código | Campos Específicos Obrigatórios | Tamanho Conta | Tamanho Nosso Número |
|-------|--------|--------------------------------|---------------|---------------------|
| Ailos | 085 | - | 8 | 9 |
| Banco do Brasil | 001 | - | 8 | 4-17 (variável) |
| BRB | 070 | nosso_numero_incremento | 7 | 6 |
| Banco do Nordeste | 004 | digito_conta_corrente | 7 | 7 |
| Banestes | 021 | digito_conta_corrente, variacao | 10 | 8 |
| Banrisul | 041 | digito_convenio | 8 | 8 |
| Bradesco | 237 | - | 7 | 11 |
| Caixa | 104 | emissao | - | 15 |
| Citibank | 745 | portfolio | - | 11 |
| Credisis | 097 | documento_cedente | 7 | 6 |
| HSBC | 399 | - | 7 | 13 |
| Itaú | 341 | seu_numero (carteiras especiais) | 5 | 8 |
| Safra | 422 | agencia_dv, conta_corrente_dv | 8 | 8 |
| Santander | 033 | convenio | 9* | 7 |
| Sicoob | 756 | variacao, quantidade | 8 | 7 |
| Sicredi | 748 | posto, byte_idt | 5 | 5 |
| Unicred | 136 | conta_corrente_dv | 9 | 10 |

*Santander: conta_corrente não é exibida no boleto

---

## 📊 Bancos com Aceite Padrão 'N'

Maioria dos bancos usa `aceite: 'S'` (definido em base.rb).

**Exceções** (usam 'N' por padrão):
- **Sicoob (756)**: `aceite: 'N'`
- **Unicred (136)**: `aceite: 'N'`

---

## 📊 Bancos com Espécie Documento Diferente

Maioria dos bancos usa `especie_documento: 'DM'` (Duplicata Mercantil).

**Exceções:**
- **Sicredi (748)**: `especie_documento: 'A'`

---

## 📊 Bancos com DV do Banco Fixo

| Banco | Código | DV Fixo |
|-------|--------|---------|
| Ailos | 085 | 1 |
| Banestes | 021 | 3 |
| Banrisul | 041 | 8 |
| Caixa | 104 | 0 |
| Citibank | 745 | 5 |
| Credisis | 097 | 3 |
| Sicoob | 756 | 0 |
| Sicredi | 748 | X |

Demais bancos calculam DV usando modulo11.

---

## 🔍 Validações de Tamanho Exato (is:)

Campos que exigem tamanho EXATO (não máximo):

### Ailos (085)
- `convenio`: 6 dígitos
- `carteira`: 2 dígitos

### Banco de Brasília (070)
- `agencia`: 3 dígitos
- `carteira`: 1 dígito

### Banco do Nordeste (004)
- `digito_conta_corrente`: 1 dígito

### Banestes (021)
- `digito_conta_corrente`: 1 dígito

### Caixa (104)
- `convenio`: 6 dígitos
- `nosso_numero`: 15 dígitos
- `carteira`: 1 dígito
- `emissao`: 1 dígito

### Citibank (745)
- `convenio`: 10 dígitos
- `nosso_numero`: 11 dígitos
- `portfolio`: 3 dígitos

### Credisis (097)
- `convenio`: 6 dígitos
- `carteira`: 2 dígitos

### Safra (422)
- `agencia_dv`: 1 dígito
- `conta_corrente_dv`: 1 dígito

### Sicredi (748)
- `byte_idt`: 1 dígito

---

## 📌 Princípios de Uso dos Campos

### 1. Campos Obrigatórios
✅ **SEMPRE incluir** com valor (padrão ou fornecido)

### 2. Campos Opcionais
✅ **INCLUIR se tiverem valor**
⚪ **OMITIR se forem None/null/vazios**
❌ **NUNCA remover se tiverem valor válido**

### 3. Campos Inválidos
❌ **REMOVER apenas** se causarem erro na API do banco

### 4. Valores Padrão
Use valores padrão específicos do banco quando disponíveis.

---

## 📚 Referências Principais

- `lib/brcobranca/boleto/base.rb:97-98` - Validações base obrigatórias
- `lib/brcobranca/boleto/base.rb:105-114` - Valores padrão base
- `lib/brcobranca/boleto/{banco}.rb` - Implementação específica de cada banco
- `POLITICA_CAMPOS_BOLETO.md` - Política de uso de campos
- `BANCO_756_API_FIX.md` - Correção de erros Sicoob

---

**Criado em:** 2025-11-25
**Status:** Documentação completa validada
**Bancos documentados:** 17
