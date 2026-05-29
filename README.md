<h1 align="center">BRCobranca</h1>

<p align="center">
  <strong>Biblioteca Ruby para geração de boletos bancários e arquivos CNAB</strong>
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
  <a href="https://github.com/Maxwbh/brcobranca/releases">
    <img src="https://img.shields.io/github/v/tag/Maxwbh/brcobranca?label=version&sort=semver" alt="Version">
  </a>
  <a href="https://github.com/Maxwbh/brcobranca/releases">
    <img src="https://img.shields.io/github/release-date/Maxwbh/brcobranca?label=release" alt="Release Date">
  </a>
  <a href="https://github.com/Maxwbh/brcobranca/stargazers">
    <img src="https://img.shields.io/github/stars/Maxwbh/brcobranca?style=social" alt="Stars">
  </a>
  <a href="https://opensource.org/licenses/BSD-3-Clause">
    <img src="https://img.shields.io/badge/License-BSD%203--Clause-blue.svg" alt="License">
  </a>
</p>

---

## Sobre

**BRCobranca** é uma biblioteca Ruby moderna e completa para emissão de **boletos bancários** e arquivos **CNAB** (240, 400 e 444) para os principais bancos brasileiros.

### Principais Recursos

- **18 bancos** suportados (incluindo **C6 Bank**)
- Geração de boletos em **PDF** com código de barras
- Suporte completo a **CNAB Remessa e Retorno**
- **PIX Cobrança** em **7 bancos** (com campos estruturados)
- Dois motores de PDF: **RGhost** (padrão) e **Prawn** (recomendado - puro Ruby)
- API de serialização (`to_hash`, `to_json`, `as_json`)
- Registro central de bancos (`Brcobranca::Bancos`)
- Totalmente testado em Ruby 3.0+

---

## Instalação

```ruby
# Gemfile
gem 'brcobranca'
```

```bash
bundle install
```

**Recomendado:** Use o template **Prawn** (sem GhostScript):

```ruby
Brcobranca.setup do |config|
  config.gerador = :prawn
end
```

---

## Uso Rápido

```ruby
require 'brcobranca'

boleto = Brcobranca::Boleto::Bradesco.new(
  agencia: '0548',
  conta_corrente: '0001448',
  carteira: '06',
  nosso_numero: '00000004042',
  valor: 135.00,
  documento_sacado: '12345678901',
  nome_sacado: 'João da Silva',
  endereco_sacado: 'Rua das Flores, 123',
  cidade_sacado: 'São Paulo',
  uf_sacado: 'SP',
  cep_sacado: '01234567'
)

File.open('boleto.pdf', 'wb') { |f| f.write(boleto.to(:pdf)) }
```

**Com PIX:**

```ruby
boleto.chave_pix = 'maxwbh@gmail.com'
boleto.tipo_chave_pix = 'email'
boleto.txid = '123456789ABCDEF'
```

---

## Bancos Suportados

Veja a tabela completa de bancos, carteiras e suporte a PIX na seção **[Bancos Suportados](#bancos-suportados)**.

---

## Por que escolher BRCobranca?

- Mais bancos suportados que a maioria das alternativas
- Suporte ativo a PIX Cobrança
- Documentação excelente em português
- Código limpo e fácil de estender
- Testes com fixtures visuais

---

## Documentação

- [Guia Rápido](docs/guia_rapido.md)
- [Campos por Banco](docs/campos_por_banco.md)
- [API Completa](docs/api_referencia.md)
- [Exemplos por Banco](README.md#exemplos-por-banco)

---

## Contribuindo

Contribuições são bem-vindas! Veja o arquivo [CONTRIBUTING.md](CONTRIBUTING.md).

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