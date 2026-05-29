<h1 align="center">BRCobranca</h1>

<p align="center">
  <strong>Biblioteca Ruby para boletos bancários, CNAB e PIX</strong><br>
  <sub>18 bancos · CNAB 240/400/444 · PIX em 7 bancos · PDF via RGhost ou Prawn</sub>
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
  <img src="https://img.shields.io/badge/ruby-%3E%3D%203.0-red" alt="Ruby">
  <a href="https://opensource.org/licenses/BSD-3-Clause">
    <img src="https://img.shields.io/badge/license-BSD--3--Clause-blue.svg" alt="License">
  </a>
</p>

<p align="center">
  <a href="#uso-rápido">Uso Rápido</a> ·
  <a href="#bancos-suportados">Bancos</a> ·
  <a href="#pix">PIX</a> ·
  <a href="#documentação">Docs</a> ·
  <a href="https://github.com/Maxwbh/brcobranca/wiki">Wiki</a> ·
  <a href="#english">English</a>
</p>

---

## Por que BRCobranca?

- **18 bancos** em uma única gem — boleto, remessa e retorno
- **PIX nativo** — campos `chave_pix`/`tipo_chave_pix`/`txid` no boleto + registro PIX na remessa CNAB
- **Sem GhostScript?** Sem problema — template **Prawn** gera PDF puro-Ruby
- **API JSON** — `to_hash`, `as_json`, `to_json` em boleto, remessa e retorno
- **Registro de bancos** — `Brcobranca::Bancos` descobre bancos/CNAB/PIX programaticamente
- **1.100+ testes** · Ruby 3.0 a 3.4 · CI em 5 versões

---

## Instalação

```ruby
# Gemfile — apontando para o fork com PIX e melhorias
gem 'brcobranca', github: 'Maxwbh/brcobranca'
```

```bash
bundle install
```

GhostScript necessário apenas para o template RGhost:

```bash
sudo apt-get install ghostscript   # Ubuntu/Debian
brew install ghostscript            # macOS
```

