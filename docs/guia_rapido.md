# Guia Rápido - BRCobranca

Este guia mostra como começar a usar o BRCobranca rapidamente.

## Instalação

### Gemfile

```ruby
gem 'brcobranca'
```

### Instalação manual

```bash
gem install brcobranca
```

### Requisitos do Sistema

O GhostScript 9.0+ é necessário para geração de PDFs:

```bash
# Ubuntu/Debian
sudo apt-get install ghostscript

# macOS
brew install ghostscript

# Alpine (Docker)
apk add ghostscript
```

---

## Uso Básico

### 1. Criar um Boleto

```ruby
require 'brcobranca'

boleto = Brcobranca::Boleto::Bradesco.new(
  carteira: '06',
  nosso_numero: '00000004042',
  agencia: '0548',
  conta_corrente: '0001448',
  valor: 135.00,
  data_vencimento: Date.today + 30,
  cedente: 'Minha Empresa LTDA',
  documento_cedente: '12.345.678/0001-90',
  sacado: 'João da Silva',
  sacado_documento: '123.456.789-01',
  sacado_endereco: 'Rua das Flores, 123 - Centro - São Paulo/SP'
)

# Verificar se é válido
if boleto.valid?
  puts "Boleto válido!"
  puts "Código de barras: #{boleto.codigo_barras}"
  puts "Linha digitável: #{boleto.linha_digitavel}"
else
  puts "Erros: #{boleto.errors.full_messages.join(', ')}"
end
```

### 2. Gerar PDF

```ruby
# PDF único
boleto.to(Brcobranca.configuration.formato) # :pdf

# Múltiplos boletos em um PDF
boletos = [boleto1, boleto2, boleto3]
Brcobranca::Boleto::Base.lote(boletos, formato: :pdf)
```

### 3. Salvar arquivo

```ruby
File.open('boleto.pdf', 'wb') do |file|
  file.write(boleto.to(:pdf))
end
```

---

## Configuração Global

```ruby
# config/initializers/brcobranca.rb (Rails)

Brcobranca.setup do |config|
  # Gerador de PDF (:rghost, :rghost_carne, :rghost_bolepix)
  config.gerador = :rghost

  # Formato do arquivo (:pdf, :jpg, :png, :ps)
  config.formato = :pdf

  # Resolução em DPI
  config.resolucao = 150
end
```

---

## Arquivo de Remessa (CNAB)

### CNAB 400

```ruby
remessa = Brcobranca::Remessa::Cnab400::Bradesco.new(
  carteira: '06',
  agencia: '0548',
  conta_corrente: '0001448',
  digito_conta: '6',
  empresa_mae: 'Minha Empresa LTDA',
  documento_cedente: '12345678000190',
  codigo_empresa: '00000000000000123456',
  sequencial_remessa: '0000001',
  pagamentos: [
    Brcobranca::Remessa::Pagamento.new(
      valor: 135.00,
      data_vencimento: Date.today + 30,
      nosso_numero: '00000004042',
      documento: '12345',
      documento_sacado: '12345678901',
      nome_sacado: 'João da Silva',
      endereco_sacado: 'Rua das Flores, 123',
      cep_sacado: '01234567',
      cidade_sacado: 'São Paulo',
      uf_sacado: 'SP'
    )
  ]
)

# Gerar arquivo
File.open('remessa.rem', 'w') do |file|
  file.write(remessa.gera_arquivo)
end
```

### CNAB 240

```ruby
remessa = Brcobranca::Remessa::Cnab240::Santander.new(
  # ... campos específicos do banco
)
```

---

## Arquivo de Retorno

### Processar CNAB 400

```ruby
# Bradesco
retornos = Brcobranca::Retorno::Cnab400::Bradesco.load_lines(
  File.open('retorno.ret')
)

retornos.each do |retorno|
  puts "Nosso Número: #{retorno.nosso_numero}"
  puts "Valor: #{retorno.valor_recebido}"
  puts "Data Crédito: #{retorno.data_credito}"
  puts "Ocorrência: #{retorno.codigo_ocorrencia}"
end
```

### Processar CNAB 240

```ruby
retornos = Brcobranca::Retorno::Cnab240::Santander.load_lines(
  File.open('retorno.ret')
)
```

---

## Boleto com PIX (Cobrança Híbrida)

```ruby
Brcobranca.setup do |config|
  config.gerador = :rghost_bolepix
end

boleto = Brcobranca::Boleto::Santander.new(
  # ... campos normais
  emv: 'PAYLOAD_PIX_AQUI' # Código EMV para QRCode
)
```

---

## Integração com Rails

### Controller

```ruby
class BoletosController < ApplicationController
  def show
    @boleto = criar_boleto(params[:id])

    respond_to do |format|
      format.html
      format.pdf do
        send_data @boleto.to(:pdf),
          filename: "boleto_#{@boleto.nosso_numero}.pdf",
          type: 'application/pdf',
          disposition: 'inline'
      end
    end
  end

  private

  def criar_boleto(id)
    cobranca = Cobranca.find(id)
    Brcobranca::Boleto::Bradesco.new(
      # ... mapear campos
    )
  end
end
```

### Route

```ruby
resources :boletos, only: [:show]
```

---

## Troubleshooting

### Erro: "GhostScript não encontrado"

Instale o GhostScript no sistema operacional.

### Erro: "Boleto inválido"

Verifique os campos obrigatórios usando:

```ruby
boleto.errors.full_messages
```

### Encoding de caracteres

```ruby
Brcobranca.setup do |config|
  config.external_encoding = 'utf-8'
end
```

---

## Referências

- [Documentação Completa](https://github.com/kivanio/brcobranca/wiki)
- [Campos por Banco](campos_por_banco.md)
- [RubyGems](https://rubygems.org/gems/brcobranca)

---

## Autor

**Maxwell Oliveira** - M&S do Brasil LTDA
- Email: maxwbh@gmail.com
- LinkedIn: [/maxwbh](https://linkedin.com/in/maxwbh)
- Website: [www.msbrasil.inf.br](https://www.msbrasil.inf.br)
