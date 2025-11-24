# Documentação de Campos por Banco - BRCobrança

Este documento detalha todos os campos necessários, opcionais e validações específicas para cada banco suportado pela gem BRCobrança.

## Índice

- [Campos Comuns a Todos os Bancos](#campos-comuns-a-todos-os-bancos)
- [001 - Banco do Brasil](#001---banco-do-brasil)
- [004 - Banco do Nordeste](#004---banco-do-nordeste)
- [033 - Santander](#033---santander)
- [041 - Banrisul](#041---banrisul)
- [104 - Caixa](#104---caixa)
- [237 - Bradesco](#237---bradesco)
- [341 - Itaú](#341---itaú)
- [748 - Sicredi](#748---sicredi)
- [756 - Sicoob](#756---sicoob)

---

## Campos Comuns a Todos os Bancos

Todos os bancos herdam da classe `Brcobranca::Boleto::Base` e compartilham os seguintes campos:

### Campos OBRIGATÓRIOS (Base)

| Campo | Tipo | Descrição | Valor Padrão |
|-------|------|-----------|--------------|
| `agencia` | String/Integer | Número da agência **sem** dígito verificador | - |
| `conta_corrente` | String/Integer | Número da conta corrente **sem** dígito verificador | - |
| `moeda` | String | Tipo de moeda (Real = 9) | '9' |
| `especie_documento` | String | Tipo do documento (ex: DM, NP, DS) | 'DM' |
| `especie` | String | Símbolo da moeda | 'R$' |
| `aceite` | String | Se o banco aceita após vencimento (S/N) | 'S' |
| `nosso_numero` | String/Integer | Número sequencial para identificar o boleto | - |
| `sacado` | String | Nome do pagador | - |
| `sacado_documento` | String | CPF/CNPJ do pagador | - |
| `valor` | Decimal | Valor do boleto | - |
| `cedente` | String | Nome do beneficiário | - |
| `documento_cedente` | String | CPF/CNPJ do beneficiário | - |
| `data_documento` | Date | Data de emissão do documento | Data atual |
| `data_vencimento` | Date | Data de vencimento do boleto | Data atual |

### Campos OPCIONAIS (Base)

| Campo | Tipo | Descrição | Valor Padrão |
|-------|------|-----------|--------------|
| `convenio` | String/Integer | Número do convênio/contrato | - |
| `carteira` | String | Carteira utilizada | (varia por banco) |
| `carteira_label` | String | Rótulo da carteira (RG/SR) | - |
| `variacao` | String | Variação da carteira | - |
| `data_processamento` | Date | Data de processamento | Data atual |
| `quantidade` | Integer | Quantidade de boletos | 1 |
| `documento_numero` | String | Número do documento fiscal | - |
| `codigo_servico` | Boolean | Código de serviço | - |
| `local_pagamento` | String | Local onde pode ser pago | 'QUALQUER BANCO ATÉ O VENCIMENTO' |
| `demonstrativo` | String | Informações para o sacado | - |
| `instrucoes` | String | Instruções gerais | - |
| `instrucao1` a `instrucao7` | String | Instruções específicas | - |
| `sacado_endereco` | String | Endereço do pagador | - |
| `avalista` | String | Nome do avalista | - |
| `avalista_documento` | String | CPF/CNPJ do avalista | - |
| `cedente_endereco` | String | Endereço do beneficiário | - |
| `emv` | String | Código EMV para QRCode PIX | - |
| `descontos_e_abatimentos` | Decimal | Descontos e abatimentos | - |

---

## 001 - Banco do Brasil

**Classe:** `Brcobranca::Boleto::BancoBrasil`

### Campos Específicos OBRIGATÓRIOS

| Campo | Tamanho | Descrição | Observações |
|-------|---------|-----------|-------------|
| `convenio` | 4-8 dígitos | Número do convênio | **Obrigatório** - Aceita de 4 a 8 dígitos |
| `nosso_numero` | Variável | Número sequencial | Tamanho varia conforme convênio (ver abaixo) |
| `agencia` | até 4 | Agência sem DV | Completado com zeros à esquerda |
| `conta_corrente` | até 8 | Conta sem DV | Completado com zeros à esquerda |
| `carteira` | 2 | Carteira de cobrança | Padrão: '18' |

### Regras de Validação Específicas

**Tamanho do Nosso Número baseado no Convênio:**

| Tamanho Convênio | Tamanho Nosso Número | Observações |
|------------------|----------------------|-------------|
| 8 dígitos | 9 dígitos | Nosso Número de 17 dígitos |
| 7 dígitos | 10 dígitos | Nosso Número de 17 dígitos |
| 6 dígitos | 5 dígitos | Se `codigo_servico` = false |
| 6 dígitos | 17 dígitos | Se `codigo_servico` = true (carteiras 16 ou 18) |
| 4 dígitos | 7 dígitos | Nosso Número de 11 dígitos |

### Campos Opcionais

| Campo | Descrição |
|-------|-----------|
| `codigo_servico` | Boolean - Define formato do nosso número para convênio 6 dígitos |

### Exemplo de Uso

```ruby
boleto = Brcobranca::Boleto::BancoBrasil.new(
  valor: 135.00,
  cedente: 'Empresa Exemplo Ltda',
  documento_cedente: '12345678000190',
  sacado: 'João da Silva',
  sacado_documento: '12345678900',
  agencia: '4042',
  conta_corrente: '61900',
  convenio: 12387989,        # 8 dígitos
  nosso_numero: '777700168', # 9 dígitos
  carteira: '18',
  data_documento: Date.today,
  data_vencimento: Date.today + 30
)
```

### Valores Padrão

- `carteira`: '18'
- `codigo_servico`: false
- `local_pagamento`: 'PAGÁVEL EM QUALQUER BANCO.'

---

## 004 - Banco do Nordeste

**Classe:** `Brcobranca::Boleto::BancoNordeste`

### Campos Específicos OBRIGATÓRIOS

| Campo | Tamanho | Descrição | Observações |
|-------|---------|-----------|-------------|
| `agencia` | até 4 | Agência sem DV | Completado com zeros à esquerda |
| `conta_corrente` | até 7 | Conta sem DV | Completado com zeros à esquerda |
| `digito_conta_corrente` | 1 | Dígito verificador da conta | **OBRIGATÓRIO** |
| `nosso_numero` | até 7 | Número sequencial | Completado com zeros à esquerda |
| `carteira` | até 2 | Carteira de cobrança | Padrão: '21' |

### Regras de Validação Específicas

- Agência: máximo 4 dígitos
- Conta Corrente: máximo 7 dígitos
- Dígito Conta Corrente: exatamente 1 dígito
- Carteira: máximo 2 dígitos
- Nosso Número: máximo 7 dígitos

### Exemplo de Uso

```ruby
boleto = Brcobranca::Boleto::BancoNordeste.new(
  valor: 100.00,
  cedente: 'Empresa Exemplo Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Maria Santos',
  sacado_documento: '98765432100',
  agencia: '0059',
  conta_corrente: '1899775',
  digito_conta_corrente: '5',
  nosso_numero: '0020572',
  carteira: '21',
  data_vencimento: Date.today + 30
)
```

### Valores Padrão

- `carteira`: '21'

---

## 033 - Santander

**Classe:** `Brcobranca::Boleto::Santander`

### Campos Específicos OBRIGATÓRIOS

| Campo | Tamanho | Descrição | Observações |
|-------|---------|-----------|-------------|
| `convenio` | até 7 | Código do Cedente | **OBRIGATÓRIO** - Completado com zeros |
| `agencia` | até 4 | Agência | Completado com zeros à esquerda |
| `conta_corrente` | até 9 | Conta corrente | Completado com zeros à esquerda |
| `nosso_numero` | até 7 | Número sequencial | Completado com zeros à esquerda |
| `carteira` | - | Carteira | Padrão: '102' |

### Regras de Validação Específicas

- Agência: máximo 4 dígitos
- Convênio: máximo 7 dígitos - **campo obrigatório**
- Nosso Número: máximo 7 dígitos
- Conta Corrente: 9 dígitos (completado automaticamente)

### Exemplo de Uso

```ruby
boleto = Brcobranca::Boleto::Santander.new(
  valor: 250.00,
  cedente: 'Empresa Exemplo Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Pedro Oliveira',
  sacado_documento: '11122233344',
  agencia: '0059',
  convenio: '1899775',
  nosso_numero: '9000026',
  conta_corrente: '013000123',
  carteira: '102',
  data_vencimento: Date.today + 30
)
```

### Valores Padrão

- `carteira`: '102'

---

## 041 - Banrisul

**Classe:** `Brcobranca::Boleto::Banrisul`

### Campos Específicos OBRIGATÓRIOS

| Campo | Tamanho | Descrição | Observações |
|-------|---------|-----------|-------------|
| `agencia` | até 4 | Agência | Completado com zeros à esquerda |
| `conta_corrente` | até 8 | Conta corrente | Completado com zeros à esquerda |
| `convenio` | até 7 | Código do cedente | Completado com zeros à esquerda |
| `digito_convenio` | até 2 | Dígito verificador do convênio | **OBRIGATÓRIO** |
| `nosso_numero` | até 8 | Número sequencial | Completado com zeros à esquerda |
| `carteira` | 1 | Tipo de produto | Padrão: '2' |

### Regras de Validação Específicas

- Agência: máximo 4 dígitos
- Conta Corrente: máximo 8 dígitos
- Convênio: máximo 7 dígitos
- Dígito Convênio: máximo 2 dígitos
- Nosso Número: máximo 8 dígitos
- Carteira: máximo 1 dígito

### Carteiras

- `1`: Cobrança Normal, Fichário emitido pelo BANRISUL
- `2`: Cobrança Direta, Fichário emitido pelo CLIENTE (padrão)

### Exemplo de Uso

```ruby
boleto = Brcobranca::Boleto::Banrisul.new(
  valor: 1278.90,
  cedente: 'Empresa Exemplo Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Ana Costa',
  sacado_documento: '55566677788',
  agencia: '1102',
  conta_corrente: '1454204',
  nosso_numero: '22832563',
  convenio: '9000150',
  digito_convenio: '46',
  carteira: '2',
  data_vencimento: Date.today + 30
)
```

### Valores Padrão

- `carteira`: '2'

---

## 104 - Caixa

**Classe:** `Brcobranca::Boleto::Caixa`

### Campos Específicos OBRIGATÓRIOS

| Campo | Tamanho | Descrição | Observações |
|-------|---------|-----------|-------------|
| `convenio` | 6 | Código do cedente | **Exatamente 6 dígitos** |
| `nosso_numero` | 15 | Número sequencial | **Exatamente 15 dígitos** |
| `carteira` | 1 | Modalidade de cobrança | **Exatamente 1 dígito** - Padrão: '1' |
| `emissao` | 1 | Tipo de emissão | **Exatamente 1 dígito** - Padrão: '4' |

### Regras de Validação Específicas

- Carteira: **exatamente** 1 dígito
- Emissão: **exatamente** 1 dígito
- Convênio: **exatamente** 6 dígitos
- Nosso Número: **exatamente** 15 dígitos

### Carteiras

- `1`: Registrada (padrão)
- `2`: Sem Registro

### Emissão

- `4`: Beneficiário (padrão)

### Exemplo de Uso

```ruby
boleto = Brcobranca::Boleto::Caixa.new(
  valor: 500.00,
  cedente: 'PREFEITURA MUNICIPAL EXEMPLO',
  documento_cedente: '04092706000181',
  sacado: 'Carlos Ferreira',
  sacado_documento: '77777777777',
  agencia: '1825',
  conta_corrente: '0000528',
  convenio: '245274',
  nosso_numero: '000000000000001',
  carteira: '1',
  emissao: '4',
  data_vencimento: Date.today + 30
)
```

### Valores Padrão

- `carteira`: '1'
- `carteira_label`: 'RG'
- `emissao`: '4'
- `local_pagamento`: 'PREFERENCIALMENTE NAS CASAS LOTÉRICAS ATÉ O VALOR LIMITE'

---

## 237 - Bradesco

**Classe:** `Brcobranca::Boleto::Bradesco`

### Campos Específicos OBRIGATÓRIOS

| Campo | Tamanho | Descrição | Observações |
|-------|---------|-----------|-------------|
| `agencia` | até 4 | Agência sem DV | Completado com zeros à esquerda |
| `conta_corrente` | até 7 | Conta sem DV | Completado com zeros à esquerda |
| `nosso_numero` | até 11 | Número sequencial | Completado com zeros à esquerda |
| `carteira` | 2 | Carteira de cobrança | Padrão: '06' |

### Regras de Validação Específicas

- Agência: máximo 4 dígitos
- Nosso Número: máximo 11 dígitos
- Conta Corrente: máximo 7 dígitos
- Carteira: máximo 2 dígitos

### Exemplo de Uso

```ruby
boleto = Brcobranca::Boleto::Bradesco.new(
  valor: 135.00,
  cedente: 'Empresa Exemplo Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Fernanda Lima',
  sacado_documento: '12345678900',
  agencia: '4042',
  conta_corrente: '61900',
  nosso_numero: '777700168',
  carteira: '03',
  data_vencimento: Date.today + 30
)
```

### Valores Padrão

- `carteira`: '06'
- `local_pagamento`: 'Pagável preferencialmente na Rede Bradesco ou Bradesco Expresso'

---

## 341 - Itaú

**Classe:** `Brcobranca::Boleto::Itau`

### Campos Específicos OBRIGATÓRIOS

| Campo | Tamanho | Descrição | Observações |
|-------|---------|-----------|-------------|
| `agencia` | até 4 | Agência sem DV | Completado com zeros à esquerda |
| `conta_corrente` | até 5 | Conta sem DV | Completado com zeros à esquerda |
| `convenio` | até 5 | Código do cliente | Completado com zeros à esquerda |
| `nosso_numero` | até 8 | Número sequencial | Completado com zeros à esquerda |
| `carteira` | - | Carteira de cobrança | Padrão: '175' |

### Campos Condicionais

| Campo | Tamanho | Quando Obrigatório | Descrição |
|-------|---------|-------------------|-----------|
| `seu_numero` | até 7 | Carteiras especiais | Número do documento (ver carteiras abaixo) |

### Carteiras que Requerem `seu_numero`

As seguintes carteiras requerem o campo `seu_numero`:
- 198, 106, 107, 122, 142, 143, 195, 196

### Regras de Validação Específicas

- Agência: máximo 4 dígitos
- Convênio: máximo 5 dígitos
- Nosso Número: máximo 8 dígitos
- Conta Corrente: máximo 5 dígitos
- Seu Número: máximo 7 dígitos (quando aplicável)

### Exemplo de Uso

```ruby
# Carteira padrão (175)
boleto = Brcobranca::Boleto::Itau.new(
  valor: 135.00,
  cedente: 'Empresa Exemplo Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Roberto Silva',
  sacado_documento: '12345678900',
  agencia: '0810',
  conta_corrente: '53678',
  convenio: '12387',
  nosso_numero: '258281',
  carteira: '175',
  data_vencimento: Date.today + 30
)

# Carteira especial (198) - requer seu_numero
boleto_especial = Brcobranca::Boleto::Itau.new(
  valor: 200.00,
  cedente: 'Empresa Exemplo Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Roberto Silva',
  sacado_documento: '12345678900',
  agencia: '0810',
  conta_corrente: '53678',
  convenio: '12387',
  nosso_numero: '12345678',
  seu_numero: '1234567',  # Obrigatório para carteiras especiais
  carteira: '198',
  data_vencimento: Date.today + 30
)
```

### Valores Padrão

- `carteira`: '175'

---

## 748 - Sicredi

**Classe:** `Brcobranca::Boleto::Sicredi`

### Campos Específicos OBRIGATÓRIOS

| Campo | Tamanho | Descrição | Observações |
|-------|---------|-----------|-------------|
| `agencia` | até 4 | Agência/Cooperativa | Completado com zeros à esquerda |
| `conta_corrente` | até 5 | Conta corrente | Completado com zeros à esquerda |
| `convenio` | até 5 | Código do beneficiário | Completado com zeros à esquerda |
| `nosso_numero` | até 5 | Número sequencial | Completado com zeros à esquerda |
| `posto` | 2 | Código do posto | **OBRIGATÓRIO** - Completado com zeros |
| `byte_idt` | 1 | Byte de identificação | **OBRIGATÓRIO** - 1 dígito |
| `carteira` | 1 | Tipo de cobrança | Padrão: '3' |
| `data_processamento` | Date | Data de processamento | Usado no nosso número |

### Regras de Validação Específicas

- Agência: máximo 4 dígitos
- Nosso Número: máximo 5 dígitos
- Conta Corrente: máximo 5 dígitos
- Carteira: máximo 1 dígito
- Posto: máximo 2 dígitos
- Byte IDT: **exatamente** 1 dígito
- Convênio: máximo 5 dígitos

### Byte IDT

- `1`: Boleto gerado pela agência
- `2-9`: Boleto gerado pelo beneficiário

### Carteiras

- `1`: Com Registro
- `3`: Sem Registro (padrão)

### Exemplo de Uso

```ruby
boleto = Brcobranca::Boleto::Sicredi.new(
  valor: 195.57,
  cedente: 'Empresa Exemplo Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Juliana Souza',
  sacado_documento: '12345678900',
  agencia: '0710',
  conta_corrente: '61900',
  convenio: '129',
  nosso_numero: '8879',
  posto: '65',
  byte_idt: '2',
  carteira: '1',
  data_processamento: Date.today,
  data_vencimento: Date.today + 30
)
```

### Valores Padrão

- `carteira`: '3'
- `especie_documento`: 'A'

---

## 756 - Sicoob

**Classe:** `Brcobranca::Boleto::Sicoob`

### Campos Específicos OBRIGATÓRIOS

| Campo | Tamanho | Descrição | Observações |
|-------|---------|-----------|-------------|
| `agencia` | até 4 | Agência/Cooperativa | Completado com zeros à esquerda |
| `conta_corrente` | até 8 | Conta corrente | Completado com zeros à esquerda |
| `convenio` | até 7 | Código do cedente/cliente | Completado com zeros à esquerda |
| `nosso_numero` | até 7 | Número sequencial | Completado com zeros à esquerda |
| `variacao` | até 2 | Código da modalidade | Padrão: '01' |
| `quantidade` | até 3 | Número da parcela | Padrão: '001' |
| `carteira` | - | Carteira de cobrança | Padrão: '1' |

### Regras de Validação Específicas

- Agência: máximo 4 dígitos
- Conta Corrente: máximo 8 dígitos
- Nosso Número: máximo 7 dígitos
- Convênio: máximo 7 dígitos
- Variação: máximo 2 dígitos
- Quantidade: máximo 3 dígitos

### Exemplo de Uso

```ruby
boleto = Brcobranca::Boleto::Sicoob.new(
  valor: 50.00,
  cedente: 'Empresa Exemplo Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Marcos Pereira',
  sacado_documento: '12345678900',
  agencia: '4327',
  conta_corrente: '417270',
  convenio: '229385',
  nosso_numero: '2',
  variacao: '01',
  quantidade: '001',
  carteira: '1',
  data_documento: Date.today,
  data_vencimento: Date.today + 30,
  aceite: 'N'
)
```

### Valores Padrão

- `carteira`: '1'
- `variacao`: '01'
- `quantidade`: '001'

---

## Dados Retornados ao Gerar o Boleto

Ao instanciar um boleto, os seguintes métodos estão disponíveis:

### Métodos Principais

```ruby
boleto = Brcobranca::Boleto::BancoBanco.new(parametros)

# Validação
boleto.valid?                    # => true/false
boleto.errors.full_messages      # => Array de erros

# Código de barras e linha digitável
boleto.codigo_barras             # => "00190000090123456789012345678901234"
boleto.codigo_barras.linha_digitavel  # => "00190.00009 01234.567890 12345.678901 2 34560000012345"

# Nosso número formatado
boleto.nosso_numero_boleto       # => Formato específico do banco

# Agência e conta formatadas
boleto.agencia_conta_boleto      # => Formato específico do banco

# Dígitos verificadores
boleto.nosso_numero_dv           # => Dígito verificador do nosso número
boleto.banco_dv                  # => Dígito verificador do banco
```

### Geração de PDF/HTML

```ruby
# Gerar PDF
boleto.to(:pdf)

# Gerar HTML
boleto.to(:html)

# Salvar em arquivo
File.open('boleto.pdf', 'wb') { |f| f.write boleto.to(:pdf) }
```

### Estrutura de Dados Completa

```ruby
{
  banco: boleto.banco,                           # Código do banco (3 dígitos)
  banco_dv: boleto.banco_dv,                     # DV do banco
  agencia: boleto.agencia,                       # Agência
  conta_corrente: boleto.conta_corrente,         # Conta corrente
  convenio: boleto.convenio,                     # Convênio
  carteira: boleto.carteira,                     # Carteira
  nosso_numero: boleto.nosso_numero,             # Nosso número
  nosso_numero_dv: boleto.nosso_numero_dv,       # DV do nosso número
  nosso_numero_boleto: boleto.nosso_numero_boleto, # Nosso número formatado
  agencia_conta_boleto: boleto.agencia_conta_boleto, # Agência/Conta formatado
  codigo_barras: boleto.codigo_barras,           # Código de barras (44 dígitos)
  linha_digitavel: boleto.codigo_barras.linha_digitavel, # Linha digitável
  valor: boleto.valor,                           # Valor do boleto
  valor_documento: boleto.valor_documento,       # Valor formatado
  data_vencimento: boleto.data_vencimento,       # Data de vencimento
  data_documento: boleto.data_documento,         # Data do documento
  data_processamento: boleto.data_processamento, # Data de processamento
  cedente: boleto.cedente,                       # Nome do beneficiário
  documento_cedente: boleto.documento_cedente,   # CPF/CNPJ beneficiário
  sacado: boleto.sacado,                         # Nome do pagador
  sacado_documento: boleto.sacado_documento,     # CPF/CNPJ pagador
  sacado_endereco: boleto.sacado_endereco,       # Endereço do pagador
  local_pagamento: boleto.local_pagamento,       # Local de pagamento
  especie: boleto.especie,                       # Espécie da moeda
  especie_documento: boleto.especie_documento,   # Espécie do documento
  aceite: boleto.aceite,                         # Aceite (S/N)
  instrucoes: boleto.instrucoes,                 # Instruções
  emv: boleto.emv                                # Código QR PIX (se disponível)
}
```

---

## Observações Importantes

### Validações

Todos os boletos validam automaticamente:
- Presença de campos obrigatórios
- Tamanhos máximos/mínimos
- Formato de valores numéricos
- Datas válidas

### Dígitos Verificadores

Os dígitos verificadores são calculados automaticamente:
- Não é necessário informar
- Cada banco tem seu algoritmo específico
- Módulo 10, Módulo 11 ou variações

### Formatação Automática

Os campos são formatados automaticamente:
- Completados com zeros à esquerda
- Ajustados aos tamanhos corretos
- Conversão de tipos quando necessário

### Testes

Sempre valide o boleto antes de usar:

```ruby
if boleto.valid?
  # Gerar boleto
  boleto.to(:pdf)
else
  # Exibir erros
  puts boleto.errors.full_messages
end
```

---

## Suporte e Contribuições

- **Repositório:** https://github.com/kivanio/brcobranca
- **Documentação:** https://github.com/kivanio/brcobranca/wiki
- **Issues:** https://github.com/kivanio/brcobranca/issues

---

**Última atualização:** 2025-11-24
**Versão da Gem:** 12.0.0
**Mantido por:** Maxwell da Silva Oliveira (@maxwbh) - M&S do Brasil Ltda