> Não quer GhostScript? Use o [template Prawn](#template-prawn-sem-ghostscript).

---

## Uso Rápido

### Boleto em PDF

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

File.write('boleto.pdf', boleto.to(:pdf))
```

### Remessa CNAB

```ruby
remessa = Brcobranca::Remessa::Cnab400::Bradesco.new(
  carteira: '06', agencia: '0548', conta_corrente: '0001448',
  digito_conta: '6', empresa_mae: 'Minha Empresa LTDA',
  documento_cedente: '12345678000190',
  codigo_empresa: '00000000000000123456',
  sequencial_remessa: '0000001',
  pagamentos: [
    Brcobranca::Remessa::Pagamento.new(
      valor: 135.00, data_vencimento: Date.today + 30,
      nosso_numero: '00000004042', documento_sacado: '12345678901',
      nome_sacado: 'Cliente da Silva', endereco_sacado: 'Rua das Flores, 123',
      cep_sacado: '01234567', cidade_sacado: 'Sao Paulo', uf_sacado: 'SP'
    )
  ]
)

File.write('remessa.rem', remessa.gera_arquivo)
```

### Retorno CNAB

```ruby
Brcobranca::Retorno::Cnab400::Bradesco.load_lines(File.open('retorno.ret')).each do |r|
  puts "#{r.nosso_numero} — R$ #{r.valor_recebido} — #{r.codigo_ocorrencia}"
end
```

### JSON para API REST

```ruby
boleto.to_hash    # Hash com todos os dados
boleto.as_json    # Hash com chaves string
boleto.to_json    # String JSON

boleto.dados_pix  # { chave_pix: '...', txid: '...', qrcode_disponivel: true }
```

---

## Bancos Suportados

| Cód | Banco | Boleto | CNAB 240 | CNAB 400 | PIX |
|:---:|-------|:------:|:--------:|:--------:|:---:|
| 001 | Banco do Brasil | ✅ | ✅ | ✅ | ✅ |
| 004 | Banco do Nordeste | ✅ | — | ✅ | — |
| 021 | Banestes | ✅ | — | — | — |
| 033 | Santander | ✅ | ✅ | ✅ | ✅ |
| 041 | Banrisul | ✅ | — | ✅ | — |
| 070 | Banco de Brasilia | ✅ | — | ✅ | — |
| 085 | AILOS | ✅ | ✅ | — | — |
| 097 | CREDISIS | ✅ | — | ✅ | — |
| 104 | Caixa | ✅ | ✅ | — | ✅ |
| 136 | Unicred | ✅ | ✅ | ✅ | — |
| 237 | Bradesco | ✅ | — | ✅ | ✅ |
| 336 | C6 Bank | ✅ | — | ✅ | ✅ |
| 341 | Itau | ✅ | — | ✅ (+444) | ✅ |
| 399 | HSBC | ✅ | — | — | — |
| 422 | Safra | ✅ | — | — | — |
| 745 | Citibank | ✅ | — | ✅ | — |
| 748 | Sicredi | ✅ | ✅ | — | — |
| 756 | Sicoob | ✅ | ✅ | ✅ | ✅ |

```ruby
# Consulta programatica
Brcobranca::Bancos.todos              # 18 bancos
Brcobranca::Bancos.find('756')        # busca por codigo
Brcobranca::Bancos.com_pix            # 7 bancos com PIX
Brcobranca::Bancos.to_json            # JSON para API
```

> Detalhes de cada banco: [Campos por Banco](docs/campos_por_banco.md) · [Wiki: Bancos Suportados](https://github.com/Maxwbh/brcobranca/wiki/Bancos-Suportados)

---

## PIX

### Campos PIX no boleto

```ruby
boleto = Brcobranca::Boleto::Sicoob.new(
  # ... campos do banco
  chave_pix: '12345678000100',
  tipo_chave_pix: 'cnpj',            # cpf, cnpj, email, telefone, chave_aleatoria
  txid: 'TXID20260528001',
  emv: '00020126580014br.gov.bcb.pix...'  # para QR Code no PDF
)

boleto.dados_pix
#=> { chave_pix: '12345678000100', tipo_chave_pix: 'cnpj',
#     txid: 'TXID20260528001', emv: '0002...', qrcode_disponivel: true }
```

### Boleto PDF com QR Code

```ruby
Brcobranca.setup { |c| c.gerador = :rghost_bolepix }
File.write('boleto_pix.pdf', boleto.to(:pdf))
```

### Remessa CNAB com registro PIX

```ruby
pagamento = Brcobranca::Remessa::PagamentoPix.new(
  # campos padrao + PIX:
  codigo_chave_dict: '12345678000100', tipo_chave_dict: 'cnpj',
  txid: 'TXID20260528001', valor_maximo_pix: 100.00, valor_minimo_pix: 100.00,
  # ... demais campos do pagamento
)

# CNAB 400: Bradesco, Itau, Santander, C6 (registro tipo 8)
Brcobranca::Remessa::Cnab400::BradescoPix.new(pagamentos: [pagamento], ...)

# CNAB 240: Sicoob, Caixa, BB (segmento Y-03)
Brcobranca::Remessa::Cnab240::SicoobPix.new(pagamentos: [pagamento], ...)
```

> Guia completo: [Wiki: Configuracao PIX](https://github.com/Maxwbh/brcobranca/wiki/Configuração-PIX)

---

## Template Prawn (sem GhostScript)

Alternativa puro-Ruby para gerar PDF sem dependencia de sistema:

```ruby
# Gemfile
gem 'prawn', '~> 2.4'
gem 'prawn-table', '~> 0.2'
gem 'barby', '~> 0.6'
gem 'rqrcode', '~> 2.0'
gem 'chunky_png', '~> 1.4'
```

```ruby
require 'brcobranca/boleto/template/prawn_bolepix'

boleto = Brcobranca::Boleto::Sicoob.new(...)
boleto.extend(Brcobranca::Boleto::Template::PrawnBolepix)
File.write('boleto.pdf', boleto.to(:pdf))
```

> Comparacao RGhost vs Prawn: [Wiki: Migracao](https://github.com/Maxwbh/brcobranca/wiki/Migração-RGhost-para-Prawn)

---

## Documentacao

| Recurso | Link |
|---------|------|
| **Wiki** (guias, FAQ, integracao) | [github.com/Maxwbh/brcobranca/wiki](https://github.com/Maxwbh/brcobranca/wiki) |
| Guia Rapido | [docs/guia_rapido.md](docs/guia_rapido.md) |
| Campos por Banco | [docs/campos_por_banco.md](docs/campos_por_banco.md) |
| API de Serializacao | [docs/api_referencia.md](docs/api_referencia.md) |
| API de Bancos | [docs/api_referencia.md#api-de-bancos](docs/api_referencia.md#api-de-bancos) |
| Roadmap | [docs/TODO_INTEGRACAO.md](docs/TODO_INTEGRACAO.md) |
| CHANGELOG | [CHANGELOG.md](CHANGELOG.md) |
| Contribuir | [CONTRIBUTING.md](CONTRIBUTING.md) |

### Wiki — paginas disponiveis

- [Primeiros Passos](https://github.com/Maxwbh/brcobranca/wiki/Primeiros-Passos)
- [Configuracao PIX](https://github.com/Maxwbh/brcobranca/wiki/Configuração-PIX)
- [Bancos Suportados](https://github.com/Maxwbh/brcobranca/wiki/Bancos-Suportados)
- [FAQ e Troubleshooting](https://github.com/Maxwbh/brcobranca/wiki/FAQ-e-Troubleshooting)
- [Migracao RGhost para Prawn](https://github.com/Maxwbh/brcobranca/wiki/Migração-RGhost-para-Prawn)
- [Integracao com Rails](https://github.com/Maxwbh/brcobranca/wiki/Integração-com-Rails)
- [Integracao com Gestao de Contratos](https://github.com/Maxwbh/brcobranca/wiki/Integração-com-Gestão-de-Contratos)

---

## Configuracao

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

```bash
git clone https://github.com/Maxwbh/brcobranca.git
bundle install
bundle exec rspec   # 1.100+ testes
```

Veja [CONTRIBUTING.md](CONTRIBUTING.md) para detalhes.

---

## Licenca

BSD-3-Clause — [LICENSE](LICENSE)

---

## Autor

Criado por [Kivanio Barbosa](https://github.com/kivanio).
Fork mantido por **[Maxwell da Silva Oliveira](https://github.com/Maxwbh)** — M&S do Brasil LTDA.

---

<a name="english"></a>

## English

**BRCobranca** is a Ruby library for Brazilian bank payment slips (boletos), CNAB remittance/return files, and PIX hybrid billing.

**Key features:** 18 banks · CNAB 240/400/444 · PIX in 7 banks · PDF via RGhost or Prawn (no GhostScript needed) · JSON serialization API · Bank registry for programmatic discovery · Ruby 3.0–3.4

### Quick Start

```ruby
# Gemfile
gem 'brcobranca', github: 'Maxwbh/brcobranca'
```

```ruby
require 'brcobranca'

boleto = Brcobranca::Boleto::Bradesco.new(
  agencia: '0548', conta_corrente: '0001448', carteira: '06',
  nosso_numero: '00000004042', valor: 135.00,
  data_vencimento: Date.today + 30,
  cedente: 'My Company LTDA', sacado: 'Customer Name',
  sacado_documento: '12345678901',
  chave_pix: '12345678000100', tipo_chave_pix: 'cnpj'
)

File.write('boleto.pdf', boleto.to(:pdf))
boleto.to_json    # JSON for REST APIs
boleto.dados_pix  # PIX data hash
```

### Documentation

- [Wiki](https://github.com/Maxwbh/brcobranca/wiki) (Portuguese)
- [API Reference](docs/api_referencia.md)
- [CHANGELOG](CHANGELOG.md)

**License:** BSD-3-Clause — [LICENSE](LICENSE)

---

<p align="center">
  <sub>Made with ❤️ in Brazil</sub>
</p>