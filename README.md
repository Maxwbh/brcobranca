<h1 align="center">BRCobranca</h1>

<p align="center">
  <strong>Biblioteca Ruby para emissão de boletos bancários e arquivos CNAB</strong>
</p>

<p align="center">
  <a href="#sobre">Sobre</a> |
  <a href="#instalação">Instalação</a> |
  <a href="#uso-rápido">Uso Rápido</a> |
  <a href="#bancos-suportados">Bancos</a> |
  <a href="#documentação">Documentação</a> |
  <a href="#english">English</a>
</p>

<p align="center">
  <a href="https://github.com/Maxwbh/brcobranca/actions/workflows/ci.yml">
    <img src="https://github.com/Maxwbh/brcobranca/actions/workflows/ci.yml/badge.svg" alt="CI">
  </a>
  <a href="https://rubygems.org/gems/brcobranca">
    <img src="https://img.shields.io/gem/v/brcobranca.svg" alt="Gem Version">
  </a>
  <a href="https://rubygems.org/gems/brcobranca">
    <img src="https://img.shields.io/gem/dt/brcobranca.svg" alt="Downloads">
  </a>
  <a href="https://opensource.org/licenses/BSD-3-Clause">
    <img src="https://img.shields.io/badge/License-BSD%203--Clause-blue.svg" alt="License">
  </a>
</p>

---

## Sobre

**BRCobranca** é uma biblioteca Ruby completa para geração de boletos bancários e arquivos de remessa/retorno no padrão CNAB (240, 400 e 444 bytes) para os principais bancos brasileiros.

### Principais Recursos

- **18 bancos brasileiros** suportados (inclusive **Banco C6** — código 336)
- **Geração de boletos** em PDF com código de barras
- **Arquivos CNAB** de remessa e retorno (formatos 240, 400 e 444)
- **Validações específicas** por banco
- **Suporte a PIX** (cobrança híbrida) em **7 bancos**:
  Santander, Bradesco, Itaú, C6 (CNAB 400) + Sicoob, Caixa, Banco do Brasil (CNAB 240)
- **Campos PIX no boleto** (`chave_pix`, `tipo_chave_pix`, `txid`) — dados estruturados via `dados_pix`/`to_hash`/`as_json`
- **2 templates de renderização**:
  - **RGhost** (padrão, requer GhostScript)
  - **Prawn** (alternativa puro-Ruby, sem GhostScript)
- **Carteira 9 do Sicoob** (nova modalidade 2024/2025) e **Layout 810** (CNAB 240 alternativo)
- **API de serialização** (`to_hash`/`as_json`/`to_json`) para integração REST
- **Registro de bancos** (`Brcobranca::Bancos`) — metadados dos 18 bancos, CNAB e PIX, prontos para expor via API
- **Ruby >= 3.0** — testado em 3.0, 3.1, 3.2, 3.3, 3.4

---

## Instalação

### Gemfile

```ruby
gem 'brcobranca'
```

```bash
bundle install
```

### Requisito: GhostScript

```bash
# Ubuntu/Debian
sudo apt-get install ghostscript

# macOS
brew install ghostscript

# Alpine Linux
apk add ghostscript
```

> **Alternativa sem GhostScript:** use o [template Prawn](#template-prawn-alternativa-sem-ghostscript).

---

## Uso Rápido

### Gerar Boleto

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
  sacado_documento: '12345678901'
)

# Gerar PDF
File.open('boleto.pdf', 'wb') { |f| f.write(boleto.to(:pdf)) }

# Linha digitável
puts boleto.linha_digitavel
```

### Gerar Remessa CNAB 400

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
      documento_sacado: '12345678901',
      nome_sacado: 'Cliente da Silva',
      endereco_sacado: 'Rua das Flores, 123',
      cep_sacado: '01234567',
      cidade_sacado: 'Sao Paulo',
      uf_sacado: 'SP'
    )
  ]
)

File.open('remessa.rem', 'w') { |f| f.write(remessa.gera_arquivo) }
```

