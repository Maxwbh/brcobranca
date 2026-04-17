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

## ✅ Fase 7 — ciclo atual (concluído)

- ✅ **Banco C6 (336)** — boleto, remessa CNAB 400, retorno CNAB 400
- ✅ **Sicoob Carteira 9** — nova modalidade 2024/2025 com `numero_contrato`
- ✅ **Sicoob Layout 810** — opção sem cálculo automático do DV
- ✅ **PIX em 7 bancos** — `PixMixin` CNAB 400 e 240, classes `BradescoPix`, `ItauPix`, `BancoC6Pix`, `SicoobPix`, `CaixaPix`, `BancoBrasilPix` (+ `SantanderPix` existente)
- ✅ **Template Prawn** — alternativa ao RGhost sem GhostScript
- ✅ **Fix RGhost 0.9.9** — compatibilidade com `RGhost::VERSION`
- ✅ **Fixtures visuais** — 41 PDFs + 13 arquivos CNAB gerados
- ✅ **Documentação** — guia rápido, campos por banco, API de serialização

---

## 🔗 Referências

- [CHANGELOG](../CHANGELOG.md)
- [API de Serialização](api_referencia.md)
- [Guia Rápido](guia_rapido.md)
- [Campos por Banco](campos_por_banco.md)
- [GitHub](https://github.com/Maxwbh/brcobranca)
