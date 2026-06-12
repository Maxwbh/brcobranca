# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/spec/v2.0.0.html).

## [Unreleased]

### Added — Tema visual personalizável nos templates Prawn (Fase 2a)
- **Novo módulo `Brcobranca::Boleto::Template::PrawnTema`** compartilhado
  por `PrawnBolepix` e `PrawnCarne`
- **Novos atributos opcionais** em `Boleto::Base` (pensados para o fluxo
  gestao_contrato → boleto_cnab_api → gem):
  - `logo_empresa` — logo do cedente (path ou IO); no carnê substitui o
    logo do banco no canhoto, no boleto entra na faixa de marca do recibo
  - `cor_marca` — hex `RRGGBB` validado; cor de texto com contraste
    automático por luminância (preto/branco)
  - `parcela_atual` / `total_parcelas` — selo "PARCELA n/N" em destaque
  - `rodape_contato` — contato da empresa (truncado em 120 chars)
- **Fallback total**: sem atributos de tema o visual permanece idêntico;
  Ficha de Compensação intocada (linha digitável, código de barras e QR
  continuam decodificando — validado com zbarimg)
- 17 specs do `PrawnTema` (rodam no CI sem as gems Prawn)

### Added — `PrawnCarne`: carnê de pagamento via Prawn (Fase 1)
- **Novo `Brcobranca::Boleto::Template::PrawnCarne`**: carnê no modelo do
  RGhost carnê (canhoto destacável + Ficha de Compensação), sem GhostScript
  - `to_carne(:pdf)` — boleto único em página 21x9cm
  - `lote_carne(boletos)` — 3 boletos por página A4, com linhas
    pontilhadas de corte (vertical canhoto/ficha e horizontal entre boletos)
  - **QR Code PIX** na ficha quando `boleto.emv` presente (nível M,
    label "Pague com PIX")
  - Código de barras I2/5 com `xdim` calculado (não invade o QR)
  - Mesmas gems opcionais do `PrawnBolepix` (prawn, barby, rqrcode,
    chunky_png) — specs fazem skip quando indisponíveis
- **Fixture versionado**: `spec/fixtures/generated/pdf/prawn_carne_sicoob_pix.pdf`
  (3 parcelas Sicoob com PIX), validado com zbarimg — 3 QR Codes decodificam
  o EMV exato e 3 códigos de barras I2/5 decodificam os códigos corretos

### Fixed — Templates de boleto com PIX (validados visualmente)
- **RGhost Bolepix**: corrige crash (`ArgumentError`) por colisão do helper
  `pix_label(boleto)` com o `attr_accessor :pix_label` de `Boleto::Base`;
  reposiciona o QR Code (estava a 2mm da borda inferior, clipado na
  impressão) para ao lado do código de barras; corrige posição do label
  "Pague com PIX" (uso indevido de `move_more` dobrava a coordenada X)
- **Prawn Bolepix**: corrige sobreposição do código de barras no QR Code
  (`xdim` fixo transbordava a caixa e destruía a quiet zone, impedindo a
  leitura do I2/5) — agora o `xdim` é calculado para caber na largura
- **QR Code nível M** em ambos os templates, conforme manual de padrões
  PIX do BACEN (era H)
- Validação com `zbarimg`: QR decodifica o EMV exato e o I2/5 decodifica
  o código de barras correto nos dois templates

### Changed — Fixtures visuais enxutos
- Repositório passa a versionar **apenas 2 boletos de exemplo**
  (Sicoob com PIX): `sicoob_pix.pdf` (RGhost) e `prawn_sicoob_pix.pdf`
  (Prawn), ambos regenerados com os templates corrigidos e validados
- Removidos 40 PDFs de fixtures (~8MB) e o modelo de referência
  `examples/modelo_referencia_layout_sicoob.pdf` (~330KB) — o conjunto
  completo continua disponível via `bin/generate_fixtures` (ignorado
  pelo git, exceto os 2 exemplos)

### Fixed — Normalização de carteira/convênio na remessa
- **Sicoob CNAB 400**: `carteira` e `convenio` agora fazem padding
  automático (`'1'` → `'01'`, `'229385'` → `'000229385'`) — o integrador
  pode usar o mesmo valor do boleto
