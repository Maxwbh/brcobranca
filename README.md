<p align="center">
  <img src="assets/logos/brcobranca-logo.png" alt="BRCobranca" width="400">
</p>

<h1 align="center">BRCobranca</h1>

<p align="center">
  <strong>Biblioteca Ruby para emissão de boletos bancários e arquivos CNAB</strong>
</p>

<p align="center">
  <a href="#-sobre">Sobre</a> |
  <a href="#-instalação">Instalação</a> |
  <a href="#-uso-rápido">Uso Rápido</a> |
  <a href="#-bancos-suportados">Bancos</a> |
  <a href="#-documentação">Documentação</a> |
  <a href="#english">English</a>
</p>

<p align="center">
  <a href="https://github.com/Maxwbh/brcobranca/actions/workflows/main.yml">
    <img src="https://github.com/Maxwbh/brcobranca/actions/workflows/main.yml/badge.svg" alt="CI">
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

- **18 bancos brasileiros** suportados (inclusive novo **Banco C6** — código 336)
- **Geração de boletos** em PDF com código de barras
- **Arquivos CNAB** de remessa e retorno (formatos 240, 400 e 444)
- **Validações específicas** por banco
- **Suporte a PIX** (cobrança híbrida) em **7 bancos**:
  Santander, Bradesco, Itaú, C6 (CNAB 400) + Sicoob, Caixa, Banco do Brasil (CNAB 240)
- **2 templates de renderização**:
  - **RGhost** (padrão, requer GhostScript)
  - **Prawn** (alternativa puro-Ruby, sem GhostScript)
- **Suporte à Carteira 9 do Sicoob** (nova modalidade 2024/2025)
- **Layout 810 do Sicoob** (CNAB 240 alternativo, sem cálculo automático do DV)
- **API de serialização** (to_hash/as_json/to_json) para integração REST
- **Pronto para produção** - usado por milhares de empresas

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
  documento_cedente: '12.345.678/0001-90',
  sacado: 'Cliente da Silva',
  sacado_documento: '123.456.789-01'
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
      cidade_sacado: 'São Paulo',
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
  puts "Nosso Número: #{r.nosso_numero}"
  puts "Valor: #{r.valor_recebido}"
  puts "Status: #{r.codigo_ocorrencia}"