### Processar Retorno

```ruby
retornos = Brcobranca::Retorno::Cnab400::Bradesco.load_lines(
  File.open('retorno.ret')
)

retornos.each do |r|
  puts "Nosso Numero: #{r.nosso_numero}"
  puts "Valor: #{r.valor_recebido}"
  puts "Status: #{r.codigo_ocorrencia}"
end
```

---

## Bancos Suportados

| Código | Banco | Boleto | CNAB 240 | CNAB 400 | PIX |
|--------|-------|:------:|:--------:|:--------:|:---:|
| 001 | Banco do Brasil | ✅ | ✅ | ✅ | ✅ |
| 004 | Banco do Nordeste | ✅ | - | ✅ | - |
| 021 | Banestes | ✅ | - | - | - |
| 033 | Santander | ✅ | ✅ | ✅ | ✅ |
| 041 | Banrisul | ✅ | - | ✅ | - |
| 070 | Banco de Brasília | ✅ | - | ✅ | - |
| 085 | AILOS | ✅ | ✅ | - | - |
| 097 | CREDISIS | ✅ | - | ✅ | - |
| 104 | Caixa Econômica | ✅ | ✅ | - | ✅ |
| 136 | Unicred | ✅ | ✅ | ✅ | - |
| 237 | Bradesco | ✅ | - | ✅ | ✅ |
| 336 | C6 Bank | ✅ | - | ✅ | ✅ |
| 341 | Itaú | ✅ | - | ✅ (+ 444) | ✅ |
| 399 | HSBC | ✅ | - | - | - |
| 422 | Safra | ✅ | - | - | - |
| 745 | Citibank | ✅ | - | ✅ | - |
| 748 | Sicredi | ✅ | ✅ | - | - |
| 756 | Sicoob | ✅ | ✅ | ✅ | ✅ |

> Consulte programaticamente via `Brcobranca::Bancos.todos` — veja [API de Bancos](#api-de-bancos).

### Carteiras especiais

- **Sicoob (756)**:
  - Carteiras `1` / `01` — Simples Com Registro
  - Carteiras `3` / `03` — Garantida Caucionada
  - **Carteira 9** (2024/2025) — Usa `numero_contrato` no código de barras
  - Layout CNAB 240: `'081'` (padrão) ou `'810'` (cliente calcula o DV)
- **C6 Bank (336)**:
  - Carteira `10` — Emissão Banco
  - Carteira `20` — Emissão Cliente

### Bancos com PIX em remessa

| Banco | Classe PIX | Formato | Registro |
|---|---|:---:|---|
| Santander (033) | `Cnab400::SantanderPix` | 400 | Tipo 8 |
| Bradesco (237) | `Cnab400::BradescoPix` | 400 | Tipo 8 |
| Itaú (341) | `Cnab400::ItauPix` | 400 | Tipo 8 |
| C6 Bank (336) | `Cnab400::BancoC6Pix` | 400 | Tipo 8 |
| Banco do Brasil (001) | `Cnab240::BancoBrasilPix` | 240 | Segmento Y-03 |
| Caixa (104) | `Cnab240::CaixaPix` | 240 | Segmento Y-03 |
| Sicoob (756) | `Cnab240::SicoobPix` | 240 | Segmento Y-03 |

---

## Boleto com PIX

### Campos PIX no boleto

Os campos `chave_pix`, `tipo_chave_pix` e `txid` ficam disponíveis em `to_hash`/`as_json`/`dados_pix`:

```ruby
boleto = Brcobranca::Boleto::Sicoob.new(
  # ... campos obrigatórios
  chave_pix: '12345678000100',
  tipo_chave_pix: 'cnpj',
  txid: 'TXID20260528001',
  emv: '00020126580014br.gov.bcb.pix0136...'  # opcional, para QR Code
)

boleto.dados_pix
#=> { emv: '0002...', chave_pix: '12345678000100',
#     tipo_chave_pix: 'cnpj', txid: 'TXID20260528001',
#     qrcode_disponivel: true }

# JSON para API REST
boleto.to_json
```

### Boleto PDF com QR Code PIX (Bolepix)

```ruby
Brcobranca.setup { |c| c.gerador = :rghost_bolepix }

boleto = Brcobranca::Boleto::Sicoob.new(
  # ... campos padrão
  chave_pix: '12345678000100',
  tipo_chave_pix: 'cnpj',
  emv: '00020126580014br.gov.bcb.pix0136...'
)

File.write('boleto_pix.pdf', boleto.to(:pdf))
```

### Remessa com PIX (registro CNAB)

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
  codigo_chave_dict: '12345678000100',
  tipo_chave_dict: 'cnpj',
  valor_maximo_pix: 100.00,
  valor_minimo_pix: 100.00,
  txid: 'TXID20260528001'
)