- **Banco do Brasil CNAB 400/240**: padding em `carteira`,
  `variacao_carteira` e `variacao`

## [12.8.2] - 2026-06-12

<!-- Adicione novas mudanças aqui -->

## [12.8.1] - 2026-05-29

<!-- Adicione novas mudanças aqui -->

## [12.8.0] - 2026-05-28

### Added — Campos PIX no Boleto (`chave_pix`, `tipo_chave_pix`, `txid`)
- **Novos atributos opcionais** em `Brcobranca::Boleto::Base`:
  - `chave_pix` — chave PIX do recebedor (CPF, CNPJ, email, telefone, aleatória)
  - `tipo_chave_pix` — tipo da chave (`'cpf'`, `'cnpj'`, `'email'`, `'telefone'`, `'chave_aleatoria'`)
  - `txid` — código de identificação da transação PIX
- **`dados_pix` expandido**: retorna `chave_pix`, `tipo_chave_pix`, `txid`,
  `emv` e `qrcode_disponivel` (true se EMV presente, false caso contrário)
- **`dados_entrada` e `to_hash`** incluem os novos campos (omitidos quando nil)
- Pensado para integração com Gestao-Contrato: mesma fonte de dados PIX
  alimenta boleto (PDF) e remessa (CNAB via `PagamentoPix`)

### Added — `Brcobranca::Bancos` (registro/API de bancos suportados)
- **Novo módulo `Brcobranca::Bancos`** (`lib/brcobranca/bancos.rb`):
  fonte única de verdade sobre capacidades de cada banco (boleto,
  CNAB 240/400/444, PIX, carteiras e notas específicas).
- **API pública** (class methods):
  - `Bancos.todos` — lista completa dos 18 bancos registrados
  - `Bancos.find("756")` — busca por código
  - `Bancos.codigos` — apenas os códigos (`["001", "004", ...]`)
  - `Bancos.com_boleto` / `com_remessa(formato=nil)` / `com_retorno(formato=nil)`
    — filtros por capacidade
  - `Bancos.com_pix` — 7 bancos com PIX na remessa
  - `Bancos.formatos_cnab` — formatos disponíveis (`["240", "400", "444"]`)
  - `Bancos.as_json` / `Bancos.to_json` — serialização pronta para APIs REST
- **Ideal para boleto_cnab_api** e integrações externas que precisam
  descobrir dinamicamente quais bancos/CNAB/PIX estão disponíveis.
- **20 specs** em `spec/brcobranca/bancos_spec.rb`.
- Autoload adicionado em `lib/brcobranca.rb`.

### Added — PIX (Boleto Híbrido) expandido para 6 bancos
- **Novo `PixMixin` para CNAB 400** (`Brcobranca::Remessa::Cnab400::PixMixin`):
  gera o registro tipo 8 (detalhe PIX) com chave DICT e TXID
- **Novo `PixMixin` para CNAB 240** (`Brcobranca::Remessa::Cnab240::PixMixin`):
  gera o Segmento Y-03 (PIX) conforme padrão FEBRABAN
- **6 novas classes de remessa com PIX** (além do `SantanderPix` existente):
  - `Brcobranca::Remessa::Cnab400::BradescoPix`
  - `Brcobranca::Remessa::Cnab400::ItauPix`
  - `Brcobranca::Remessa::Cnab400::BancoC6Pix`
  - `Brcobranca::Remessa::Cnab240::SicoobPix`
  - `Brcobranca::Remessa::Cnab240::CaixaPix`
  - `Brcobranca::Remessa::Cnab240::BancoBrasilPix`
- **Integração automática no CNAB 240**: `Base#monta_lote` agora detecta
  `PagamentoPix` e chama `monta_segmento_y` se a classe suportar

