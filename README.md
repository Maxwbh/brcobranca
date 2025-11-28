# BRCobranca

> Gem Ruby para emissão de boletos bancários e geração de arquivos de remessa/retorno CNAB para bancos brasileiros.

[![Ruby](https://github.com/kivanio/brcobranca/actions/workflows/main.yml/badge.svg)](https://github.com/kivanio/brcobranca/actions/workflows/main.yml)
[![Gem Version](http://img.shields.io/gem/v/brcobranca.svg)][gem]
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fkivanio%2Fbrcobranca.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fkivanio%2Fbrcobranca?ref=badge_shield)

[gem]: https://rubygems.org/gems/brcobranca

## 📋 Índice

- [Características](#-características)
- [Instalação](#-instalação)
- [Início Rápido](#-início-rápido)
- [Bancos Suportados](#-bancos-suportados)
- [Documentação](#-documentação)
- [Exemplos](#-exemplos)
- [Contribuindo](#-contribuindo)
- [Licença](#-licença)

## ✨ Características

- ✅ **17 bancos brasileiros** suportados com validações específicas
- 📄 **Geração de boletos** em PDF com código de barras
- 💾 **Arquivos CNAB** de remessa (240/400/444) e retorno
- 🔒 **Validações robustas** de campos por banco
- 🎨 **Layouts customizáveis** para boletos
- 🧪 **Amplamente testado** com RSpec
- 📦 **Pronto para produção** (usado por milhares de empresas)
- 🌐 **Ruby 2.7+** até 3.3

## 📥 Instalação

Adicione ao seu `Gemfile`:

```ruby
gem 'brcobranca'
```

E execute:

```bash
bundle install
```

Ou instale diretamente:

```bash
gem install brcobranca
```

**Requisito adicional:** GhostScript > 9.0 (para geração de PDFs)

```bash
# Ubuntu/Debian
sudo apt-get install ghostscript

# macOS
brew install ghostscript
```

📖 **[Guia de Instalação Completo](docs/installation.md)**

## 🚀 Início Rápido

```ruby
require 'brcobranca'

# Criar um boleto
boleto = Brcobranca::Boleto::BancoDoBrasil.new(
  cedente: "Minha Empresa",
  documento_cedente: "12345678000199",
  sacado: "Cliente",
  sacado_documento: "12345678900",
  agencia: "1234",
  conta_corrente: "123456",
  convenio: "1234567",
  numero_documento: "123456",
  valor: 100.00,
  data_vencimento: Date.today + 30,
  data_documento: Date.today
)

# Gerar PDF
File.open('boleto.pdf', 'wb') { |f| f.write(boleto.to(:pdf)) }

# Obter linha digitável
puts boleto.linha_digitavel
#=> "00190.00009 01234.567891 12345.678901 2 34567890123456"
```

📖 **[Guia de Início Rápido Completo](docs/getting-started/quick-start.md)**

## 🏦 Bancos Suportados

### Boletos (17 bancos)

### Bancos Disponíveis

| Bancos                  | Carteiras                                                                                         | Documentações                                                                                                                                                                                               |
| ----------------------- | ------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 001 - Banco do Brasil   | Todas as carteiras presentes na documentação                                                      | [pdf](http://www.bb.com.br/docs/pub/emp/empl/dwn/Doc5175Bloqueto.pdf)                                                                                                                                       |
| 004 - Banco do Nordeste | Todas as carteiras presentes na documentação - [Marcelo J. Both](https://github.com/marceloboth)  |                                                                                                                                                                                                             |
| 021 - Banestes          | Todas as carteiras presentes na documentação                                                      |                                                                                                                                                                                                             |
| 033 - Santander         | Todas as carteiras presentes na documentação - [Ronaldo Araujo](https://github.com/ronaldoaraujo) | [pdf](http://177.69.143.161:81/Treinamento/SisMoura/Documentação%20Boleto%20Remessa/Documentacao_SANTANDER/Layout%20de%20Cobrança%20-%20Código%20de%20Barras%20Santander%20Setembro%202012%20v%202%203.pdf) |
| 041 - Banrisul          | Todas as carteiras presentes na documentação                                                      |                                                                                                                                                                                                             |
| 070 - Banco de Brasília | Todas as carteiras presentes na documentação - [Marcelo J. Both](https://github.com/marceloboth)  |                                                                                                                                                                                                             |
| 104 - Caixa             | Todas as carteiras presentes na documentação - [Túlio Ornelas](https://github.com/tulios)         | [pdf](http://downloads.caixa.gov.br/_arquivos/cobranca_caixa_sigcb/manuais/CODIGO_BARRAS_SIGCB.PDF)                                                                                                         |
| 237 - Bradesco          | Todas as carteiras presentes na documentação                                                      | [pdf](http://www.bradesco.com.br/portal/PDF/pessoajuridica/solucoes-integradas/outros/layout-de-arquivo/cobranca/4008-524-0121-08-layout-cobranca-versao-portugues.pdf)                                     |
| 341 - Itaú              | Todas as carteiras presentes na documentação                                                      | [CNAB240](http://download.itau.com.br/bankline/cobranca_cnab240.pdf), [CNAB400](http://download.itau.com.br/bankline/layout_cobranca_400bytes_cnab_itau_mensagem.pdf)                                       |
| 399 - HSBC              | CNR, CSB - [Rafael DL](https://github.com/rafaeldl)                                               |                                                                                                                                                                                                             |
| 748 - Sicredi           | C (03)                                                                                            |                                                                                                                                                                                                             |
| 756 - Sicoob            | Todas as carteiras presentes na documentação                                                      |                                                                                                                                                                                                             |
| 085 - AILOS             | Todas as carteiras presentes na documentação - [Marcelo J. Both](https://github.com/marceloboth)  |                                                                                                                                                                                                             |
| 136 - Unicred           | 21 - [Magno Costa](https://github.com/mbcosta)                                                    |                                                                                                                                                                                                             |
| 097 - CREDISIS          | Todas as carteiras presentes na documentação - [Marcelo J. Both](https://github.com/marceloboth)  |                                                                                                                                                                                                             |
| 745 - Citibank          | 3                                                                                                 |                                                                                                                                                                                                             |

### Retornos e Remessas

| Banco             | Retorno         | Remessa               |
| ----------------- | --------------- | --------------------- |
| Banco do Brasil   | 400 (ou CBR643) | 400 (ou CBR641) e 240 |
| Banco do Nordeste | 400             | 400                   |
| Banco de Brasília | 400             | 400                   |
| Banestes          | Não             | Não                   |
| Banrisul          | 400             | 400                   |
| Bradesco          | 400             | 400                   |
| Caixa             | 240             | 240                   |
| Citibank          | Não             | 400                   |
| HSBC              | Não             | Não                   |
| Itaú              | 400             | 400 e 444             |
| Santander         | 400 e 240       | 400 e 240             |
| Sicoob            | 240             | 400 e 240             |
| Sicredi           | 240             | 240                   |
| UNICRED           | 400             | 400 e 240             |
| AILOS             | 240             | 240                   |
| CREDISIS          | 400             | 400                   |

- Banco do Brasil (CNAB240) [Isabella](https://github.com/isabellaSantos) da [Zaez](http://www.zaez.net)
- Caixa Economica Federal (CNAB240) [Isabella](https://github.com/isabellaSantos) da [Zaez](http://www.zaez.net)
- Bradesco (CNAB400) [Isabella](https://github.com/isabellaSantos) da [Zaez](http://www.zaez.net)
- Itaú (CNAB400) [Isabella](https://github.com/isabellaSantos) da [Zaez](http://www.zaez.net)
- Itaú (CNAB444) [Junior Tada](https://github.com/juniortada) 
- Citibank (CNAB400)
- Santander (CNAB400)
- Santander (CNAB240)

### Documentação e Recursos

#### Documentação Local
- **[Guia de Início Rápido](docs/getting-started/quick-start.md)** - Como usar a gem passo a passo
- **[Campos por Banco](docs/banks/fields-reference.md)** - Referência completa de campos para cada banco
- **[Deploy no Render](docs/deployment/render-guide.md)** - Otimização e deploy para produção
- **[📚 Índice Completo da Documentação](docs/README.md)** - Navegação completa de todos os recursos

#### Documentação Online
- **[Wiki Oficial](https://github.com/kivanio/brcobranca/wiki)** - Documentação colaborativa
- **[RubyDoc Estável](http://rubydoc.info/gems/brcobranca)** - Documentação da versão estável
- **[RubyDoc Desenvolvimento](http://rubydoc.info/github/kivanio/brcobranca/master/frames)** - Documentação da versão de desenvolvimento

### Apoio

- [Kobana](https://www.kobana.com.br)

### Licença

- BSD


## License
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fkivanio%2Fbrcobranca.svg?type=large)](https://app.fossa.com/projects/git%2Bgithub.com%2Fkivanio%2Fbrcobranca?ref=badge_large)
