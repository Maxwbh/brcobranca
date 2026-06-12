# Artefatos gerados para validação visual

Este diretório contém artefatos gerados pelo script
[`bin/generate_fixtures`](../../../bin/generate_fixtures), úteis para:

- Validação visual do layout dos boletos (PDFs)
- Validação estrutural dos arquivos CNAB (`.rem`)
- Conferência do posicionamento do QR Code PIX nos boletos híbridos
- Testes de regressão visual ao alterar templates

## PDFs versionados (2 exemplos)

Apenas os exemplos **Sicoob com PIX** são versionados no repositório,
um para cada template de renderização:

| Arquivo | Template | Descrição |
|---|---|---|
| `pdf/sicoob_pix.pdf` | **RGhost** (`:rghost_bolepix`) | Boleto híbrido com QR Code PIX, requer GhostScript |
| `pdf/prawn_sicoob_pix.pdf` | **Prawn** (`PrawnBolepix`) | Recibo do Pagador + Ficha de Compensação + QR Code PIX, puro-Ruby |

Ambos foram validados com `zbarimg`: o QR Code decodifica a string EMV
exata e o código de barras I2/5 decodifica o código correto.

## Como gerar o conjunto completo localmente

```bash
bin/generate_fixtures
```

O script gera localmente (não versionados — ver `.gitignore`):

- **PDFs de todos os 18 bancos** — boletos tradicionais (RGhost),
  híbridos com PIX (`RghostBolepix`) e via Prawn (`PrawnBolepix`)
- **Arquivos CNAB de remessa** (ver tabela abaixo)

### `remessa/` — Arquivos CNAB de remessa (13 arquivos, versionados)

#### CNAB 400

| Banco | Arquivo | Com PIX |
|---|---|:---:|
| Bradesco | `bradesco_cnab400.rem` | `bradesco_cnab400_pix.rem` |
| Itaú | `itau_cnab400.rem` | `itau_cnab400_pix.rem` |
| Santander | — | `santander_cnab400_pix.rem` |
| C6 Bank | `banco_c6_cnab400.rem` | `banco_c6_cnab400_pix.rem` |

#### CNAB 240

| Banco | Arquivo | Com PIX |
|---|---|:---:|
| Banco do Brasil | `banco_brasil_cnab240.rem` | `banco_brasil_cnab240_pix.rem` |
| Caixa | `caixa_cnab240.rem` | `caixa_cnab240_pix.rem` |
| Sicoob | `sicoob_cnab240.rem` | `sicoob_cnab240_pix.rem` |

## Estrutura dos arquivos CNAB

Os `.rem` seguem o padrão FEBRABAN:

- Cada linha tem 240 ou 400 caracteres (conforme o formato)
- Terminadores de linha: `\r\n` (CR+LF)
- Todas as linhas em UPPERCASE sem acentos

### CNAB 400 tradicional
```
0 Header (400 bytes)
1 Detalhe título (400 bytes)
9 Trailer (400 bytes)
```

### CNAB 400 com PIX
```
0 Header (400 bytes)
1 Detalhe título (400 bytes)
8 Detalhe PIX com chave DICT + TXID (400 bytes)
9 Trailer (400 bytes)
```

### CNAB 240 tradicional
```
000 Header de arquivo (240 bytes)
001 Header de lote (240 bytes)
3P  Segmento P (240 bytes)
3Q  Segmento Q (240 bytes)
3R  Segmento R (240 bytes)
005 Trailer de lote (240 bytes)
999 Trailer de arquivo (240 bytes)
```

### CNAB 240 com PIX
Adiciona o segmento Y-03 após os segmentos P/Q/R de cada título:

```
000 Header de arquivo
001 Header de lote
3P  Segmento P
3Q  Segmento Q
3R  Segmento R
3Y  Segmento Y-03 com chave DICT + TXID
005 Trailer de lote
999 Trailer de arquivo
```

## Dados usados nos fixtures

- **Beneficiário:** `Empresa Exemplo LTDA` — CNPJ `12345678000100`
- **Pagador:** `Cliente Teste da Silva` — CPF `12345678900`
- **Chave PIX:** CNPJ `12345678000100`
- **EMV exemplo:** BR Code válido iniciando com `0002...` (fictício)