### Added — Template Prawn como alternativa ao RGhost
- **Novo `Brcobranca::Boleto::Template::PrawnBolepix`**: template de boleto
  híbrido (com PIX/QR Code) que **não depende de Ghostscript**.
  - Usa gems puro-Ruby: `prawn`, `prawn-table`, `barby`, `rqrcode`, `chunky_png`
  - Todas as gems são opcionais: se não estiverem instaladas,
    `PRAWN_AVAILABLE` é `false` e apenas mensagens informativas são exibidas
  - Baseado na PR #275 upstream (`kivanio/brcobranca`)

### Changed — Refatoração do `rghost_bolepix.rb`
- Eliminada duplicação entre `modelo_generico` e `modelo_generico_multipage`
  extraindo `desenha_pagina`, `desenha_codigo_barras`, `desenha_qrcode_pix`
- Label PIX agora é configurável via `Brcobranca.configuration.pix_label`
  ou `boleto.pix_label` (fallback para "Pague com PIX")
- Validação mínima do EMV (verifica se começa com `0002` conforme padrão
  BR Code do Banco Central)
- Novo atributo `Boleto::Base#pix_label` para customização por boleto

### Added — Script `bin/generate_fixtures`
- Gera automaticamente todos os artefatos de validação:
  - **42 PDFs** em `spec/fixtures/generated/pdf/` (boletos tradicionais,
    híbridos com PIX e via Prawn)
  - **13 arquivos CNAB** em `spec/fixtures/generated/remessa/`
    (CNAB 240 e CNAB 400 com e sem PIX)
- Documentação completa dos fixtures em `spec/fixtures/generated/README.md`

### Fixed
- **Compatibilidade com rghost 0.9.9**: a gem `rghost` na versão 0.9.9
  (lançada em 2024-03-07) removeu o `require` do arquivo que define a
  constante `RGhost::VERSION`, causando `NameError: uninitialized constant
  RGhost::VERSION` ao instanciar qualquer `RGhost::Document` (chamado em
  `lib/brcobranca/boleto/template/rghost.rb`). Adicionado fallback que
  define a constante caso não esteja presente, restaurando a geração de
  boletos em PDF/JPG/PNG/TIF. Afeta 34 specs que falhavam neste cenário.

### Added — Sicoob (756): atualizações conforme documentação mais recente
- **Suporte à Carteira 9** (nova modalidade 2024/2025): usa Número do Contrato
  fornecido pelo Sicoob em vez do Código do Cedente na composição do código de
  barras e linha digitável.
  - `Brcobranca::Boleto::Sicoob#numero_contrato` - novo atributo
  - `Brcobranca::Boleto::Sicoob#carteira_contrato?` - identificador da carteira
  - `Brcobranca::Remessa::Cnab240::Sicoob#numero_contrato` - disponível na remessa
  - `Brcobranca::Remessa::Cnab400::Sicoob#numero_contrato` - disponível na remessa
- **Suporte ao Layout 810** (CNAB 240 Sicoob): versão alternativa onde o
  Sicoob NÃO calcula o DV do nosso número (cliente já envia calculado).
  - `Brcobranca::Remessa::Cnab240::Sicoob#versao_layout_arquivo_opcao`
  - Valores aceitos: `'081'` (padrão, Sicoob calcula DV) ou `'810'` (cliente calcula)
- **Nome do banco configurável no CNAB 400**: permite definir `'SICOOB'`
  (nome atual do banco) no lugar de `'BANCOOBCED'` (compatibilidade mantida).
  - `Brcobranca::Remessa::Cnab400::Sicoob#nome_banco=` agora é configurável
  - Default continua `'BANCOOBCED'` para compatibilidade retroativa
- **Retorno CNAB 240 Sicoob**: parsing expandido incluindo
  `documento_numero` (posições 59-73) e `especie_documento` (112-114) que
  estavam comentados como "não consegui extrair".