# CNAB 400 (Bradesco, Itaú, Santander, C6)
remessa = Brcobranca::Remessa::Cnab400::BradescoPix.new(
  # ... campos padrão
  pagamentos: [pagamento_pix]
)

# CNAB 240 (Sicoob, Caixa, Banco do Brasil)
remessa = Brcobranca::Remessa::Cnab240::SicoobPix.new(
  # ... campos padrão
  pagamentos: [pagamento_pix]
)

File.write('remessa_pix.rem', remessa.gera_arquivo)
```

### Template Prawn (alternativa sem GhostScript)

```ruby
require 'brcobranca/boleto/template/prawn_bolepix'

boleto = Brcobranca::Boleto::Sicoob.new(
  # ... campos padrão
  emv: '00020126580014br.gov.bcb.pix0136...'
)
boleto.extend(Brcobranca::Boleto::Template::PrawnBolepix)

File.write('boleto.pdf', boleto.to(:pdf))
```

Requer: `gem install prawn prawn-table barby rqrcode chunky_png`

---

## API de Bancos

Registro central (`Brcobranca::Bancos`) com metadados dos 18 bancos — útil para
seletores dinâmicos e endpoints de descoberta.

```ruby
Brcobranca::Bancos.todos              # 18 bancos
Brcobranca::Bancos.find('756')        # busca por código
Brcobranca::Bancos.com_pix            # 7 bancos com PIX
Brcobranca::Bancos.com_remessa('240') # bancos com CNAB 240
Brcobranca::Bancos.formatos_cnab      # ["240", "400", "444"]
Brcobranca::Bancos.to_json            # JSON pronto para API REST
```

Referência completa: [docs/api_referencia.md](docs/api_referencia.md#api-de-bancos)

---

## Exemplos por banco

### Sicoob — Carteira tradicional (1)

```ruby
boleto = Brcobranca::Boleto::Sicoob.new(
  agencia: '4327',
  convenio: '229385',
  nosso_numero: '1',
  carteira: '1',
  valor: 100.00,
  data_vencimento: Date.today + 30,
  cedente: 'Minha Empresa LTDA',
  documento_cedente: '12345678000100',
  sacado: 'Cliente',
  sacado_documento: '12345678900'
)
```

### Sicoob — Carteira 9 (com número de contrato)

```ruby
boleto = Brcobranca::Boleto::Sicoob.new(
  agencia: '4327',
  convenio: '229385',
  numero_contrato: '1234567',
  carteira: '9',
  nosso_numero: '1',
  valor: 100.00,
  # ... demais campos
)
```

### C6 Bank — Boleto e Remessa

```ruby
boleto = Brcobranca::Boleto::BancoC6.new(
  agencia: '0001',
  convenio: '000000123456',
  nosso_numero: '0000000001',
  carteira: '10',
  valor: 100.00,
  # ... demais campos
)

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

## Documentação

