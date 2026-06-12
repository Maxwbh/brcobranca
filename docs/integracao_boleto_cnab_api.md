# Integração boleto_cnab_api → BRCobranca

> Contrato de dados entre a API REST [`boleto_cnab_api`](https://github.com/Maxwbh/boleto_cnab_api)
> e a gem BRCobranca, incluindo os campos de **customização visual (tema)**.
>
> Fluxo: `gestao_contrato` → HTTP/JSON → `boleto_cnab_api` (Grape) → `Brcobranca`

---

## 1. Arquitetura

```
┌────────────────┐   JSON (boleto + tema)   ┌──────────────────┐   attrs    ┌─────────────┐
│ gestao_contrato├─────────────────────────►│ boleto_cnab_api  ├───────────►│ Brcobranca  │
│ (logo, cor,    │   POST /api/boleto/...   │ · boleto_class() │ klass.new  │ · Boleto::* │
│  contato da    │◄─────────────────────────┤ · filter_attrs() │            │ · PrawnBolepix
│  empresa)      │   PDF / JSON base64      │ · BoletoService  │            │ · PrawnCarne │
└────────────────┘                          └──────────────────┘            └─────────────┘
```

Como o `BoletoService` usa `filter_supported_attributes` antes de
`klass.new(values)`, **todo atributo novo da gem fica disponível na API
automaticamente** — basta incluí-lo no JSON. Exceções: campos que não são
texto puro (ex.: logo em binário) precisam de tratamento na API (seção 4).

---

## 2. Contrato atual — geração de boleto

### `POST /api/boleto/multi`

| Param | Tipo | Obrigatório | Descrição |
|---|---|:---:|---|
| `type` | String | ✅ | `pdf`, `jpg`, `png`, `tif` (Prawn: apenas `pdf`) |
| `data` | File | ✅ | Arquivo JSON com a lista de boletos |
| `template` | String | — | `rghost` (default), `rghost_bolepix`, `prawn` |
| `include_data` | String | — | `'true'` retorna JSON com `content_base64` + metadados |

### Estrutura de cada boleto no JSON (`data`)

```json
{
  "bank": "sicoob",
  "valor": 135.00,
  "cedente": "Empresa Exemplo LTDA",
  "documento_cedente": "12345678000100",
  "sacado": "Cliente Teste da Silva",
  "sacado_documento": "12345678900",
  "sacado_endereco": "Rua Exemplo, 123 - Centro - Sao Paulo/SP",
  "agencia": "4327",
  "conta_corrente": "417270",
  "convenio": "229385",
  "carteira": "1",
  "nosso_numero": "42",
  "data_vencimento": "2026-07-12",
  "documento_numero": "CT-2026-001",
  "instrucao1": "Nao receber apos o vencimento",

  "chave_pix": "12345678000100",
  "tipo_chave_pix": "cnpj",
  "txid": "TXID20260712000000000001",
  "emv": "00020126580014br.gov.bcb.pix..."
}
```

> Os campos PIX (`chave_pix`, `tipo_chave_pix`, `txid`, `emv`) estão
> disponíveis desde a v12.8.0 e já passam pelo filtro automaticamente.
> O QR Code é desenhado quando `emv` está presente (templates
> `rghost_bolepix` e `prawn`).

### Mapeamento `bank` → classe

`"sicoob"` → `Brcobranca::Boleto::Sicoob` · `"banco_c6"` →
`Brcobranca::Boleto::BancoC6` · etc. (snake_case → CamelCase).
Bancos disponíveis em runtime: `GET /api/bank_info` (usa
`Brcobranca::Bancos`).

---

## 3. Carnê (PrawnCarne) — extensão proposta da API

A gem já oferece `Brcobranca::Boleto::Template::PrawnCarne` (3 boletos por
página A4, canhoto + ficha + QR PIX). Para expor na API:

### `POST /api/boleto/carne` *(proposto)*

| Param | Tipo | Obrigatório | Descrição |
|---|---|:---:|---|
| `data` | File | ✅ | JSON com lista de boletos (parcelas, mesma estrutura da seção 2) |
| `include_data` | String | — | idem `/multi` |

Implementação no `BoletoService` (referência):

```ruby
def generate_carne(boletos_data)
  boletos = boletos_data.map { |values| create(values.delete('bank'), values) }
  Brcobranca::Boleto::Template::PrawnCarne.lote_carne(boletos)
end
```

---

## 4. Tema (customização visual) — contrato proposto

> Status: **proposta** (Fases 2/3 do roadmap de visual moderno).
> Os campos abaixo definem como a `boleto_cnab_api` deve **enviar** os
> dados quando a gem implementar o tema. Válido para os dois modelos
> (`prawn` boleto e `prawn_carne`).

### Bloco `tema` por boleto (ou no nível raiz do JSON, aplicado a todos)

```json
{
  "bank": "sicoob",
  "...campos do boleto...": "...",

  "tema": {
    "logo_empresa_base64": "iVBORw0KGgoAAAANSUhEUg...",
    "logo_empresa_formato": "png",
    "cor_marca": "006B3F",
    "parcela_atual": 2,
    "total_parcelas": 12,
    "marca_dagua": "EMPRESA EXEMPLO LTDA",
    "rodape_contato": "financeiro@empresa.com - (77) 3000-0000 - empresa.com.br"
  }
}
```

| Campo | Tipo | Limites/validação (na API) | Atributo na gem |
|---|---|---|---|
| `logo_empresa_base64` | String base64 | PNG/JPG, **máx. 500KB** decodificado | `logo_empresa` (IO/path) |
| `logo_empresa_formato` | String | `png` ou `jpg` | — (usado na decodificação) |
| `cor_marca` | String hex | `^[0-9A-Fa-f]{6}$` | `cor_marca` |
| `parcela_atual` / `total_parcelas` | Integer | > 0; atual ≤ total | `parcela_atual` / `total_parcelas` |
| `marca_dagua` | String | máx. 60 chars | `marca_dagua` |
| `rodape_contato` | String | máx. 120 chars | `rodape_contato` |

### Responsabilidades da boleto_cnab_api

1. **Decodificar o logo**: `Base64.decode64` → `Tempfile` (por requisição)
   → atribuir o **path** ao boleto. Nunca persistir em disco compartilhado.
2. **Validar antes de repassar** (tamanho do logo, formato, regex da cor) —
   responder `400` com `validation_errors` no padrão já usado pela API.
3. **Multi-tenant por requisição**: o tema é atributo **do boleto**, nunca
   configuração global (`Brcobranca.setup`) — a API atende várias empresas
   no mesmo processo.
4. **Cache opcional** do logo por hash SHA256 do conteúdo (evita
   decodificar o mesmo logo em cada parcela do carnê).
5. **Fallback**: na ausência do bloco `tema`, o PDF sai com o visual padrão
   atual — nenhum campo é obrigatório.

### Exemplo completo (carnê de 3 parcelas com tema)

```bash
curl -X POST https://sua-api/api/boleto/carne \
  -F 'include_data=true' \
  -F 'data=@carne.json;type=application/json'
```

`carne.json`:

```json
{
  "tema": {
    "logo_empresa_base64": "<base64 do PNG>",
    "logo_empresa_formato": "png",
    "cor_marca": "006B3F",
    "total_parcelas": 3,
    "rodape_contato": "financeiro@empresa.com - (77) 3000-0000"
  },
  "boletos": [
    { "bank": "sicoob", "parcela_atual": 1, "nosso_numero": "1", "valor": 135.0, "data_vencimento": "2026-07-12", "...": "..." },
    { "bank": "sicoob", "parcela_atual": 2, "nosso_numero": "2", "valor": 135.0, "data_vencimento": "2026-08-12", "...": "..." },
    { "bank": "sicoob", "parcela_atual": 3, "nosso_numero": "3", "valor": 135.0, "data_vencimento": "2026-09-12", "...": "..." }
  ]
}
```

Resposta (`include_data=true`):

```json
{
  "content_base64": "<PDF do carnê>",
  "boletos": [
    { "nosso_numero": "1", "linha_digitavel": "75691.43279 ...", "codigo_barras": "7569..." }
  ]
}
```

---

## 5. Checklist de implementação

| Lado | Item | Status |
|---|---|:---:|
| gem | Campos PIX no boleto (`chave_pix`, `tipo_chave_pix`, `txid`, `emv`) | ✅ v12.8.0 |
| gem | `PrawnBolepix` (boleto) e `PrawnCarne` (carnê 3/página) | ✅ |
| gem | Atributos de tema (`logo_empresa`, `cor_marca`, `parcela_atual`, `total_parcelas`, `marca_dagua`, `rodape_contato`) | 📋 Fase 2/3 |
| API | `template=prawn` no `/api/boleto/multi` | ✅ |
| API | Endpoint `/api/boleto/carne` (PrawnCarne) | 📋 proposto |
| API | Bloco `tema` (decodificação base64 do logo, validações, tempfile) | 📋 proposto |
| gestão_contrato | Cadastro da empresa: logo (upload), cor_hex, contato | 📋 proposto |

---

## Referências

- [API de Bancos](api_referencia.md#api-de-bancos) — descoberta de bancos/CNAB/PIX
- [Wiki: Configuração PIX](https://github.com/Maxwbh/brcobranca/wiki/Configuração-PIX)
- [Wiki: Integração com Gestão de Contratos](https://github.com/Maxwbh/brcobranca/wiki/Integração-com-Gestão-de-Contratos)
- [boleto_cnab_api](https://github.com/Maxwbh/boleto_cnab_api)
