# Roadmap: brcobranca + boleto_cnab_api

> Plano de integração entre o gem `brcobranca` (core) e a API REST `boleto_cnab_api`.
>
> **Mantenedor:** Maxwell Oliveira (@maxwbh)

---

## 🎯 Arquitetura

| Camada | Projeto | Responsabilidade |
|--------|---------|------------------|
| **Core** | [brcobranca](https://github.com/Maxwbh/brcobranca) | Cálculos, validações, geração de arquivos, serialização |
| **API** | [boleto_cnab_api](https://github.com/Maxwbh/boleto_cnab_api) | HTTP, JSON I/O, logging, autenticação, deploy |

### Fluxo de dados

```
Request HTTP
     │
     ▼
┌─────────────────┐
│ boleto_cnab_api │ ──► Validação de parâmetros HTTP
│   (Grape API)   │ ──► Logging de requisição
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   brcobranca    │ ──► Criação do objeto (Boleto/Remessa/Retorno)
│     (Gem)       │ ──► Validação de negócio
│                 │ ──► Cálculos (código barras, linha digitável)
│                 │ ──► Serialização (to_hash/as_json)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ boleto_cnab_api │ ──► Formatação da resposta HTTP
│   (Grape API)   │ ──► Logging de resposta
└────────┬────────┘
         │
         ▼
Response HTTP (JSON/PDF/etc)
```

---

## ✅ Status — brcobranca (concluído)

Histórico detalhado no [CHANGELOG](../CHANGELOG.md). Resumo dos marcos:

| Versão | Entrega |
|:---:|---|
| v12.2.0 | Boleto API (`to_hash`, `as_json`, `to_json`, `dados_calculados`) |
| v12.3.0 | Validação segura (`valido?`, `to_hash_seguro`) |
| v12.4.0 | Remessa API (`Remessa::Base#to_hash`, factory `Remessa.criar`) |
| v12.5.0 | Retorno API (`Retorno::Base#to_hash`, factory `Retorno.parse`) |
| v12.6.0 | Atualizações de documentação e gemspec |
| **Fase 7 (atual)** | **C6 Bank · PIX em 7 bancos · Sicoob Carteira 9 · Template Prawn · fix RGhost 0.9.9** |

### Fase 7 — entregas do ciclo atual

- ✅ **Banco C6 (336)** — implementação completa (boleto, remessa CNAB 400, retorno CNAB 400)
- ✅ **Sicoob Carteira 9** — nova modalidade 2024/2025 com `numero_contrato`
- ✅ **Sicoob Layout 810** — opção sem cálculo automático do DV
- ✅ **PIX em 7 bancos** — `PixMixin` CNAB 400 e CNAB 240, classes `BradescoPix`, `ItauPix`, `BancoC6Pix`, `SicoobPix`, `CaixaPix`, `BancoBrasilPix` (+ `SantanderPix` que já existia)
- ✅ **Template Prawn** — alternativa ao RGhost sem GhostScript
- ✅ **Fix RGhost 0.9.9** — compatibilidade com `RGhost::VERSION`
- ✅ **Fixtures visuais** — 41 PDFs + 13 arquivos CNAB gerados
- ✅ **Documentação** — novo guia [BOLETO_CNAB_API_INTEGRATION.md](BOLETO_CNAB_API_INTEGRATION.md)

---

## 🟡 Status — boleto_cnab_api (pendente)

Checklist de atualização no `boleto_cnab_api` para consumir as novas features:

### 1. Dependências
- [ ] Atualizar `brcobranca` para versão com Fase 7 (via `github:` branch ou tag)
- [ ] Adicionar gems opcionais do Prawn (grupo `:prawn`) se usar template alternativo

### 2. Novos endpoints
- [ ] `POST /api/remessa/pix` — remessa CNAB com registro/segmento PIX (7 bancos)
- [ ] `POST /api/boleto/prawn` — PDF via Prawn (sem GhostScript)
- [ ] `GET /api/bancos` — lista bancos suportados (via `Brcobranca::Remessa.bancos_disponiveis`)
- [ ] `GET /api/metadata` — versão, bancos, recursos ativos

### 3. Endpoints existentes (ajustes)
- [ ] `POST /api/boleto/data` — aceitar `banco_c6` como valor de `bank`
- [ ] `POST /api/boleto/validate` — aceitar `banco_c6`
- [ ] Adicionar parâmetros opcionais para Sicoob:
  - `numero_contrato` (obrigatório se `carteira = 9`)
  - `versao_layout_arquivo_opcao` (`081` ou `810`)

### 4. Documentação / Deploy
- [ ] README do boleto_cnab_api: listar novo banco C6 e novos endpoints
- [ ] Swagger/OpenAPI: adicionar schemas dos novos endpoints
- [ ] Postman collection: exemplos dos novos endpoints PIX
- [ ] Dockerfile: opção de build sem GhostScript (usando Prawn)
- [ ] CI testando ambos os geradores (RGhost + Prawn)

### 5. Testes de integração
- [ ] Testes para C6 Bank (CNAB 400)
- [ ] Testes para remessa PIX (7 bancos)
- [ ] Teste de geração via Prawn (sem GhostScript)
- [ ] Teste do Sicoob Carteira 9 com `numero_contrato`

**👉 Para o guia detalhado com exemplos de código, consulte**
[BOLETO_CNAB_API_INTEGRATION.md](BOLETO_CNAB_API_INTEGRATION.md).

---

## 🔗 Referências

- [brcobranca — CHANGELOG](../CHANGELOG.md)
- [brcobranca — API de Serialização](api_referencia.md)
- [brcobranca — Guia Rápido](guia_rapido.md)
- [brcobranca — Campos por Banco](campos_por_banco.md)
- [brcobranca GitHub](https://github.com/Maxwbh/brcobranca)
- [boleto_cnab_api GitHub](https://github.com/Maxwbh/boleto_cnab_api)
