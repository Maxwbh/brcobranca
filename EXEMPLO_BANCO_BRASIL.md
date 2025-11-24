# Exemplo de Uso - Banco do Brasil

## Geração de Boleto com Todos os Campos

Este exemplo mostra como gerar um boleto do Banco do Brasil com todos os campos corretamente preenchidos, incluindo o campo `documento_numero`.

### Exemplo Básico

```ruby
require 'brcobranca'

boleto = Brcobranca::Boleto::BancoBrasil.new do |b|
  # === DADOS DO BENEFICIÁRIO (CEDENTE) ===
  b.cedente = 'Sua Empresa LTDA'
  b.cedente_endereco = 'Rua Example, 123 - Centro - CEP 12345-678 - Cidade/UF'
  b.documento_cedente = '12.345.678/0001-90'  # CNPJ ou CPF

  # === DADOS BANCÁRIOS ===
  b.agencia = '1234'            # Número da agência SEM dígito
  b.conta_corrente = '12345678' # Número da conta SEM dígito
  b.convenio = 12345678         # Número do convênio (4, 6, 7 ou 8 dígitos)
  b.carteira = '18'             # Modalidade de cobrança (padrão: 18)

  # === NOSSO NÚMERO ===
  # Tamanho depende do convênio:
  # - Convênio 4 dígitos: nosso_numero com 7 dígitos
  # - Convênio 6 dígitos: nosso_numero com 5 dígitos (ou 17 com codigo_servico=true)
  # - Convênio 7 dígitos: nosso_numero com 10 dígitos
  # - Convênio 8 dígitos: nosso_numero com 9 dígitos
  b.nosso_numero = '123456789'  # Exemplo para convênio de 8 dígitos

  # === DADOS DO DOCUMENTO ===
  b.documento_numero = 'NF-001234'  # IMPORTANTE: Número da NF/Pedido/Contrato
  b.data_documento = Date.today
  b.data_vencimento = Date.today + 30  # Vencimento em 30 dias
  b.valor = 1234.56
  b.especie_documento = 'DM'   # DM = Duplicata Mercantil
  b.aceite = 'N'

  # === DADOS DO PAGADOR (SACADO) ===
  b.sacado = 'Nome do Cliente'
  b.sacado_documento = '123.456.789-00'  # CPF ou CNPJ
  b.sacado_endereco = 'Rua do Cliente, 456 - Bairro - CEP 98765-432 - Cidade/UF'

  # === INSTRUÇÕES (OPCIONAL) ===
  b.instrucoes = <<~INSTRUCOES
    - Não receber após o vencimento
    - Multa de 2% após o vencimento
    - Juros de 1% ao mês
  INSTRUCOES

  # === DEMONSTRATIVO (OPCIONAL) ===
  b.demonstrativo = 'Pagamento referente à NF-001234'
end

# Validar o boleto
unless boleto.valid?
  puts "ERRO: Boleto inválido!"
  boleto.errors.full_messages.each do |erro|
    puts "  - #{erro}"
  end
  exit 1
end

# Verificar campos gerados
puts "Nosso Número: #{boleto.nosso_numero_boleto}"
puts "Código de Barras: #{boleto.codigo_barras}"
puts "Linha Digitável: #{boleto.codigo_barras.linha_digitavel}"
puts "Documento Número: #{boleto.documento_numero}"

# Gerar PDF
pdf = boleto.to_pdf
File.open('boleto.pdf', 'wb') { |f| f.write(pdf) }
puts "Boleto gerado: boleto.pdf"
```

### Campos Obrigatórios

Segundo a documentação oficial do Banco do Brasil, os seguintes campos são **obrigatórios**:

#### Para geração do código de barras:
- `cedente` - Nome do beneficiário
- `documento_cedente` - CNPJ/CPF do beneficiário
- `agencia` - Número da agência
- `conta_corrente` - Número da conta corrente
- `convenio` - Número do convênio (4, 6, 7 ou 8 dígitos)
- `nosso_numero` - Número sequencial do boleto
- `sacado` - Nome do pagador
- `sacado_documento` - CPF/CNPJ do pagador
- `data_vencimento` - Data de vencimento
- `valor` - Valor do boleto

