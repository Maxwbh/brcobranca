# Roadmap: brcobranca

> Status das entregas do gem `brcobranca`.
>
> **Mantenedor:** Maxwell Oliveira (@maxwbh)

---

## ✅ Histórico de entregas

Detalhes completos no [CHANGELOG](../CHANGELOG.md).

| Versão | Entrega |
|:---:|---|
| v12.2.0 | Boleto API (`to_hash`, `as_json`, `to_json`, `dados_calculados`) |
| v12.3.0 | Validação segura (`valido?`, `to_hash_seguro`) |
| v12.4.0 | Remessa API (`Remessa::Base#to_hash`, factory `Remessa.criar`) |
| v12.5.0 | Retorno API (`Retorno::Base#to_hash`, factory `Retorno.parse`) |
| v12.6.0 | Atualizações de documentação e gemspec |

---

## ✅ Fase 7 — concluída

- ✅ **Banco C6 (336)** — boleto, remessa CNAB 400, retorno CNAB 400
- ✅ **Sicoob Carteira 9** — nova modalidade 2024/2025 com `numero_contrato`
- ✅ **Sicoob Layout 810** — opção sem cálculo automático do DV
- ✅ **PIX em 7 bancos** — `PixMixin` CNAB 400 e 240, classes `BradescoPix`, `ItauPix`, `BancoC6Pix`, `SicoobPix`, `CaixaPix`, `BancoBrasilPix` (+ `SantanderPix` existente)
- ✅ **Template Prawn** — alternativa ao RGhost sem GhostScript
- ✅ **Fix RGhost 0.9.9** — compatibilidade com `RGhost::VERSION`
- ✅ **Fixtures visuais** — 42 PDFs + 13 arquivos CNAB gerados
- ✅ **Documentação** — guia rápido, campos por banco, API de serialização

---

## ✅ Fase 8 — concluída

- ✅ **`Brcobranca::Bancos`** — registro central com metadados dos 18 bancos
  - `todos`, `find`, `codigos`, `com_boleto`, `com_remessa`, `com_retorno`, `com_pix`
  - `formatos_cnab`, `as_json`, `to_json` — serialização pronta para APIs REST
  - 20 specs em `spec/brcobranca/bancos_spec.rb`
  - Autoload em `lib/brcobranca.rb`
- ✅ **Documentação atualizada** — CHANGELOG, README, api_referencia, guia_rapido, docs/README

---

## 📋 Fase 9 — próximas entregas (planejado)

### Alta prioridade

- [ ] **Retorno CNAB 400 Sicoob** — atualmente só tem remessa 400
- [ ] **Webhook/callback** no `Bancos` — permitir registrar bancos custom via `Bancos.registrar`
- [ ] **Validação cruzada** — `Bancos.find` retornando instâncias de classe em vez de strings
- [ ] **i18n** — mensagens de erro e labels em inglês/português
- [ ] **Geração de QR Code estático** — BR Code EMV sem necessidade de remessa

### Baixa prioridade / futuro

- [ ] **CNAB 240 para Bradesco** — remessa e retorno no formato 240
- [ ] **CNAB 240 para Itaú** — complementar o CNAB 400/444 existente
- [ ] **Retorno CNAB 240 Banco do Brasil** — atualmente só tem remessa 240
- [ ] **Retorno CNAB 400 Citibank** — atualmente só tem remessa
- [ ] **Retorno CNAB 240 Unicred** — atualmente só tem remessa 240
- [ ] **Retorno CNAB 444 Itaú** — atualmente só tem remessa 444
- [ ] **PIX para Sicredi** — CNAB 240 com Segmento Y-03
- [ ] **PIX para Banrisul** — avaliar formato suportado pelo banco
- [ ] **Template Prawn para boleto tradicional** (sem PIX) — complementar o `PrawnBolepix`

---

## 🔗 Referências

- [CHANGELOG](../CHANGELOG.md)
- [API de Bancos](api_referencia.md#api-de-bancos)
- [API de Serialização](api_referencia.md)
- [Guia Rápido](guia_rapido.md)
- [Campos por Banco](campos_por_banco.md)
- [GitHub](https://github.com/Maxwbh/brcobranca)
