# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/spec/v2.0.0.html).

## [Unreleased]

<!-- Adicione novas mudanças aqui -->

## [12.2.0] - 2025-12-31

### Added
- **API para retorno de dados do boleto**: Novos métodos para facilitar integração
  - `to_hash`: Retorna todos os dados do boleto como Hash
  - `as_json`: Retorna dados prontos para serialização JSON
  - `to_json`: Retorna string JSON
  - `dados_entrada`: Campos informados pelo usuário
  - `dados_calculados`: Campos gerados automaticamente (código de barras, linha digitável, etc)
  - `banco_nome`: Nome do banco para exibição
  - `dados_pix`: Dados para pagamento via PIX (EMV, QRCode)

### Example
```ruby
boleto = Brcobranca::Boleto::Sicoob.new(params)

# Todos os dados
boleto.to_hash
#=> { convenio: '123', ..., codigo_barras: '756...', linha_digitavel: '75691...', ... }

# Apenas campos calculados
boleto.to_hash(somente_calculados: true)
#=> { banco: '756', codigo_barras: '...', linha_digitavel: '...', nosso_numero_boleto: '...' }

# JSON para APIs
boleto.to_json
#=> '{"convenio":"123","codigo_barras":"756...",...}'
```

### Contributors
- Maxwell Oliveira (@maxwbh) - M&S do Brasil LTDA

## [12.1.0] - 2025-12-31

### Added
- **FormatacaoCampos**: Novo módulo para formatação padronizada de campos bancários
  - Método `formata_campo` para gerar setters com padding automático
  - Método `formata_campos` para definir múltiplos campos de uma vez
- **with_options**: Implementação completa do método para validações condicionais
  - Classe `OptionsProxy` para aplicar opções comuns a múltiplas validações
  - Similar ao padrão do ActiveModel
- **Documentação de campos por banco** (`docs/campos_por_banco.md`)
  - Referência completa de campos obrigatórios/opcionais por banco
  - Exemplos de código para cada banco suportado
- **Guia de início rápido** (`docs/guia_rapido.md`)
  - Instalação e configuração
  - Geração de boletos e arquivos CNAB
  - Integração com Rails
  - Troubleshooting

### Changed
- **RGhost**: Dependência atualizada de `= 0.9.8` para `>= 0.9.8`
  - Permite uso do RGhost 0.9.9 (lançado em Mar/2024)
  - Resolve issue #269 do repositório original
- **Retorno::Base**: Atributos reorganizados em grupos lógicos com documentação
- **Validations**: Método `collect_validations` extraído para reduzir duplicação

### Improved
- **SimpleCov**: Configuração aprimorada com cobertura mínima de 80%
  - Grupos por módulo (Boletos, Remessa, Retorno, Utilitários)
  - Filtros para `/spec/` e `/vendor/`
- **Docker**: Adicionado Dockerfile para containerização
  - Ruby 3.3 com GhostScript
  - Otimizado para CI/CD
- **Render.com**: Adicionada configuração para deploy gratuito
  - Blueprint em `render.yaml`
  - Configuração de worker para testes

### Contributors
- Maxwell Oliveira (@maxwbh) - M&S do Brasil LTDA

## [12.0.1] - 2025-11-28

### Added
- Reestruturação completa da documentação
- Nova estrutura de diretórios `docs/` organizada por categoria
- Índice centralizado de documentação em `docs/README.md`
- Diretório `assets/` para logos e templates (anteriormente em `lib/brcobranca/arquivos/`)
- Diretório `lib/brcobranca/util/` consolidando todos os módulos utilitários
- Comentários explicativos em classes base legadas do retorno

### Changed
- Documentação reorganizada em `docs/getting-started/`, `docs/banks/`, `docs/guides/`, `docs/deployment/`
- Módulos utilitários movidos para `lib/brcobranca/util/` (calculo, formatacao, currency, validations, etc.)
- Assets (logos e templates) movidos de `lib/brcobranca/arquivos/` para `assets/`
- Links de documentação atualizados no README.md

### Improved
- Estrutura de projeto mais moderna e organizada
- Melhor separação entre código fonte e recursos estáticos
- Documentação mais fácil de navegar e manter

## [12.0.0] - 2024-11-25

### Added
- Documentação completa de campos para todos os 17 bancos suportados
- Guia completo do Banco do Brasil
- Guia de troubleshooting da API do Sicoob (banco 756)
- Documentação de política de campos opcionais
- Esclarecimentos sobre uso do campo `documento_numero`

### Fixed
- Sicoob: Define `aceite` padrão como 'N' conforme especificação bancária

## [11.x.x] - Histórico Anterior

### Added
- CNAB444 para Itaú (#267)
- Suporte a PIX para Santander em remessa/retorno (#268)
- Renderização de valores de descontos/abatimentos nos campos corretos do boleto (#264)
- Logo do recibo do beneficiário (#255)

### Fixed
- Itaú: Tamanho fixo das instruções na remessa (#262)
- Santander Remessa 240: Código e dias de baixa/devolução (#261)
- Itaú: Códigos de prazo de instrução de protesto: 09, 34 e 35 (#259)
- Santander Remessa 240: Dígito da agência (#257)

### Changed
- Atualização para Ruby 3.4.3
- Remoção do TruffleRuby do CI
- Bump de versão no Gemfile.lock

## Bancos Suportados

### Boletos
- 001 - Banco do Brasil
- 004 - Banco do Nordeste
- 021 - Banestes
- 033 - Santander
- 041 - Banrisul
- 070 - Banco de Brasília
- 085 - AILOS
- 097 - CREDISIS
- 104 - Caixa
- 136 - Unicred
- 237 - Bradesco
- 341 - Itaú
- 399 - HSBC
- 745 - Citibank
- 748 - Sicredi
- 756 - Sicoob

### Remessa/Retorno
- CNAB 240: 9 bancos
- CNAB 400: 13 bancos
- CNAB 444: Itaú
- CBR643: Banco do Brasil

## Links

- [Versões Estáveis](https://github.com/kivanio/brcobranca/releases)
- [Documentação Completa](docs/README.md)
- [Guia de Início Rápido](docs/getting-started/quick-start.md)
- [Campos por Banco](docs/banks/fields-reference.md)

---

**Formato de Versionamento:** MAJOR.MINOR.PATCH
- **MAJOR**: Mudanças incompatíveis com versões anteriores
- **MINOR**: Novas funcionalidades compatíveis com versões anteriores
- **PATCH**: Correções de bugs compatíveis com versões anteriores

**Mantido por:** [Kivanio Barbosa](https://github.com/kivanio/brcobranca)
**Contribuidores:** Comunidade BRCobrança

---

### Contribuidor v12.1.0

**Maxwell Oliveira** - M&S do Brasil LTDA
- Email: maxwbh@gmail.com
- LinkedIn: [/maxwbh](https://linkedin.com/in/maxwbh)
- Website: [www.msbrasil.inf.br](https://www.msbrasil.inf.br)