end
```

---

## Bancos Suportados

| Código | Banco | Boleto | CNAB 240 | CNAB 400 |
|--------|-------|:------:|:--------:|:--------:|
| 001 | Banco do Brasil | ✅ | ✅ | ✅ |
| 004 | Banco do Nordeste | ✅ | - | ✅ |
| 021 | Banestes | ✅ | - | - |
| 033 | Santander | ✅ | ✅ | ✅ |
| 041 | Banrisul | ✅ | - | ✅ |
| 070 | Banco de Brasília | ✅ | - | ✅ |
| 085 | AILOS | ✅ | ✅ | - |
| 097 | CREDISIS | ✅ | - | ✅ |
| 104 | Caixa Econômica | ✅ | ✅ | - |
| 136 | Unicred | ✅ | ✅ | ✅ |
| 237 | Bradesco | ✅ | - | ✅ |
| 336 | C6 Bank | ✅ | - | ✅ |
| 341 | Itaú | ✅ | - | ✅ (+ 444) |
| 399 | HSBC | ✅ | - | - |
| 422 | Safra | ✅ | - | - |
| 745 | Citibank | ✅ | - | ✅ |
| 748 | Sicredi | ✅ | ✅ | - |
| 756 | Sicoob | ✅ | ✅ | ✅ |

### Carteiras especiais

- **Sicoob (756)**:
  - Carteiras tradicionais `1` (boleto) / `01` (remessa) — Simples Com Registro
  - Carteiras tradicionais `3` / `03` — Garantida Caucionada
  - **Nova Carteira 9** (2024/2025) — Usa Número do Contrato no código de barras em vez do Código do Cedente. Basta informar `numero_contrato` e `carteira: '9'`.
  - Versão de layout CNAB 240: `'081'` (padrão) ou `'810'` (cliente calcula o DV do nosso número)
- **C6 Bank (336)**:
  - Carteira `10` — Cobrança Simples Emissão Banco
  - Carteira `20` — Cobrança Simples Emissão Cliente

### Bancos com PIX em remessa

| Banco | Classe com PIX | Formato | Registro PIX |
|---|---|:---:|---|
| Santander (033) | `Cnab400::SantanderPix` | 400 | Registro tipo 8 |
| Bradesco (237) | `Cnab400::BradescoPix` | 400 | Registro tipo 8 |
| Itaú (341) | `Cnab400::ItauPix` | 400 | Registro tipo 8 |
| C6 Bank (336) | `Cnab400::BancoC6Pix` | 400 | Registro tipo 8 |
| Banco do Brasil (001) | `Cnab240::BancoBrasilPix` | 240 | Segmento Y-03 |
| Caixa (104) | `Cnab240::CaixaPix` | 240 | Segmento Y-03 |
| Sicoob (756) | `Cnab240::SicoobPix` | 240 | Segmento Y-03 |

O registro/segmento PIX é gerado automaticamente quando o pagamento é um
`Brcobranca::Remessa::PagamentoPix` contendo chave DICT e TXID.

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

### Sicoob — Carteira 9 (nova modalidade com número de contrato)

```ruby
boleto = Brcobranca::Boleto::Sicoob.new(
  agencia: '4327',
  convenio: '229385',
  numero_contrato: '1234567',  # fornecido pelo Sicoob
  carteira: '9',
  nosso_numero: '1',
  valor: 100.00,
  # ... demais campos
)
# codigo_barras_segunda_parte usará numero_contrato em vez de convenio
```

### Sicoob — Remessa CNAB 240 com layout 810

```ruby
remessa = Brcobranca::Remessa::Cnab240::Sicoob.new(
  versao_layout_arquivo_opcao: '810',  # cliente calcula o DV
  agencia: '1234',
  conta_corrente: '12345678',
  digito_conta: '1',
  convenio: '123456789',
  # ... demais campos
)
```

### C6 Bank — Boleto

```ruby
boleto = Brcobranca::Boleto::BancoC6.new(
  agencia: '0001',
  convenio: '000000123456',  # Código do Cedente do C6
  nosso_numero: '0000000001',
  carteira: '10',            # ou '20' para Emissão Cliente
  valor: 100.00,
  # ... demais campos
)
```

### C6 Bank — Remessa CNAB 400

```ruby
remessa = Brcobranca::Remessa::Cnab400::BancoC6.new(
  codigo_beneficiario: '000000123456',
  carteira: '10',
  empresa_mae: 'Minha Empresa LTDA',
  documento_cedente: '12345678000100',
  sequencial_remessa: '1',
  pagamentos: [pagamento]
)

# ou via factory:
Brcobranca::Remessa.criar(
  banco: :c6,         # ou '336'
  formato: :cnab400,
  codigo_beneficiario: '000000123456',
  # ... demais campos
)
```

### Remessa com PIX (Boleto Híbrido)

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
  tipo_chave_dict: 'cnpj',          # cpf, cnpj, email, telefone, chave_aleatoria
  valor_maximo_pix: 100.00,
  valor_minimo_pix: 100.00,
  txid: 'TXID20250101001'
)

# CNAB 400 com registro PIX tipo 8
remessa = Brcobranca::Remessa::Cnab400::BradescoPix.new(
  carteira: '09', agencia: '1234', conta_corrente: '12345678',
  digito_conta: '1', empresa_mae: 'Empresa LTDA',
  documento_cedente: '12345678000100', codigo_empresa: '12345',
  pagamentos: [pagamento_pix]
)

# CNAB 240 com Segmento Y-03 (Sicoob, Caixa, Banco do Brasil)
remessa = Brcobranca::Remessa::Cnab240::SicoobPix.new(
  empresa_mae: 'Empresa LTDA', agencia: '1234', conta_corrente: '12345678',
  digito_conta: '1', documento_cedente: '12345678000100',
  convenio: '123456789', modalidade_carteira: '01',
  tipo_formulario: '4', parcela: '01',
  pagamentos: [pagamento_pix]
)
```

### Boleto com QR Code PIX (Bolepix)

Informe a string EMV (BR Code) no boleto e use o template `:rghost_bolepix`:

```ruby
Brcobranca.setup { |c| c.gerador = :rghost_bolepix }

boleto = Brcobranca::Boleto::Sicoob.new(
  # ... campos padrão
  emv: '00020126580014br.gov.bcb.pix0136...'
)

File.write('boleto_pix.pdf', boleto.to(:pdf))
```

### Template Prawn (alternativa sem GhostScript)

Use o template Prawn para gerar PDFs sem depender do GhostScript:

```ruby
# Instale: gem install prawn prawn-table barby rqrcode chunky_png
require 'brcobranca/boleto/template/prawn_bolepix'

boleto = Brcobranca::Boleto::Sicoob.new(
  # ... campos padrão
  emv: '00020126580014br.gov.bcb.pix0136...'  # opcional para QR Code
)
boleto.extend(Brcobranca::Boleto::Template::PrawnBolepix)

File.write('boleto.pdf', boleto.to(:pdf))
```

O layout Prawn inclui **Recibo do Pagador** + **Ficha de Compensação** + QR Code PIX, seguindo o padrão FEBRABAN com cores e sombreados. Veja exemplos em `spec/fixtures/generated/pdf/prawn_*.pdf`.

---

## Documentação

| Documento | Descrição |
|-----------|-----------|
| [Guia Rápido](docs/guia_rapido.md) | Tutorial de início rápido |
| [Campos por Banco](docs/campos_por_banco.md) | Referência de campos obrigatórios |
| [API de Serialização](docs/api_referencia.md) | `to_hash`, `as_json`, factory methods |
| [Integração boleto_cnab_api](docs/BOLETO_CNAB_API_INTEGRATION.md) | Como consumir a gem via HTTP |
| [TODO Integração](docs/TODO_INTEGRACAO.md) | Roadmap de integração brcobranca + boleto_cnab_api |
| [CHANGELOG](CHANGELOG.md) | Histórico de versões |
| [CONTRIBUTING](CONTRIBUTING.md) | Guia de contribuição |

### Fixtures visuais

PDFs de exemplo e arquivos CNAB pré-gerados em:

- `spec/fixtures/generated/pdf/` — 41 PDFs (boletos de todos os 18 bancos, com/sem PIX, via RGhost e Prawn)
- `spec/fixtures/generated/remessa/` — 13 arquivos CNAB 240/400 de exemplo

Para regenerar: `bin/generate_fixtures`

### Recursos Online

- [Wiki Oficial](https://github.com/Maxwbh/brcobranca/wiki)
- [RubyDoc](http://rubydoc.info/gems/brcobranca)
- [RubyGems](https://rubygems.org/gems/brcobranca)

### Referências técnicas

- **Sicoob**: [Validador CNAB oficial](https://www.sicoob.com.br/web/sicoob/validador-cnab) • Manual CNAB 240 (Sicoobnet Empresarial)
- **C6 Bank**: Layout de Arquivos Cobrança Bancária Padrão CNAB 400 (v2.7 Julho 2025)
- **FEBRABAN**: padrões CNAB 240 / 400 / 444 para troca de informações bancárias

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
# Clone o repositório
git clone https://github.com/Maxwbh/brcobranca.git

# Instale dependências
bundle install

# Execute os testes
bundle exec rspec
```

---

## Licença

Distribuído sob a licença BSD-3-Clause. Veja [LICENSE](LICENSE) para mais informações.

---

## Apoio

- [Kobana](https://www.kobana.com.br)
- Comunidade Open Source

---

## Autor

Criado originalmente por [Kivanio Barbosa](https://github.com/kivanio). Fork mantido por [Maxwell da Silva Oliveira](https://github.com/Maxwbh) - M&S do Brasil LTDA.

### Contribuidor v12.1.0

**Maxwell Oliveira** - [M&S do Brasil LTDA](https://www.msbrasil.inf.br)
- GitHub: [@maxwbh](https://github.com/maxwbh)
- LinkedIn: [/maxwbh](https://linkedin.com/in/maxwbh)
- Email: maxwbh@gmail.com

---

<a name="english"></a>

# English

## About

**BRCobranca** is a complete Ruby library for generating bank payment slips (boletos) and CNAB remittance/return files for Brazilian banks.

## Installation

```ruby
gem 'brcobranca'
```

**Requirement:** GhostScript > 9.0

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
  sacado: 'Customer Name'
)

# Generate PDF
File.open('boleto.pdf', 'wb') { |f| f.write(boleto.to(:pdf)) }
```

## Features

- **18 Brazilian banks** supported
- **PDF generation** with barcode
- **CNAB files** (240/400/444 bytes)
- **Bank-specific validations**
- **PIX support** (hybrid billing)
- **Production ready**

## Documentation

- [Quick Start Guide](docs/guia_rapido.md) (Portuguese)
- [Fields Reference](docs/campos_por_banco.md) (Portuguese)
- [Official Wiki](https://github.com/Maxwbh/brcobranca/wiki)

## License

BSD-3-Clause. See [LICENSE](LICENSE) for details.

---

<p align="center">
  <sub>Made with ❤️ in Brazil</sub>
</p>
