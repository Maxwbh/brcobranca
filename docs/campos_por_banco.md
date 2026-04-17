# Campos por Banco

Este documento detalha os campos obrigatórios e opcionais para cada banco suportado pelo BRCobranca.

## Índice

- [Campos Comuns (Base)](#campos-comuns-base)
- [Banco do Brasil (001)](#banco-do-brasil-001)
- [Bradesco (237)](#bradesco-237)
- [Itaú (341)](#itaú-341)
- [Santander (033)](#santander-033)
- [Caixa Econômica Federal (104)](#caixa-econômica-federal-104)
- [Sicoob (756)](#sicoob-756) — inclui **Carteira 9** (2024/2025)
- [Sicredi (748)](#sicredi-748)
- [Banco C6 (336)](#banco-c6-336) — novo banco, CNAB 400
- [Campos PIX (PagamentoPix)](#campos-pix-pagamentopix)

---

## Campos Comuns (Base)

Todos os boletos herdam os seguintes campos da classe `Brcobranca::Boleto::Base`:

### Campos Obrigatórios

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `agencia` | String | Número da agência (sem DV) |
| `conta_corrente` | String | Número da conta corrente (sem DV) |
| `moeda` | String | Código da moeda (9 = Real) |
| `especie_documento` | String | Tipo do documento (DM, NP, etc.) |
| `especie` | String | Símbolo da moeda (R$) |
| `aceite` | String | Aceite (S ou N) |
| `nosso_numero` | String | Número do título no banco |
| `sacado` | String | Nome do pagador |
| `sacado_documento` | String | CPF/CNPJ do pagador |

### Campos Opcionais

| Campo | Tipo | Descrição | Padrão |
|-------|------|-----------|--------|
| `convenio` | String | Número do convênio/contrato | - |
| `carteira` | String | Carteira de cobrança | Varia por banco |
| `data_processamento` | Date | Data de processamento | Data atual |
| `data_vencimento` | Date | Data de vencimento | Data atual |
| `quantidade` | Integer | Quantidade de boletos | 1 |
| `valor` | Float | Valor do boleto | 0.0 |
| `local_pagamento` | String | Onde pagar | "QUALQUER BANCO ATÉ O VENCIMENTO" |
| `cedente` | String | Nome do beneficiário | - |
| `documento_cedente` | String | CPF/CNPJ do beneficiário | - |
| `sacado_endereco` | String | Endereço do pagador | - |
| `instrucoes` | String | Instruções de pagamento | - |
| `emv` | String | EMV para QRCode PIX | - |

---

## Banco do Brasil (001)

**Classe:** `Brcobranca::Boleto::BancoBrasil`

### Campos Específicos

| Campo | Tamanho | Obrigatório | Descrição |
|-------|---------|-------------|-----------|
| `convenio` | 4-8 dígitos | Sim | Número do convênio |
| `carteira` | 2 dígitos | Sim | Carteira (17, 18, etc.) |
| `nosso_numero` | 5-17 dígitos | Sim | Varia conforme convênio |
| `agencia` | 4 dígitos | Sim | Código da agência |
| `conta_corrente` | 8 dígitos | Sim | Conta corrente |
| `variacao` | 3 dígitos | Não | Variação da carteira |

### Regras de Convênio

- **Convênio 4 dígitos:** Nosso número com 7 posições
- **Convênio 6 dígitos:** Nosso número com 5 posições
- **Convênio 7 dígitos:** Nosso número com 10 posições
- **Convênio 8 dígitos:** Nosso número com 17 posições

### Exemplo

```ruby
boleto = Brcobranca::Boleto::BancoBrasil.new(
  convenio: '1238798',
  carteira: '18',
  nosso_numero: '7700168',
  agencia: '1234',
  conta_corrente: '12345678',
  valor: 135.00,
  cedente: 'Empresa LTDA',
  sacado: 'Cliente da Silva',
  sacado_documento: '12345678901'
)
```

---

## Bradesco (237)

**Classe:** `Brcobranca::Boleto::Bradesco`

### Campos Específicos

| Campo | Tamanho | Obrigatório | Descrição |
|-------|---------|-------------|-----------|
| `carteira` | 2 dígitos | Sim | Carteira (06, 09, etc.) |
| `nosso_numero` | 11 dígitos | Sim | Número do título |
| `agencia` | 4 dígitos | Sim | Código da agência |
| `conta_corrente` | 7 dígitos | Sim | Conta corrente |

### Carteiras Disponíveis

- **06** - Cobrança Simples com Registro
- **09** - Cobrança Simples sem Registro

### Exemplo

```ruby
boleto = Brcobranca::Boleto::Bradesco.new(
  carteira: '06',
  nosso_numero: '00000004042',
  agencia: '0548',
  conta_corrente: '0001448',
  valor: 250.00,
  cedente: 'Empresa LTDA',
  sacado: 'Cliente da Silva',
  sacado_documento: '12345678901'
)
```

---

## Itaú (341)

**Classe:** `Brcobranca::Boleto::Itau`

### Campos Específicos

| Campo | Tamanho | Obrigatório | Descrição |
|-------|---------|-------------|-----------|
| `carteira` | 3 dígitos | Sim | Carteira (175, 198, etc.) |
| `nosso_numero` | 8 dígitos | Sim | Número do título |
| `agencia` | 4 dígitos | Sim | Código da agência |
| `conta_corrente` | 5 dígitos | Sim | Conta corrente |
| `convenio` | 5 dígitos | Não | Código do cliente |
| `seu_numero` | 7 dígitos | Condicional | Obrigatório para carteiras especiais |

### Carteiras Especiais (requerem `seu_numero`)

- 106, 107, 122, 142, 143, 195, 196, 198

### Exemplo

```ruby
boleto = Brcobranca::Boleto::Itau.new(
  carteira: '175',
  nosso_numero: '12345678',
  agencia: '0811',
  conta_corrente: '53678',
  valor: 100.00,
  cedente: 'Empresa LTDA',
  sacado: 'Cliente da Silva',
  sacado_documento: '12345678901'
)
```

---

## Santander (033)

**Classe:** `Brcobranca::Boleto::Santander`

### Campos Específicos

| Campo | Tamanho | Obrigatório | Descrição |
|-------|---------|-------------|-----------|
| `convenio` | 7 dígitos | Sim | Código do cedente |
| `carteira` | 3 dígitos | Sim | Carteira (101, 102, etc.) |
| `nosso_numero` | 7 dígitos | Sim | Número do título |
| `agencia` | 4 dígitos | Sim | Código da agência |
| `conta_corrente` | 9 dígitos | Não | Conta corrente |

### Exemplo

```ruby
boleto = Brcobranca::Boleto::Santander.new(
  convenio: '1899775',
  carteira: '102',
  nosso_numero: '9000272',
  agencia: '0059',
  valor: 500.00,
  cedente: 'Empresa LTDA',
  sacado: 'Cliente da Silva',
  sacado_documento: '12345678901'
)
```

---

## Caixa Econômica Federal (104)

**Classe:** `Brcobranca::Boleto::Caixa`

### Campos Específicos

| Campo | Tamanho | Obrigatório | Descrição |
|-------|---------|-------------|-----------|
| `convenio` | 6 dígitos | Sim | Código do beneficiário |
| `carteira` | 2 dígitos | Sim | Carteira (SR, RG) |
| `nosso_numero` | 15-17 dígitos | Sim | Número do título |
| `agencia` | 4 dígitos | Sim | Código da agência |
| `conta_corrente` | 11 dígitos | Sim | Código operação + conta |

### Exemplo

```ruby
boleto = Brcobranca::Boleto::Caixa.new(
  convenio: '123456',
  carteira: 'SR',
  nosso_numero: '24000000000000001',
  agencia: '0001',
  conta_corrente: '00000000001',
  valor: 350.00,
  cedente: 'Empresa LTDA',
  sacado: 'Cliente da Silva',
  sacado_documento: '12345678901'
)
```

---

## Sicoob (756)

**Classe:** `Brcobranca::Boleto::Sicoob`

### Campos Específicos

| Campo | Tamanho | Obrigatório | Descrição |
|-------|---------|-------------|-----------|
| `convenio` | 7 dígitos | Sim | Código do cliente (cedente) |
| `carteira` | 1 dígito | Sim | `'1'`, `'3'` ou `'9'` (nova) |
| `nosso_numero` | 7 dígitos | Sim | Número do título |
| `agencia` | 4 dígitos | Sim | Código cooperativa |
| `conta_corrente` | 8 dígitos | Sim | Conta corrente |
| `numero_contrato` | 7 dígitos | ⚠️ (só Carteira 9) | Número do contrato fornecido pelo Sicoob |

### Carteiras suportadas

- **Carteira 1** — Cobrança Simples Com Registro (tradicional)
- **Carteira 3** — Cobrança Garantida Caucionada
- **Carteira 9** — Nova modalidade (2024/2025): usa `numero_contrato`
  no código de barras em vez do `convenio`

### Exemplo (carteira tradicional)

```ruby
boleto = Brcobranca::Boleto::Sicoob.new(
  convenio: '1234567',
  carteira: '1',
  nosso_numero: '0000001',
  agencia: '3069',
  conta_corrente: '00000001',
  valor: 200.00,
  cedente: 'Empresa LTDA',
  sacado: 'Cliente da Silva',
  sacado_documento: '12345678901'
)
```

### Exemplo (Carteira 9, nova modalidade)

```ruby
boleto = Brcobranca::Boleto::Sicoob.new(
  convenio: '229385',
  carteira: '9',                # Ativa a nova composição
  numero_contrato: '1234567',   # Fornecido pelo Sicoob
  nosso_numero: '1',
  agencia: '4327',
  # ... demais campos
)
```

### CNAB 240 — Layout 810 (opcional)

Na remessa CNAB 240, é possível indicar que o cliente já envia o DV do
nosso número calculado (Sicoob não recalcula):

```ruby
remessa = Brcobranca::Remessa::Cnab240::Sicoob.new(
  versao_layout_arquivo_opcao: '810',  # '081' (padrão) ou '810'
  # ... demais campos
)
```

### CNAB 400 — Nome do banco configurável

Desde 2018 o banco usa o nome **SICOOB** oficialmente. Por padrão, a remessa
ainda usa `'BANCOOBCED'` para compatibilidade. Para atualizar:

```ruby
remessa = Brcobranca::Remessa::Cnab400::Sicoob.new(
  nome_banco: 'SICOOB',  # default: 'BANCOOBCED'
  # ... demais campos
)
```

---

## Sicredi (748)

**Classe:** `Brcobranca::Boleto::Sicredi`

### Campos Específicos

| Campo | Tamanho | Obrigatório | Descrição |
|-------|---------|-------------|-----------|
| `posto` | 2 dígitos | Sim | Código do posto |
| `byte_idt` | 1 dígito | Sim | Byte identificador |
| `carteira` | 1 dígito | Sim | Carteira (A, B, C) |
| `nosso_numero` | 5 dígitos | Sim | Número do título |
| `agencia` | 4 dígitos | Sim | Código da cooperativa |
| `conta_corrente` | 5 dígitos | Sim | Conta corrente |

### Exemplo

```ruby
boleto = Brcobranca::Boleto::Sicredi.new(
  posto: '08',
  byte_idt: '2',
  carteira: 'A',
  nosso_numero: '00001',
  agencia: '0710',
  conta_corrente: '03009',
  valor: 150.00,
  cedente: 'Empresa LTDA',
  sacado: 'Cliente da Silva',
  sacado_documento: '12345678901'
)
```

---

## Banco C6 (336)

Novo banco adicionado nesta versão. CNAB 400, versão de layout 2.7 (Jul/2025).

### Campos Obrigatórios

| Campo | Tipo | Tamanho | Descrição |
|-------|------|---------|-----------|
| `agencia` | String | 4 | Número da agência |
| `convenio` | String | 12 | Código do Cedente fornecido pelo C6 |
| `carteira` | String | 2 | `'10'` (Emissão Banco) ou `'20'` (Emissão Cliente) |
| `nosso_numero` | String | 10 | Número do título (preenchido com zeros à esquerda) |

### Campo Livre (25 posições)

```
Posição | Tamanho | Conteúdo
20 a 31 |   12    | Código do Cedente (convenio)
32 a 41 |   10    | Nosso Número (sem DV)
42 a 43 |   2     | Código da Carteira ('10' ou '20')
44      |   1     | Indicador de Layout (3 = Emissão Banco, 4 = Emissão Cliente)
```

### Exemplo

```ruby
boleto = Brcobranca::Boleto::BancoC6.new(
  agencia: '0001',
  convenio: '000000123456',
  carteira: '10',
  nosso_numero: '0000000001',
  valor: 100.00,
  data_vencimento: Date.today + 30,
  cedente: 'Minha Empresa LTDA',
  documento_cedente: '12345678000100',
  sacado: 'Cliente',
  sacado_documento: '12345678900'
)
```

### Remessa CNAB 400

Campo adicional obrigatório: `codigo_beneficiario` (12 dígitos).

```ruby
remessa = Brcobranca::Remessa::Cnab400::BancoC6.new(
  codigo_beneficiario: '000000123456',
  carteira: '10',
  empresa_mae: 'Minha Empresa LTDA',
  documento_cedente: '12345678000100',
  sequencial_remessa: '1',
  pagamentos: [pagamento]
)
```

---

## Campos PIX (PagamentoPix)

Para gerar remessa com registro/segmento PIX, use `Brcobranca::Remessa::PagamentoPix`
em vez de `Pagamento`. Campos adicionais:

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|:-:|-----------|
| `tipo_chave_dict` | String | ✅ | `'cpf'`, `'cnpj'`, `'email'`, `'telefone'`, `'chave_aleatoria'` |
| `codigo_chave_dict` | String | ✅ | Chave PIX do recebedor |
| `tipo_pagamento_pix` | String | - | `'00'` (padrão), `'01'`, `'02'`, `'03'` |
| `quantidade_pagamentos_pix` | String | - | `'01'` (padrão) |
| `tipo_valor_pix` | String | - | `'1'` (padrão) |
| `valor_maximo_pix` | Float | - | Valor máximo do PIX |
| `valor_minimo_pix` | Float | - | Valor mínimo do PIX |
| `percentual_maximo_pix` | Float | - | Percentual máximo (default: 100.0) |
| `percentual_minimo_pix` | Float | - | Percentual mínimo (default: 100.0) |
| `txid` | String | - | Código de identificação do QR Code |

### Validações por tipo de chave

| Tipo | Formato esperado |
|---|---|
| `cpf` | 11 dígitos numéricos |
| `cnpj` | 14 caracteres (12 alfanuméricos + 2 numéricos) |
| `email` | RFC de email |
| `telefone` | `+DDDNNNNNNNNN` (12 a 13 caracteres) |
| `chave_aleatoria` | 1 a 77 caracteres |

### Classes com suporte a PIX

| Banco | Formato | Classe |
|---|:---:|---|
| Santander (033) | CNAB 400 | `Brcobranca::Remessa::Cnab400::SantanderPix` |
| Bradesco (237) | CNAB 400 | `Brcobranca::Remessa::Cnab400::BradescoPix` |
| Itaú (341) | CNAB 400 | `Brcobranca::Remessa::Cnab400::ItauPix` |
| C6 Bank (336) | CNAB 400 | `Brcobranca::Remessa::Cnab400::BancoC6Pix` |
| Banco do Brasil (001) | CNAB 240 | `Brcobranca::Remessa::Cnab240::BancoBrasilPix` |
| Caixa (104) | CNAB 240 | `Brcobranca::Remessa::Cnab240::CaixaPix` |
| Sicoob (756) | CNAB 240 | `Brcobranca::Remessa::Cnab240::SicoobPix` |

---

## Outros Bancos Suportados

O BRCobranca também suporta:

- **Banestes (021)**
- **Banrisul (041)**
- **Banco Nordeste (004)**
- **Banco de Brasília (070)**
- **Citibank (745)**
- **Credisis (097)**
- **HSBC (399)** - Descontinuado
- **Safra (422)**
- **Unicred (136)**
- **Ailos (085)**

Consulte a documentação específica de cada banco na pasta `lib/brcobranca/boleto/`.

---

## Autor

**Maxwell Oliveira** - M&S do Brasil LTDA
- Email: maxwbh@gmail.com
- LinkedIn: [/maxwbh](https://linkedin.com/in/maxwbh)
- Website: [www.msbrasil.inf.br](https://www.msbrasil.inf.br)
