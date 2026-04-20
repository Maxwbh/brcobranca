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

### Com RGhost (padrão, requer GhostScript)

```ruby
Brcobranca.setup do |config|
  config.gerador = :rghost_bolepix
end

boleto = Brcobranca::Boleto::Santander.new(
  # ... campos normais
  emv: '00020126580014br.gov.bcb.pix0136...' # BR Code EMV
)

File.write('boleto.pdf', boleto.to(:pdf))
```

### Com Prawn (alternativa sem GhostScript)

```ruby
# Instale: gem install prawn prawn-table barby rqrcode chunky_png
require 'brcobranca/boleto/template/prawn_bolepix'

boleto = Brcobranca::Boleto::Sicoob.new(
  # ... campos normais
  emv: '00020126580014br.gov.bcb.pix0136...'
)
boleto.extend(Brcobranca::Boleto::Template::PrawnBolepix)

File.write('boleto.pdf', boleto.to(:pdf))
```

---

## Remessa CNAB com PIX

Para gerar arquivo remessa contendo o registro/segmento PIX, use uma das
classes `*Pix` e `PagamentoPix`:

```ruby
pagamento_pix = Brcobranca::Remessa::PagamentoPix.new(
  valor: 100.00,
  data_vencimento: Date.today + 30,
  nosso_numero: '001',
  documento_sacado: '12345678900',
  nome_sacado: 'Cliente Exemplo',
  endereco_sacado: 'Rua Exemplo, 100',
  bairro_sacado: 'Centro',
  cep_sacado: '00000000',
  cidade_sacado: 'Cidade',
  uf_sacado: 'UF',
  # Dados PIX:
  codigo_chave_dict: '12345678000100',
  tipo_chave_dict: 'cnpj',       # cpf, cnpj, email, telefone, chave_aleatoria
  valor_maximo_pix: 100.00,
  valor_minimo_pix: 100.00,
  txid: 'TXID20250101001'
)

# Bancos com PIX em CNAB 400: Bradesco, Itaú, Santander, C6
remessa = Brcobranca::Remessa::Cnab400::BradescoPix.new(
  # ... campos padrão da remessa
  pagamentos: [pagamento_pix]
)

# Bancos com PIX em CNAB 240: Banco do Brasil, Caixa, Sicoob
remessa = Brcobranca::Remessa::Cnab240::SicoobPix.new(
  # ... campos padrão da remessa
  pagamentos: [pagamento_pix]
)

File.write('remessa_pix.rem', remessa.gera_arquivo)
```

---

## Banco C6 (novo, código 336)

```ruby
boleto = Brcobranca::Boleto::BancoC6.new(
  agencia: '0001',
  convenio: '000000123456',     # Código do Cedente (12 dígitos)
  nosso_numero: '0000000001',   # 10 dígitos
  carteira: '10',               # '10' = Emissão Banco, '20' = Emissão Cliente
  valor: 100.00,
  data_vencimento: Date.today + 30,
  cedente: 'Minha Empresa LTDA',
  documento_cedente: '12345678000100',
  sacado: 'Cliente',
  sacado_documento: '12345678900'
)

# Remessa CNAB 400
remessa = Brcobranca::Remessa::Cnab400::BancoC6.new(
  codigo_beneficiario: '000000123456',
  carteira: '10',
  empresa_mae: 'Minha Empresa LTDA',
  documento_cedente: '12345678000100',
  sequencial_remessa: '1',
  pagamentos: [pagamento]
)

# Via factory
Brcobranca::Remessa.criar(banco: :c6, formato: :cnab400, **params)
```

---

## Sicoob Carteira 9 (novo, 2024/2025)

Nova modalidade que usa **Número do Contrato** em vez do Código do Cedente
no código de barras.

```ruby
boleto = Brcobranca::Boleto::Sicoob.new(
  agencia: '4327',
  convenio: '229385',
  numero_contrato: '1234567',   # Fornecido pelo Sicoob (novo campo)
  carteira: '9',                # Carteira 9 ativa a nova composição
  nosso_numero: '1',
  # ... demais campos
)
```

### Layout 810 (CNAB 240 alternativo)

Para informar que o cliente já calcula o DV do nosso número:

```ruby
remessa = Brcobranca::Remessa::Cnab240::Sicoob.new(
  versao_layout_arquivo_opcao: '810',  # '081' (padrão) ou '810'
  # ... demais campos
)
```

---

## Registro de Bancos (`Brcobranca::Bancos`)

Registro central com metadados dos 18 bancos suportados — útil para montar
seletores dinâmicos na UI ou expor um endpoint de descoberta (`boleto_cnab_api`).

```ruby
# Listar todos os bancos
Brcobranca::Bancos.todos.map { |b| "#{b[:codigo]} - #{b[:nome]}" }
#=> ["001 - Banco do Brasil", "004 - Banco do Nordeste", ..., "756 - Sicoob"]

# Buscar por código
banco = Brcobranca::Bancos.find('756')
banco[:boleto]       #=> "Sicoob"
banco[:carteiras]    #=> ["1", "3", "9"]
banco[:pix]          #=> { "240" => "Cnab240::SicoobPix" }

# Filtrar por capacidade
Brcobranca::Bancos.com_pix.size           #=> 7
Brcobranca::Bancos.com_remessa('240')     # bancos com CNAB 240
Brcobranca::Bancos.formatos_cnab          #=> ["240", "400", "444"]

# JSON pronto para API REST
Brcobranca::Bancos.to_json
```

Referência completa: [API de Bancos](api_referencia.md#api-de-bancos).

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

### Endpoint de descoberta de bancos

```ruby
# app/controllers/api/bancos_controller.rb
class Api::BancosController < ApplicationController
  def index
    render json: Brcobranca::Bancos.as_json
  end

  def show
    banco = Brcobranca::Bancos.find(params[:id])
    banco ? render(json: banco) : head(:not_found)
  end
end

# config/routes.rb
namespace :api do
  resources :bancos, only: %i[index show]
end
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

- [Documentação Completa](https://github.com/Maxwbh/brcobranca/wiki)
- [Campos por Banco](campos_por_banco.md)
- [RubyGems](https://rubygems.org/gems/brcobranca)

---

## Autor

**Maxwell Oliveira** - M&S do Brasil LTDA
- Email: maxwbh@gmail.com
- LinkedIn: [/maxwbh](https://linkedin.com/in/maxwbh)
- Website: [www.msbrasil.inf.br](https://www.msbrasil.inf.br)
