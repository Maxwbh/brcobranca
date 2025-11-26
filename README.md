Gem para emissão de boletos de cobrança para bancos brasileiros.

[![Ruby](https://github.com/kivanio/brcobranca/actions/workflows/main.yml/badge.svg)](https://github.com/kivanio/brcobranca/actions/workflows/main.yml)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fkivanio%2Fbrcobranca.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fkivanio%2Fbrcobranca?ref=badge_shield)

[![Gem Version](http://img.shields.io/gem/v/brcobranca.svg)][gem]

[gem]: https://rubygems.org/gems/brcobranca

## Documentação Completa

- 📖 **[Guia de Início Rápido](docs/getting-started/quick-start.md)** - Comece a usar a gem rapidamente
- 📋 **[Campos por Banco](docs/banks/fields-reference.md)** - Documentação detalhada de campos obrigatórios, opcionais e validações para cada banco
- 🚀 **[Deploy no Render](docs/deployment/render-guide.md)** - Guia completo para deploy otimizado no Render (plano free)

### Exemplos e Documentação

- 📖 **[Guia de Início Rápido](docs/getting-started/quick-start.md)** - Tutorial completo para começar
- 📋 **[Documentação de Campos](docs/banks/fields-reference.md)** - Campos obrigatórios e opcionais por banco
- 🚀 **[Deploy no Render](docs/deployment/render-guide.md)** - Guia de deploy otimizado

#### Aplicações de Exemplo

- https://brcobranca.herokuapp.com
- http://github.com/kivanio/brcobranca_exemplo
- https://github.com/thiagoc7/brcobranca_app

### API Server

Criado pelo pessoal da [Akretion](http://www.akretion.com) muito TOP \o/

[API server for brcobranca](https://github.com/akretion/boleto_cnab_api)

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