#### Para o Recibo do Pagador (segundo Doc5175Bloqueto.pdf, página 3):
- `cedente` - Nome do beneficiário
- `cedente_endereco` - Endereço do beneficiário
- `documento_cedente` - CNPJ/CPF do beneficiário
- `sacado` - Nome do pagador
- `nosso_numero` - Nosso número
- **`documento_numero` - Número do documento** ✓
- `data_vencimento` - Data de vencimento
- `valor` - Valor do documento

## Troubleshooting - Campos Vazios no PDF

Se você está gerando PDFs com campos vazios (linha digitável, código de barras, nosso número), verifique:

### 1. Validação do Boleto

**SEMPRE** valide o boleto antes de gerar o PDF:

```ruby
if boleto.valid?
  pdf = boleto.to_pdf
else
  puts "Erros:"
  boleto.errors.full_messages.each { |m| puts "  - #{m}" }
end
```

### 2. Campos Obrigatórios

Certifique-se de preencher TODOS os campos obrigatórios listados acima.

### 3. Nome Correto dos Campos

⚠️ **ATENÇÃO**: O campo é `documento_numero`, não `numero_documento`!

```ruby
# ✓ CORRETO
b.documento_numero = 'NF-001234'

# ✗ ERRADO - Vai gerar erro
b.numero_documento = 'NF-001234'
```

### 4. Tamanho do Nosso Número

O tamanho do `nosso_numero` depende do tamanho do `convenio`:

| Convênio | Nosso Número |
|----------|--------------|
| 4 dígitos | 7 dígitos |
| 6 dígitos | 5 dígitos (ou 17 com `codigo_servico = true`) |
| 7 dígitos | 10 dígitos |
| 8 dígitos | 9 dígitos |

Exemplo:
```ruby
# Convênio de 8 dígitos
b.convenio = 12345678
b.nosso_numero = '123456789'  # 9 dígitos

# Convênio de 7 dígitos
b.convenio = 1234567
b.nosso_numero = '1234567890'  # 10 dígitos
```

### 5. Formato de Datas

Use objetos `Date` do Ruby:

```ruby
b.data_documento = Date.today
b.data_vencimento = Date.parse('2025-12-31')
# ou
b.data_vencimento = Date.new(2025, 12, 31)
```

## Exemplo Completo com Tratamento de Erros

```ruby
require 'brcobranca'

begin
  boleto = Brcobranca::Boleto::BancoBrasil.new(
    cedente: 'Sua Empresa LTDA',
    cedente_endereco: 'Rua Example, 123 - Centro',
    documento_cedente: '12.345.678/0001-90',
    agencia: '1234',
    conta_corrente: '12345678',
    convenio: 12345678,
    nosso_numero: '123456789',
    documento_numero: 'NF-001234',  # ← CAMPO IMPORTANTE!
    data_documento: Date.today,
    data_vencimento: Date.today + 30,
    valor: 1234.56,
    sacado: 'Nome do Cliente',
    sacado_documento: '123.456.789-00',
    sacado_endereco: 'Rua do Cliente, 456'
  )

  # Validar
  unless boleto.valid?
    raise "Boleto inválido: #{boleto.errors.full_messages.join(', ')}"
  end

  # Mostrar informações
  puts "=" * 80
  puts "BOLETO GERADO COM SUCESSO"
  puts "=" * 80
  puts "Nosso Número: #{boleto.nosso_numero_boleto}"
  puts "Código de Barras: #{boleto.codigo_barras}"
  puts "Linha Digitável: #{boleto.codigo_barras.linha_digitavel}"
  puts "Documento Número: #{boleto.documento_numero}"
  puts "=" * 80

  # Gerar PDF
  pdf = boleto.to_pdf
  File.open('boleto_bb.pdf', 'wb') { |f| f.write(pdf) }
  puts "✓ PDF gerado: boleto_bb.pdf"

rescue => e
  puts "✗ ERRO: #{e.message}"
  puts e.backtrace.first(5).join("\n") if ENV['DEBUG']
  exit 1
end
```

## Referências

- Documentação oficial BB: `/docs/Banco do Brasil/Doc5175Bloqueto.pdf`
- Especificações técnicas: `lib/brcobranca/boleto/banco_brasil.rb`
- Testes: `spec/brcobranca/boleto/banco_brasil_spec.rb`