### Added — Suporte ao Banco C6 (código 336) - CNAB 400
  - `Brcobranca::Boleto::BancoC6` - emissão de boletos com layout oficial C6Bank v2.7
  - `Brcobranca::Remessa::Cnab400::BancoC6` - geração de arquivos remessa CNAB 400
  - `Brcobranca::Retorno::Cnab400::BancoC6` - processamento de arquivos retorno CNAB 400
  - Suporte às carteiras 10 (Emissão Banco) e 20 (Emissão Cliente)
  - Cálculo do DV do nosso número via Módulo 11
  - Campo livre (25 posições): Cedente (12) + Nosso Número (10) + Carteira (2) + Indicador de Layout (1)
  - Registrado no factory `Brcobranca::Remessa.criar` com aliases: `'336'`, `'c6'`, `'banco_c6'`
  - Detecção automática no `Brcobranca::Retorno.parse` quando código de banco = 336
  - Baseado no manual oficial "Layout de Arquivos Cobrança Bancária Padrão CNAB 400 - Versão 2.7 Julho 2025"

### Contributors
- Maxwell da Silva Oliveira (@maxwbh) - M&S do Brasil LTDA - www.msbrasil.inf.br

## [12.6.1] - 2026-04-08

<!-- Adicione novas mudanças aqui -->

## [12.6.0] - 2026-01-03

<!-- Adicione novas mudanças aqui -->

## [12.5.0] - 2026-01-03

### Added
- **API de Serialização para Retorno** (Fase 4): Novos métodos para processamento de arquivos de retorno
  - `Retorno::Base#to_hash`: Retorna todos os atributos do registro como Hash
  - `Retorno::Base#as_json`: Retorna dados com chaves string
  - `Retorno::Base#to_json`: Retorna string JSON
  - `Retorno::Base#dados_titulo`: Dados principais do título
  - `Retorno::Base#dados_recebimento`: Dados de recebimento/pagamento
  - `Retorno::Base#dados_ocorrencia`: Dados da ocorrência/movimento
  - `Retorno::Base#dados_bancarios`: Dados bancários
  - `Retorno::Base#dados_pix`: Dados PIX quando disponíveis

- **Factory Method para Retorno**: `Brcobranca::Retorno.parse`
  - Processamento simplificado de arquivos de retorno
  - Auto-detecção de formato (CNAB240, CNAB400, CBR643)
  - Auto-detecção de banco pelo header do arquivo
  - `Brcobranca::Retorno.detectar_formato`: Detecta formato pelo tamanho da linha
  - `Brcobranca::Retorno.detectar_banco`: Detecta código do banco
  - `Brcobranca::Retorno.formato_valido?`: Verifica se arquivo é válido
  - `Brcobranca::Retorno.load_lines`: Carrega registros como objetos

### Example
```ruby
# Auto-detecção completa
resultado = Brcobranca::Retorno.parse('retorno.ret')
#=> {
#     formato: :cnab400,
#     banco: '237',
#     total_registros: 10,
#     registros: [{ nosso_numero: '123', valor_recebido: '10050', ... }, ...]
#   }

# Acessar registro individual
registro = Brcobranca::Retorno.load_lines('retorno.ret').first
registro.dados_titulo
#=> { nosso_numero: '123', valor_titulo: '10000', ... }

registro.dados_recebimento
#=> { valor_recebido: '10050', data_credito: '021226', ... }

# Verificar formato
Brcobranca::Retorno.formato_valido?('arquivo.ret')
#=> true

Brcobranca::Retorno.detectar_formato('arquivo.ret')
#=> :cnab400
```

### Contributors
- Maxwell Oliveira (@maxwbh) - M&S do Brasil LTDA - www.msbrasil.inf.br

## [12.4.0] - 2026-01-03

### Added
- **API de Serialização para Remessa** (Fase 3): Novos métodos para Pagamento e Remessa::Base
  - `Pagamento#to_hash`: Retorna todos os atributos do pagamento
  - `Pagamento#as_json`: Retorna dados com chaves string
  - `Pagamento#to_json`: Retorna string JSON
  - `Pagamento#valido?`: Validação sem exceção
  - `Pagamento#to_hash_seguro`: Hash com status de validação
  - `Remessa::Base#to_hash`: Retorna dados da remessa com pagamentos
  - `Remessa::Base#as_json`: Retorna dados com chaves string
  - `Remessa::Base#to_json`: Retorna string JSON
  - `Remessa::Base#valido?`: Validação sem exceção
  - `Remessa::Base#to_hash_seguro`: Hash com status de validação

