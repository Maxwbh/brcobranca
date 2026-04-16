# Artefatos gerados para validação visual

Este diretório contém os arquivos gerados automaticamente pelo script
[`bin/generate_fixtures`](../../../bin/generate_fixtures). Eles são úteis para:

- Validação visual do layout dos boletos (PDFs)
- Validação estrutural dos arquivos CNAB (`.rem`)
- Conferência do posicionamento do QR Code PIX nos boletos híbridos
- Testes de regressão visual ao alterar templates

## Como regenerar

```bash
bin/generate_fixtures
```

## Conteúdo

### `pdf/` — Boletos renderizados em PDF (34 arquivos)

#### Boletos tradicionais (RGhost)
Um PDF por banco suportado, gerado com o template padrão `RGhost`:

- `ailos.pdf`
- `banco_brasil.pdf`
- `banco_brasilia.pdf`
- `banco_c6.pdf`, `banco_c6_carteira_20.pdf`
- `banco_nordeste.pdf`
- `banestes.pdf`
- `banrisul.pdf`
- `bradesco.pdf`
- `caixa.pdf`
- `citibank.pdf`
- `credisis.pdf`
- `hsbc.pdf`
- `itau.pdf`
- `safra.pdf`
- `santander.pdf`
- `sicoob.pdf`, `sicoob_carteira_9.pdf`
- `sicredi.pdf`
- `unicred.pdf`

#### Boletos híbridos com PIX/QRCode (`RghostBolepix`)
Mesmos boletos com a string EMV BR Code gerando QR Code PIX:

- `banco_brasil_pix.pdf`
- `banco_c6_pix.pdf`, `banco_c6_carteira_20_pix.pdf`
- `bradesco_pix.pdf`
- `caixa_pix.pdf`
- `itau_pix.pdf`
- `santander_pix.pdf`
- `sicoob_pix.pdf`, `sicoob_carteira_9_pix.pdf`

#### Boletos via Prawn (alternativa sem Ghostscript)
Template experimental usando gems puro-Ruby (`prawn` + `barby` + `rqrcode`):

- `prawn_bradesco_pix.pdf`
- `prawn_caixa_pix.pdf`
- `prawn_itau_pix.pdf`
- `prawn_sicoob_pix.pdf`
- `prawn_banco_c6_pix.pdf`

### `remessa/` — Arquivos CNAB de remessa (13 arquivos)

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
- **Valor:** R$ 123,45
- **Data de vencimento:** hoje + 30 dias
- **Chave PIX:** CNPJ `12345678000100`
- **TXID:** `TXID20260416001`
- **EMV exemplo:** BR Code válido iniciando com `0002...` (fictício)
