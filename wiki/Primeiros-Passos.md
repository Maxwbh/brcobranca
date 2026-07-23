# Primeiros Passos

## 1. Instalação

### Gemfile

```ruby
gem 'brcobranca'
```

```bash
bundle install
```

### GhostScript (obrigatório para template RGhost)

```bash
# Ubuntu/Debian
sudo apt-get install ghostscript

# macOS
brew install ghostscript

# Alpine (Docker)
apk add ghostscript

# Verificar instalação
gs --version
```

> **Sem GhostScript?** Use o [template Prawn](Migração-RGhost-para-Prawn) como alternativa.

---

## 2. Configuração

```ruby
# config/initializers/brcobranca.rb (Rails)
# ou no início do seu script Ruby

Brcobranca.setup do |config|
  config.gerador = :rghost          # :rghost, :rghost_carne, :rghost_bolepix
  config.formato = :pdf             # :pdf, :jpg, :png, :ps
  config.resolucao = 150            # DPI
end
```

### Geradores disponíveis

| Gerador | Descrição | Requer GhostScript |
|---------|-----------|:------------------:|
| `:rghost` | Boleto tradicional | Sim |
| `:rghost_carne` | Carnê (3 boletos por página) | Sim |
| `:rghost_bolepix` | Boleto híbrido com QR Code PIX | Sim |

---

## 3. Primeiro boleto

```ruby
require 'brcobranca'

boleto = Brcobranca::Boleto::Bradesco.new(
  agencia: '0548',
  conta_corrente: '0001448',
  carteira: '06',
  nosso_numero: '00000004042',
  valor: 135.00,
  data_vencimento: Date.today + 30,
  cedente: 'Minha Empresa LTDA',
  documento_cedente: '12345678000190',
  sacado: 'Cliente da Silva',
  sacado_documento: '12345678901',
  sacado_endereco: 'Rua das Flores, 123 - Centro - Sao Paulo/SP'
)

# Validar
if boleto.valid?
  puts "Codigo de barras: #{boleto.codigo_barras}"
  puts "Linha digitavel:  #{boleto.linha_digitavel}"
else
  puts "Erros: #{boleto.errors.full_messages.join(', ')}"
end

# Gerar PDF
File.open('boleto.pdf', 'wb') { |f| f.write(boleto.to(:pdf)) }
```

---

## 4. Primeira remessa (CNAB 400)

```ruby
pagamento = Brcobranca::Remessa::Pagamento.new(
  valor: 135.00,
  data_vencimento: Date.today + 30,
  nosso_numero: '00000004042',
  documento_sacado: '12345678901',
  nome_sacado: 'Cliente da Silva',
  endereco_sacado: 'Rua das Flores, 123',
  bairro_sacado: 'Centro',
  cep_sacado: '01234567',
  cidade_sacado: 'Sao Paulo',
  uf_sacado: 'SP'
)

remessa = Brcobranca::Remessa::Cnab400::Bradesco.new(
  carteira: '06',
  agencia: '0548',
  conta_corrente: '0001448',
  digito_conta: '6',
  empresa_mae: 'Minha Empresa LTDA',
  documento_cedente: '12345678000190',
  codigo_empresa: '00000000000000123456',
  sequencial_remessa: '0000001',
  pagamentos: [pagamento]
)

File.open('remessa.rem', 'w') { |f| f.write(remessa.gera_arquivo) }
```

---

## 5. Primeiro retorno

```ruby
retornos = Brcobranca::Retorno::Cnab400::Bradesco.load_lines(
  File.open('retorno.ret')
)

retornos.each do |r|
  puts "Nosso Numero: #{r.nosso_numero}"
  puts "Valor pago:   #{r.valor_recebido}"
  puts "Data credito: #{r.data_credito}"
  puts "Ocorrencia:   #{r.codigo_ocorrencia}"
end
```

---

## 6. Dados do boleto para API (JSON)

```ruby
# Hash completo
boleto.to_hash
# => { cedente: '...', codigo_barras: '...', linha_digitavel: '...', ... }

# Apenas dados calculados
boleto.to_hash(somente_calculados: true)

# JSON string
boleto.to_json

# Com validação (nunca lança exceção)
boleto.as_json_seguro
# => { valid: true/false, errors: [...], ... }
```

---

## Próximos passos

- [[Configuração PIX]] — adicionar QR Code PIX ao boleto
- [[Bancos Suportados]] — ver campos específicos por banco
- [Referência da API](https://github.com/Maxwbh/brcobranca/blob/master/docs/api_referencia.md) — `to_hash`/`as_json`/`to_json`