- **Factory Method para Remessas**: `Brcobranca::Remessa.criar`
  - Criação simplificada de remessas por banco e formato
  - Suporte a códigos bancários (ex: '756') e nomes (ex: :sicoob)
  - Formatos suportados: :cnab240, :cnab400, :cnab444
  - `Brcobranca::Remessa.bancos_disponiveis`: Lista bancos disponíveis
  - `Brcobranca::Remessa.suporta?`: Verifica compatibilidade banco/formato

### Example
```ruby
# Criar pagamento
pagamento = Brcobranca::Remessa::Pagamento.new(
  nosso_numero: '00001',
  valor: 100.50,
  nome_sacado: 'Cliente Exemplo',
  # ... outros campos
)

# Serialização
pagamento.to_hash
#=> { nosso_numero: '00001', valor: 100.50, ... }

pagamento.to_hash_seguro
#=> { valid: true, errors: [], nosso_numero: '00001', ... }

# Factory method para remessas
remessa = Brcobranca::Remessa.criar(
  banco: :sicoob,
  formato: :cnab400,
  empresa_mae: 'Empresa LTDA',
  pagamentos: [pagamento]
)

# Verificar suporte
Brcobranca::Remessa.suporta?(banco: :sicoob, formato: :cnab400)
#=> true
```

### Contributors
- Maxwell Oliveira (@maxwbh) - M&S do Brasil LTDA - www.msbrasil.inf.br

## [12.3.0] - 2026-01-02

### Added
- **Métodos de Validação Seguros**: Novos métodos que não levantam exceções
  - `valido?`: Retorna true/false sem levantar exceção (diferente de `valid?`)
  - `to_hash_seguro`: Retorna hash com flag `:valid` e lista `:errors`
  - `as_json_seguro`: Versão JSON-ready do `to_hash_seguro`
  - `to_json_seguro`: String JSON segura

- **Melhorias em Errors**: Novos métodos na classe `Brcobranca::Util::Errors`
  - `to_hash`: Retorna erros como Hash agrupados por atributo
  - `as_json`: Hash com chaves string para JSON
  - `to_json`: String JSON dos erros
  - `any?` / `empty?`: Verificação de existência de erros
  - `first_messages`: Primeiro erro de cada atributo
  - `clear`: Limpa todos os erros
  - `merge!`: Combina erros de outro objeto

### Example
```ruby
boleto = Brcobranca::Boleto::Sicoob.new(params)

# Validação sem exceção
if boleto.valido?
  processar(boleto)
else
  tratar_erros(boleto.errors.to_hash)
end

# Hash seguro (nunca levanta exceção)
resultado = boleto.to_hash_seguro
if resultado[:valid]
  usar_dados(resultado)
else
  mostrar_erros(resultado[:errors])
end

# Erros como JSON
boleto.errors.as_json
#=> { "sacado" => ["não pode estar em branco"], "agencia" => ["não é um número"] }
```

### Contributors
- Maxwell Oliveira (@maxwbh) - M&S do Brasil LTDA - www.msbrasil.inf.br
## [12.2.1] - 2026-01-02

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
- 336 - C6 Bank
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

- [Versões Estáveis](https://github.com/Maxwbh/brcobranca/releases)
- [Documentação Completa](docs/README.md)
- [Guia de Início Rápido](docs/getting-started/quick-start.md)
- [Campos por Banco](docs/banks/fields-reference.md)

---

**Formato de Versionamento:** MAJOR.MINOR.PATCH
- **MAJOR**: Mudanças incompatíveis com versões anteriores
- **MINOR**: Novas funcionalidades compatíveis com versões anteriores
- **PATCH**: Correções de bugs compatíveis com versões anteriores

**Mantido por:** [Maxwell da Silva Oliveira](https://github.com/Maxwbh/brcobranca) - M&S do Brasil LTDA
**Contribuidores:** Comunidade BRCobrança

---

### Contribuidor v12.1.0

**Maxwell Oliveira** - M&S do Brasil LTDA
- Email: maxwbh@gmail.com
- LinkedIn: [/maxwbh](https://linkedin.com/in/maxwbh)
- Website: [www.msbrasil.inf.br](https://www.msbrasil.inf.br)
