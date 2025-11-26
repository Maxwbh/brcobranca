# Guia de Início Rápido - BRCobrança

Este guia vai te ajudar a começar a usar a gem BRCobrança rapidamente para gerar boletos bancários.

## Índice

- [Instalação](#instalação)
- [Configuração Básica](#configuração-básica)
- [Gerando Seu Primeiro Boleto](#gerando-seu-primeiro-boleto)
- [Exemplos por Banco](#exemplos-por-banco)
- [Validação e Erros](#validação-e-erros)
- [Exportando Boletos](#exportando-boletos)
- [Próximos Passos](#próximos-passos)

---

## Instalação

### Via Bundler (Recomendado)

Adicione ao seu `Gemfile`:

```ruby
gem 'brcobranca'
```

Execute:

```bash
bundle install
```

### Via RubyGems

```bash
gem install brcobranca
```

---

## Configuração Básica

### 1. Require da Gem

```ruby
require 'brcobranca'
```

### 2. Configuração Opcional

```ruby
# Configure o gerador (padrão: rghost)
Brcobranca.setup do |config|
  # Opções: :rghost, :prawn
  config.gerador = :rghost
end
```

---

## Gerando Seu Primeiro Boleto

### Exemplo Simples (Itaú)

```ruby
require 'brcobranca'

# Criar instância do boleto
boleto = Brcobranca::Boleto::Itau.new(
  # Dados do beneficiário (quem vai receber)
  cedente: 'M&S do Brasil Ltda',
  documento_cedente: '12345678000190',
  cedente_endereco: 'Rua Exemplo, 123 - São Paulo/SP',

  # Dados do pagador (quem vai pagar)
  sacado: 'João da Silva',
  sacado_documento: '12345678900',
  sacado_endereco: 'Rua do Cliente, 456 - Rio de Janeiro/RJ',

  # Dados do banco
  agencia: '0810',
  conta_corrente: '53678',
  convenio: '12387',
  carteira: '175',

  # Dados do boleto
  nosso_numero: '258281',
  valor: 100.50,
  data_documento: Date.today,
  data_vencimento: Date.today + 30,

  # Informações adicionais
  documento_numero: 'NF-001',
  instrucoes: 'Não receber após o vencimento'
)

# Validar o boleto
if boleto.valid?
  puts "Boleto válido!"
  puts "Código de barras: #{boleto.codigo_barras}"
  puts "Linha digitável: #{boleto.codigo_barras.linha_digitavel}"
  puts "Nosso número: #{boleto.nosso_numero_boleto}"

  # Gerar PDF
  File.open('boleto.pdf', 'wb') { |f| f.write boleto.to(:pdf) }
  puts "Boleto salvo em boleto.pdf"
else
  puts "Erros encontrados:"
  boleto.errors.full_messages.each do |erro|
    puts "- #{erro}"
  end
end
```

---

## Exemplos por Banco

### Banco do Brasil (001)

```ruby
boleto = Brcobranca::Boleto::BancoBrasil.new(
  cedente: 'Sua Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Exemplo',
  sacado_documento: '12345678900',

  agencia: '4042',
  conta_corrente: '61900',
  convenio: 12387989,        # 8 dígitos
  nosso_numero: '777700168', # 9 dígitos (para convênio de 8)
  carteira: '18',

  valor: 150.00,
  data_vencimento: Date.today + 30
)
```

### Bradesco (237)

```ruby
boleto = Brcobranca::Boleto::Bradesco.new(
  cedente: 'Sua Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Exemplo',
  sacado_documento: '12345678900',

  agencia: '4042',
  conta_corrente: '61900',
  nosso_numero: '777700168',
  carteira: '03',

  valor: 250.00,
  data_vencimento: Date.today + 30
)
```

### Santander (033)

```ruby
boleto = Brcobranca::Boleto::Santander.new(
  cedente: 'Sua Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Exemplo',
  sacado_documento: '12345678900',

  agencia: '0059',
  convenio: '1899775',
  conta_corrente: '013000123',
  nosso_numero: '9000026',
  carteira: '102',

  valor: 300.00,
  data_vencimento: Date.today + 30
)
```

### Caixa (104)

```ruby
boleto = Brcobranca::Boleto::Caixa.new(
  cedente: 'Sua Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Exemplo',
  sacado_documento: '12345678900',

  agencia: '1825',
  conta_corrente: '0000528',
  convenio: '245274',              # Exatamente 6 dígitos
  nosso_numero: '000000000000001', # Exatamente 15 dígitos
  carteira: '1',  # 1=Registrada, 2=Sem Registro
  emissao: '4',   # 4=Beneficiário

  valor: 500.00,
  data_vencimento: Date.today + 30
)
```

### Sicoob (756)

```ruby
boleto = Brcobranca::Boleto::Sicoob.new(
  cedente: 'Sua Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Exemplo',
  sacado_documento: '12345678900',

  agencia: '4327',
  conta_corrente: '417270',
  convenio: '229385',
  nosso_numero: '2',
  variacao: '01',
  quantidade: '001',
  carteira: '1',
  aceite: 'N',

  valor: 75.00,
  data_vencimento: Date.today + 30
)
```

### Sicredi (748)

```ruby
boleto = Brcobranca::Boleto::Sicredi.new(
  cedente: 'Sua Empresa Ltda',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Exemplo',
  sacado_documento: '12345678900',

  agencia: '0710',
  conta_corrente: '61900',
  convenio: '129',
  nosso_numero: '8879',
  posto: '65',        # Obrigatório
  byte_idt: '2',      # 1=agência, 2-9=beneficiário
  carteira: '1',      # 1=Com Registro, 3=Sem Registro

  valor: 195.57,
  data_processamento: Date.today,
  data_vencimento: Date.today + 30
)
```

---

## Validação e Erros

### Validando um Boleto

```ruby
boleto = Brcobranca::Boleto::Itau.new(params)

if boleto.valid?
  # Boleto válido, pode gerar
  puts "✓ Boleto válido"
else
  # Exibir erros
  puts "✗ Erros encontrados:"
  boleto.errors.full_messages.each do |erro|
    puts "  - #{erro}"
  end
end
```

### Erros Comuns

```ruby
# Exemplo de erros que podem ocorrer:

# Campo obrigatório faltando
# => "Agencia não pode estar em branco."

# Tamanho incorreto
# => "Nosso numero deve ser menor ou igual a 8 dígitos."

# Tipo incorreto
# => "Convenio não é um número."

# Data inválida
# => "Data vencimento deve ser uma data válida."
```

### Tratamento de Erros Recomendado

```ruby
def gerar_boleto(params)
  boleto = Brcobranca::Boleto::Itau.new(params)

  unless boleto.valid?
    raise StandardError, "Boleto inválido: #{boleto.errors.full_messages.join(', ')}"
  end

  boleto.to(:pdf)
rescue StandardError => e
  Rails.logger.error "Erro ao gerar boleto: #{e.message}"
  nil
end
```

---

## Exportando Boletos

### PDF

```ruby
# Gerar como string
pdf_string = boleto.to(:pdf)

# Salvar em arquivo
File.open('boleto.pdf', 'wb') { |f| f.write boleto.to(:pdf) }

# Em um controller Rails
send_data boleto.to(:pdf),
          filename: "boleto_#{boleto.nosso_numero}.pdf",
          type: 'application/pdf',
          disposition: 'inline' # ou 'attachment' para download
```

### HTML

```ruby
# Gerar como HTML
html = boleto.to(:html)

# Salvar em arquivo
File.open('boleto.html', 'w') { |f| f.write boleto.to(:html) }

# Em um controller Rails
render html: boleto.to(:html).html_safe
```

### JSON (para APIs)

```ruby
# Extrair dados do boleto para JSON
boleto_data = {
  banco: boleto.banco,
  agencia_conta: boleto.agencia_conta_boleto,
  nosso_numero: boleto.nosso_numero_boleto,
  codigo_barras: boleto.codigo_barras,
  linha_digitavel: boleto.codigo_barras.linha_digitavel,
  valor: boleto.valor,
  vencimento: boleto.data_vencimento,
  cedente: boleto.cedente,
  sacado: boleto.sacado
}

# Retornar como JSON
render json: boleto_data
```

### Múltiplos Boletos em um PDF

```ruby
require 'prawn'

boletos = [boleto1, boleto2, boleto3]

Prawn::Document.generate("boletos_lote.pdf") do |pdf|
  boletos.each_with_index do |boleto, index|
    pdf.start_new_page unless index.zero?
    pdf.text boleto.to(:html) # Adaptar conforme necessário
  end
end
```

---

## Dicas e Boas Práticas

### 1. Campos Obrigatórios

Sempre verifique os campos obrigatórios para cada banco na [documentação de campos](CAMPOS_BANCOS.md).

### 2. Ambiente de Testes

```ruby
# Use valores de teste em desenvolvimento
if Rails.env.development?
  boleto.valor = 0.01 # Valor mínimo
  boleto.instrucoes = '[AMBIENTE DE TESTES] Este é um boleto de teste'
end
```

### 3. Validação Prévia

```ruby
# Validar antes de salvar no banco de dados
def create
  @boleto_params = boleto_params
  boleto = Brcobranca::Boleto::Itau.new(@boleto_params)

  if boleto.valid?
    @cobranca = Cobranca.create!(
      boleto_params: @boleto_params.to_json,
      codigo_barras: boleto.codigo_barras,
      linha_digitavel: boleto.codigo_barras.linha_digitavel
    )
    redirect_to @cobranca
  else
    flash[:error] = boleto.errors.full_messages.join(', ')
    render :new
  end
end
```

### 4. Cache de Boletos

```ruby
# Salvar o PDF gerado para evitar regenerar
class Cobranca < ApplicationRecord
  def gerar_boleto_pdf
    return boleto_pdf if boleto_pdf.present?

    boleto = Brcobranca::Boleto::Itau.new(JSON.parse(boleto_params))
    pdf = boleto.to(:pdf)

    update(boleto_pdf: pdf)
    pdf
  end
end
```

### 5. Log de Geração

```ruby
# Manter log de boletos gerados
boleto = Brcobranca::Boleto::Itau.new(params)

if boleto.valid?
  Rails.logger.info "Boleto gerado: #{boleto.banco}-#{boleto.nosso_numero_boleto}"
  Rails.logger.info "Valor: R$ #{boleto.valor} - Vencimento: #{boleto.data_vencimento}"
end
```

---

## Integração com Rails

### Model Exemplo

```ruby
class Cobranca < ApplicationRecord
  BANCOS = {
    'itau' => Brcobranca::Boleto::Itau,
    'bradesco' => Brcobranca::Boleto::Bradesco,
    'banco_brasil' => Brcobranca::Boleto::BancoBrasil,
    'santander' => Brcobranca::Boleto::Santander,
    'caixa' => Brcobranca::Boleto::Caixa
  }.freeze

  validates :banco, inclusion: { in: BANCOS.keys }

  def gerar_boleto
    classe_boleto = BANCOS[banco]
    boleto = classe_boleto.new(
      cedente: empresa.nome,
      documento_cedente: empresa.cnpj,
      sacado: cliente.nome,
      sacado_documento: cliente.cpf_cnpj,
      agencia: conta_bancaria.agencia,
      conta_corrente: conta_bancaria.conta,
      convenio: conta_bancaria.convenio,
      nosso_numero: nosso_numero,
      valor: valor,
      data_vencimento: vencimento,
      carteira: conta_bancaria.carteira
    )

    raise "Boleto inválido: #{boleto.errors.full_messages.join(', ')}" unless boleto.valid?

    update!(
      codigo_barras: boleto.codigo_barras,
      linha_digitavel: boleto.codigo_barras.linha_digitavel,
      nosso_numero_formatado: boleto.nosso_numero_boleto
    )

    boleto
  end
end
```

### Controller Exemplo

```ruby
class BoletosController < ApplicationController
  def show
    @cobranca = Cobranca.find(params[:id])
    @boleto = @cobranca.gerar_boleto

    respond_to do |format|
      format.html
      format.pdf do
        send_data @boleto.to(:pdf),
                  filename: "boleto_#{@cobranca.id}.pdf",
                  type: 'application/pdf',
                  disposition: 'inline'
      end
      format.json do
        render json: {
          codigo_barras: @boleto.codigo_barras,
          linha_digitavel: @boleto.codigo_barras.linha_digitavel,
          nosso_numero: @boleto.nosso_numero_boleto,
          valor: @boleto.valor,
          vencimento: @boleto.data_vencimento
        }
      end
    end
  end
end
```

---

## Troubleshooting

### Erro: "não pode estar em branco"

Verifique se todos os campos obrigatórios estão preenchidos. Consulte [CAMPOS_BANCOS.md](CAMPOS_BANCOS.md).

### Erro: "deve ser menor ou igual a X dígitos"

O campo está excedendo o tamanho máximo. Ajuste o valor.

### Erro: "não é um número"

Certifique-se de passar valores numéricos como Integer ou String, não como outros tipos.

### PDF não é gerado

Verifique se o RGhost está instalado:

```bash
# macOS
brew install ghostscript

# Ubuntu/Debian
sudo apt-get install ghostscript

# Ou use Prawn
Brcobranca.setup do |config|
  config.gerador = :prawn
end
```

### Código de barras inválido

Valide o boleto antes de gerar:

```ruby
raise "Boleto inválido" unless boleto.valid?
```

---

## Próximos Passos

1. **Leia a documentação completa de campos:** [CAMPOS_BANCOS.md](CAMPOS_BANCOS.md)
2. **Configure remessa e retorno:** Consulte a documentação da gem
3. **Implemente testes:** Garanta que seus boletos funcionam corretamente
4. **Configure ambiente de produção:** Veja o guia de deploy no [README.md](README.md)

---

## Recursos Adicionais

- **Repositório:** https://github.com/kivanio/brcobranca
- **Wiki:** https://github.com/kivanio/brcobranca/wiki
- **Issues:** https://github.com/kivanio/brcobranca/issues
- **RubyDoc:** http://rubydoc.info/gems/brcobranca

---

## Suporte

Para dúvidas e suporte:

1. Consulte a [Wiki](https://github.com/kivanio/brcobranca/wiki)
2. Abra uma [Issue](https://github.com/kivanio/brcobranca/issues)
3. Entre em contato com a comunidade

---

**Mantido por:** Maxwell da Silva Oliveira (@maxwbh) - M&S do Brasil Ltda
**Última atualização:** 2025-11-24
