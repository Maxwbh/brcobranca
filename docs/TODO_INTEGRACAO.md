# Roadmap: brcobranca

> Status das entregas do gem `brcobranca`.
>
> **Mantenedor:** Maxwell Oliveira (@maxwbh) — M&S do Brasil LTDA
> **Versão atual:** 12.10.1 · Ruby >= 3.0 · 18 bancos

---

## ✅ Histórico de entregas

Detalhes completos no [CHANGELOG](../CHANGELOG.md).

| Versão | Entrega |
|:---:|---|
| v12.2.0 | Boleto API (`to_hash`, `as_json`, `to_json`, `dados_calculados`) |
| v12.3.0 | Validação segura (`valido?`, `to_hash_seguro`) |
| v12.4.0 | Remessa API (`Remessa::Base#to_hash`, factory `Remessa.criar`) |
| v12.5.0 | Retorno API (`Retorno::Base#to_hash`, factory `Retorno.parse`) |
| v12.6.x | Atualizações de documentação e gemspec |
| v12.8.0 | Campos PIX no boleto (`chave_pix`, `tipo_chave_pix`, `txid`) + `Brcobranca::Bancos` |
| v12.10.x | `PrawnCarne` (carnê 3/página) + tema visual (logo, cor, marca d'água, fonte TTF) |

---

## ✅ Fases concluídas

### Fase 7 — bancos, PIX e templates

- ✅ **Banco C6 (336)** — boleto, remessa CNAB 400, retorno CNAB 400
- ✅ **Sicoob Carteira 9** — nova modalidade 2024/2025 com `numero_contrato`
- ✅ **Sicoob Layout 810** — opção sem cálculo automático do DV
- ✅ **PIX em 7 bancos** — `PixMixin` CNAB 400 e 240 (`BradescoPix`, `ItauPix`, `BancoC6Pix`, `SantanderPix`, `SicoobPix`, `CaixaPix`, `BancoBrasilPix`)
- ✅ **Template Prawn** — alternativa ao RGhost sem GhostScript
- ✅ **Fix RGhost 0.9.9** — compatibilidade com `RGhost::VERSION`
- ✅ **Fixtures visuais** — geração via `bin/generate_fixtures` (18 bancos) + 13 arquivos CNAB; exemplos Sicoob PIX versionados

### Fase 8 — registro de bancos e dados PIX no boleto

- ✅ **`Brcobranca::Bancos`** — registro central (todos/find/com_pix/as_json), 20 specs
- ✅ **Campos PIX no `Boleto::Base`** — `chave_pix`, `tipo_chave_pix`, `txid`; `dados_pix` expandido
- ✅ **Configs do projeto** — Ruby >= 3.0, RuboCop 3.0, Dockerfile 3.4, CI actions v4/v3
- ✅ **Documentação** — README, api_referencia, campos_por_banco, guia_rapido

### Fase 9 — carnê e tema visual personalizável

- ✅ **`PrawnCarne`** — carnê de pagamento (canhoto + ficha + QR PIX), 3 boletos por página A4
- ✅ **Tema visual** (`PrawnTema`, compartilhado pelos templates Prawn):
  `logo_empresa`, `cor_marca` (com contraste automático), `parcela_atual`/`total_parcelas`
  (selo "PARCELA n/N"), `rodape_contato`, `marca_dagua`, `fonte_ttf`
- ✅ **Normalização carteira/convênio** na remessa (padding automático: Sicoob CNAB 400, BB CNAB 240/400)
- ✅ **Limpeza estrutural** — métodos duplicados extraídos para `PrawnTema`;
  `spec/arquivos/` → `spec/fixtures/retorno/`; `cecred_spec.rb` → `ailos_spec.rb`

---

## 📊 Matriz de cobertura atual (18 bancos)

Legenda: ✅ implementado · — ausente · 🔑 PIX

| Cód | Banco | Boleto | Rem 240 | Rem 400 | Ret 240 | Ret 400 | PIX |
|:---:|---|:---:|:---:|:---:|:---:|:---:|:---:|
| 001 | Banco do Brasil | ✅ | ✅ | ✅ | — | ✅ | 🔑 240 |
| 004 | Banco do Nordeste | ✅ | — | ✅ | — | ✅ | — |
| 021 | Banestes | ✅ | — | — | — | — | — |
| 033 | Santander | ✅ | ✅ | ✅ | ✅ | ✅ | 🔑 400 |
| 041 | Banrisul | ✅ | — | ✅ | — | ✅ | — |
| 070 | Banco de Brasília | ✅ | — | ✅ | — | ✅ | — |
| 085 | AILOS | ✅ | ✅ | — | ✅ | — | — |
| 097 | CREDISIS | ✅ | — | ✅ | — | ✅ | — |
| 104 | Caixa | ✅ | ✅ | — | ✅ | — | 🔑 240 |
| 136 | Unicred | ✅ | ✅ | ✅ | — | ✅ | — |
| 237 | Bradesco | ✅ | — | ✅ | — | ✅ | 🔑 400 |
| 336 | C6 Bank | ✅ | — | ✅ | — | ✅ | 🔑 400 |
| 341 | Itaú | ✅ | — | ✅ (+444) | — | ✅ | 🔑 400 |
| 399 | HSBC | ✅ | — | — | — | — | — |
| 422 | Safra | ✅ | — | — | — | — | — |
| 745 | Citibank | ✅ | — | ✅ | — | — | — |
| 748 | Sicredi | ✅ | ✅ | — | ✅ | — | — |
| 756 | Sicoob | ✅ | ✅ | ✅ | ✅ | — | 🔑 240 |

**Lacunas de simetria remessa↔retorno:**
- Remessa 240 sem retorno 240: **Banco do Brasil (001)**, **Unicred (136)**
- Remessa 400 sem retorno 400: **Citibank (745)**, **Sicoob (756)**
- Boleto sem nenhum CNAB: **Banestes (021)**, **HSBC (399)**, **Safra (422)**

---

## 📋 Próximas entregas (planejado)

### 🔴 Alta prioridade

- [ ] **Retorno CNAB 400 Sicoob (756)** — fechar a lacuna remessa↔retorno do Sicoob
- [ ] **i18n** — mensagens de erro e labels em pt-BR / en
- [ ] **QR Code PIX estático** — gerar BR Code EMV a partir de `chave_pix`/`txid` sem remessa
      (conecta os campos da Fase 8 ao template Bolepix automaticamente)
- [ ] **PIX no retorno** — parsear dados PIX dos arquivos de retorno
- [ ] **Remover dependência `parseline`** — gem sem manutenção desde 2009.
      Substituir por módulo interno `Brcobranca::ParseLine` (DSL fixed-width).
      Impacta ~20 arquivos de retorno
- [ ] **Remover metadata duplicada do gemspec** — `gem.homepage` + `homepage_uri` redundantes
- [ ] **Extrair `PixMixin` compartilhado** — CNAB 240 e CNAB 400 têm mixins separados com
      estrutura semelhante (mapeamento DICT idêntico). Extrair lógica comum
- [ ] **Modularizar classes base grandes** — `cnab240/base.rb` (540 linhas),
      `boleto/base.rb` (460+), `pagamento.rb` (411), `util/validations.rb` (307)
- [ ] **Aposentar `RetornoCnab400` legado** — marcado DEPRECATED, mantido só por compat.
      Planejar remoção em major futura
- [ ] **Padronizar herança de retorno** — `Cnab400::{BancoBrasilia,BancoNordeste,Credisis}`
      herdam de `Retorno::Base` em vez de `Cnab400::Base`; `Cnab240::Caixa` herda do legado
      `RetornoCnab240`. Uniformizar (atenção: breaking change, agendar para major)
- [ ] **Encapsulamento** — muitos helpers internos estão públicos; revisar `private`/`protected`
- [ ] **Specs de retorno ausentes** (implementação já existe, faltam specs):
  - [ ] `retorno/cnab240/caixa_spec.rb`
  - [ ] `retorno/cnab400/banco_brasil_spec.rb`
  - [ ] `retorno/cnab400/banco_c6_spec.rb`
- [ ] **`Bancos.registrar`** — registro de bancos custom em runtime
- [ ] **Validação cruzada no `Bancos`** — `find` retornando classes resolvidas, não strings
- [ ] **Resolver FIXMEs de DV** — `retorno/cnab400/itau.rb` e `retorno_cnab400.rb`
      ("SEM DIV" — agência sem dígito verificador)
- [ ] **Avalista no CNAB 400 Banco do Brasil** — `TODO implementar avalista` em `monta_detalhe`

### 🟢 Baixa prioridade / futuro

- [ ] **Caixa SIGCB** — suporte a convênio de 7 dígitos
- [ ] **CNAB 240 para Bradesco** — remessa e retorno
- [ ] **CNAB 240 para Itaú** — complementar o CNAB 400/444
- [ ] **Retorno CNAB 240 Banco do Brasil (001)** e **Unicred (136)**
- [ ] **Retorno CNAB 400 Citibank (745)**
- [ ] **Retorno CNAB 444 Itaú**
- [ ] **PIX para Sicredi (748)** — CNAB 240 com Segmento Y-03
- [ ] **PIX para Banrisul (041)** — avaliar formato suportado
- [ ] **HSBC** — verificar outras carteiras (`TODO` em `boleto/hsbc.rb`)

---

## 🔗 Referências

- [CHANGELOG](../CHANGELOG.md)
- [API de Bancos](api_referencia.md#api-de-bancos)
- [API de Serialização](api_referencia.md)
- [Guia Rápido](guia_rapido.md)
- [Campos por Banco](campos_por_banco.md)
- [GitHub](https://github.com/Maxwbh/brcobranca)
