# Exemplos

Arquivos de exemplo para uso e referência do brcobranca.

## Scripts

| Arquivo | Descrição |
|---|---|
| [`api_boleto_example.rb`](api_boleto_example.rb) | Demonstração da API de serialização (`to_hash`, `as_json`, `to_hash_seguro`) usando boleto Sicoob |

Execução:

```bash
bundle exec ruby examples/api_boleto_example.rb
```

## Boletos de exemplo (PDF)

Dois boletos Sicoob com PIX validados visualmente, um por template:

| Arquivo | Template |
|---|---|
| [`../spec/fixtures/generated/pdf/sicoob_pix.pdf`](../spec/fixtures/generated/pdf/sicoob_pix.pdf) | RGhost (`:rghost_bolepix`) |
| [`../spec/fixtures/generated/pdf/prawn_sicoob_pix.pdf`](../spec/fixtures/generated/pdf/prawn_sicoob_pix.pdf) | Prawn (`PrawnBolepix`) |
| [`../spec/fixtures/generated/pdf/prawn_carne_sicoob_pix.pdf`](../spec/fixtures/generated/pdf/prawn_carne_sicoob_pix.pdf) | Prawn (`PrawnCarne` — carnê 3 parcelas/página) |

Para gerar o conjunto completo (18 bancos, com/sem PIX) localmente:

```bash
bin/generate_fixtures
```
