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

## PDFs de referência

| Arquivo | Descrição |
|---|---|
| [`modelo_referencia_layout_sicoob.pdf`](modelo_referencia_layout_sicoob.pdf) | Modelo real de boleto Sicoob utilizado como referência para o layout do template Prawn. Contém 2 páginas (recibo e ficha de compensação) |

## Fixtures gerados

Para ver PDFs gerados automaticamente (41 bancos/variações + 13 arquivos CNAB
de exemplo), consulte:

- `spec/fixtures/generated/pdf/` — boletos renderizados (RGhost e Prawn)
- `spec/fixtures/generated/remessa/` — arquivos CNAB 240/400

Para regenerar:

```bash
bundle exec bin/generate_fixtures
```
