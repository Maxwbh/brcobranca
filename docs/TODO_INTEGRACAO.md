# Roadmap: brcobranca

> Status das entregas do gem `brcobranca`.
>
> **Mantenedor:** Maxwell Oliveira (@maxwbh) — M&S do Brasil LTDA
> **Versão atual:** 12.8.0 · Ruby >= 3.0 · 18 bancos

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

---

## ✅ Fases concluídas

### Fase 7 — bancos, PIX e templates

- ✅ **Banco C6 (336)** — boleto, remessa CNAB 400, retorno CNAB 400
- ✅ **Sicoob Carteira 9** — nova modalidade 2024/2025 com `numero_contrato`
- ✅ **Sicoob Layout 810** — opção sem cálculo automático do DV
- ✅ **PIX em 7 bancos** — `PixMixin` CNAB 400 e 240 (`BradescoPix`, `ItauPix`, `BancoC6Pix`, `SantanderPix`, `SicoobPix`, `CaixaPix`, `BancoBrasilPix`)
- ✅ **Template Prawn** — alternativa ao RGhost sem GhostScript
- ✅ **Fix RGhost 0.9.9** — compatibilidade com `RGhost::VERSION`
- ✅ **Fixtures visuais** — 42 PDFs + 13 arquivos CNAB gerados

### Fase 8 — registro de bancos e dados PIX no boleto

- ✅ **`Brcobranca::Bancos`** — registro central (todos/find/com_pix/as_json), 20 specs
- ✅ **Campos PIX no `Boleto::Base`** — `chave_pix`, `tipo_chave_pix`, `txid`; `dados_pix` expandido
- ✅ **Configs do projeto** — Ruby >= 3.0, RuboCop 3.0, Dockerfile 3.4, CI actions v4/v3
- ✅ **Documentação** — README, api_referencia, campos_por_banco, guia_rapido

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

## 📋 Fase 9 — próximas entregas (planejado)

### 🔴 Alta prioridade

- [ ] **Retorno CNAB 400 Sicoob (756)** — fechar a lacuna remessa↔retorno do Sicoob
- [ ] **Specs de retorno ausentes** (cobertura de regressão — implementação já existe):
  - [ ] `retorno/cnab240/ailos_spec.rb`
  - [ ] `retorno/cnab240/caixa_spec.rb`
  - [ ] `retorno/cnab400/banco_brasil_spec.rb`
  - [ ] `retorno/cnab400/banco_c6_spec.rb`
- [ ] **`Bancos.registrar`** — registro de bancos custom em runtime (webhook/callback)
- [ ] **Validação cruzada no `Bancos`** — `find` retornando classes resolvidas, não strings
- [ ] **i18n** — mensagens de erro e labels em pt-BR / en
- [ ] **QR Code PIX estático** — gerar BR Code EMV a partir de `chave_pix`/`txid` sem remessa
      (conecta os campos da Fase 8 ao template Bolepix automaticamente)

### 🟡 Média prioridade

- [ ] **PIX no retorno** — parsear dados PIX dos arquivos de retorno
      (base: PR #268 upstream adicionou remessa+retorno PIX para Santander)
- [ ] **Caixa SIGCB — convênio de 7 dígitos** — suporte adicional (origem: fork afsys)
- [ ] **Resolver FIXMEs de DV** — `retorno/cnab400/itau.rb` e `retorno_cnab400.rb`
      ("SEM DIV" — agência sem dígito verificador)
- [ ] **Avalista no CNAB 400 Banco do Brasil** — `TODO implementar avalista` em `monta_detalhe`

### 🟢 Baixa prioridade / futuro

- [ ] **CNAB 240 para Bradesco** — remessa e retorno
- [ ] **CNAB 240 para Itaú** — complementar o CNAB 400/444
- [ ] **Retorno CNAB 240 Banco do Brasil (001)** e **Unicred (136)**
- [ ] **Retorno CNAB 400 Citibank (745)**
- [ ] **Retorno CNAB 444 Itaú**
- [ ] **PIX para Sicredi (748)** — CNAB 240 com Segmento Y-03
- [ ] **PIX para Banrisul (041)** — avaliar formato suportado
- [ ] **Template Prawn para boleto tradicional** (sem PIX)
- [ ] **HSBC** — verificar outras carteiras (`TODO` em `boleto/hsbc.rb`)

---

## 🧹 Débito técnico / Qualidade de código

> Achados da revisão completa do projeto (Fase 8). Não bloqueiam, mas reduzem manutenção futura.

- [ ] **Remover dependência `parseline`** — gem sem manutenção desde 2009. Substituir por
      módulo interno `Brcobranca::ParseLine` (DSL fixed-width). Impacta ~20 arquivos de retorno.
      Base: PR #274 upstream. *Modernização + menos dependências externas.*
- [ ] **Remover metadata duplicada do gemspec** — `gem.homepage` + `homepage_uri` redundantes.
      Base: PR #273 upstream.
- [ ] **Extrair `PixMixin` compartilhado** — CNAB 240 e CNAB 400 têm mixins separados com
      estrutura semelhante (mapeamento DICT idêntico). Extrair lógica comum para um pai.
- [ ] **Modularizar classes base grandes** — `cnab240/base.rb` (540 linhas),
      `boleto/base.rb` (460), `pagamento.rb` (411), `util/validations.rb` (307).
- [ ] **Aposentar `RetornoCnab400` legado** — marcado DEPRECATED, mantido só por compat.
      Planejar remoção em major futura.
- [ ] **Encapsulamento** — apenas 19/96 arquivos usam `private`/`protected`; muitos
      helpers internos estão públicos.
- [ ] **Renomear `cecred_spec.rb`** — testa a classe Ailos (nome enganoso).

---

## 🔄 Sincronização com upstream (kivanio/brcobranca)

> O upstream está em v12.0.0 (Ruby 3.4.3). Itens relevantes para alinhar — sem abrir PR para o upstream (fora do escopo atual).

| Item upstream | Status no fork | Ação |
|---|---|---|
| CNAB 444 Itaú (#267) | ✅ já temos | — |
| Santander PIX remessa+retorno (#268) | ⚠️ só remessa | Avaliar PIX no retorno (Fase 9 média) |
| Template Prawn (#275, aberto) | ✅ já implementado | — |
| Remover parseline (#274, aberto) | ❌ ainda usamos | Débito técnico (acima) |
| Dedup metadata gemspec (#273, aberto) | ❌ duplicado | Débito técnico (acima) |
| Renderização desconto/abatimento (#264) | ✅ `descontos_e_abatimentos` | Validar paridade |

---

## 🔗 Referências

- [CHANGELOG](../CHANGELOG.md)
- [API de Bancos](api_referencia.md#api-de-bancos)
- [API de Serialização](api_referencia.md)
- [Guia Rápido](guia_rapido.md)
- [Campos por Banco](campos_por_banco.md)
- [GitHub](https://github.com/Maxwbh/brcobranca) · [Upstream](https://github.com/kivanio/brcobranca)