| Documento | Descrição |
|-----------|-----------|
| [Guia Rápido](docs/guia_rapido.md) | Tutorial de início rápido |
| [Campos por Banco](docs/campos_por_banco.md) | Referência de campos obrigatórios |
| [API de Serialização](docs/api_referencia.md) | `to_hash`, `as_json`, `dados_pix`, factory methods |
| [API de Bancos](docs/api_referencia.md#api-de-bancos) | `Brcobranca::Bancos` — registro de bancos/CNAB/PIX |
| [Roadmap](docs/TODO_INTEGRACAO.md) | Status das entregas e versões |
| [CHANGELOG](CHANGELOG.md) | Histórico de versões |
| [CONTRIBUTING](CONTRIBUTING.md) | Guia de contribuição |

### Fixtures visuais

- `spec/fixtures/generated/pdf/` — 42 PDFs (todos os bancos, com/sem PIX, RGhost e Prawn)
- `spec/fixtures/generated/remessa/` — 13 arquivos CNAB 240/400

Para regenerar: `bin/generate_fixtures`

---

## Configuração

```ruby
# config/initializers/brcobranca.rb

Brcobranca.setup do |config|
  config.gerador = :rghost        # :rghost, :rghost_carne, :rghost_bolepix
  config.formato = :pdf           # :pdf, :jpg, :png, :ps
  config.resolucao = 150          # DPI
end
```

---

## Contribuindo

Contribuições são bem-vindas! Veja [CONTRIBUTING.md](CONTRIBUTING.md) para detalhes.

```bash
git clone https://github.com/Maxwbh/brcobranca.git
bundle install
bundle exec rspec
```

---

## Licença

BSD-3-Clause. Veja [LICENSE](LICENSE).

---

## Autor

Criado por [Kivanio Barbosa](https://github.com/kivanio).
Fork mantido por [Maxwell da Silva Oliveira](https://github.com/Maxwbh) — M&S do Brasil LTDA.

- GitHub: [@maxwbh](https://github.com/maxwbh)
- LinkedIn: [/maxwbh](https://linkedin.com/in/maxwbh)
- Email: maxwbh@gmail.com

---

<a name="english"></a>

# English

## About

**BRCobranca** is a Ruby library for generating bank payment slips (boletos) and CNAB remittance/return files for Brazilian banks.

### Features

- **18 Brazilian banks** supported (including C6 Bank)
- **PDF generation** with barcode (RGhost or Prawn)
- **CNAB files** — remittance and return (240/400/444 bytes)
- **PIX support** — hybrid billing in 7 banks, with `chave_pix`, `tipo_chave_pix`, `txid` fields
- **Bank registry** (`Brcobranca::Bancos`) — programmatic discovery of supported banks/CNAB/PIX
- **Serialization API** (`to_hash`/`as_json`/`to_json`) for REST integration
- **Ruby >= 3.0** — tested on 3.0, 3.1, 3.2, 3.3, 3.4

## Installation

```ruby
gem 'brcobranca'
```

**Requirement:** GhostScript > 9.0 (or use the Prawn template for GhostScript-free PDF generation)

## Quick Start

```ruby
require 'brcobranca'

boleto = Brcobranca::Boleto::Bradesco.new(
  agencia: '0548',
  conta_corrente: '0001448',
  carteira: '06',
  nosso_numero: '00000004042',
  valor: 135.00,
  data_vencimento: Date.today + 30,
  cedente: 'My Company LTDA',
  sacado: 'Customer Name',
  sacado_documento: '12345678901'
)

File.open('boleto.pdf', 'wb') { |f| f.write(boleto.to(:pdf)) }

# PIX data (when available)
boleto.dados_pix #=> { chave_pix: '...', tipo_chave_pix: '...', ... }

# JSON for REST APIs
boleto.to_json
```

## Documentation

- [Quick Start Guide](docs/guia_rapido.md) (Portuguese)
- [Fields Reference](docs/campos_por_banco.md) (Portuguese)
- [API Reference](docs/api_referencia.md) (Portuguese)
- [CHANGELOG](CHANGELOG.md)

## License

BSD-3-Clause. See [LICENSE](LICENSE) for details.

---

<p align="center">
  <sub>Made with ❤️ in Brazil</sub>
</p>
