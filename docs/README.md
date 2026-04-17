# Documentação BRCobranca

Índice da documentação da biblioteca BRCobranca para geração de boletos,
cobrança híbrida com PIX, e arquivos CNAB 240/400/444.

## 📚 Documentos

### Guias de uso

| Documento | Descrição |
|-----------|-----------|
| [Guia Rápido](guia_rapido.md) | Instalação, configuração e primeiros passos |
| [Campos por Banco](campos_por_banco.md) | Campos obrigatórios/opcionais por banco |
| [API de Serialização](api_referencia.md) | `to_hash`, `as_json`, factory methods |
| [Roadmap](TODO_INTEGRACAO.md) | Status das entregas e versões |

### Arquivos do projeto

| Documento | Descrição |
|-----------|-----------|
| [README](../README.md) | Visão geral do projeto |
| [CHANGELOG](../CHANGELOG.md) | Histórico de versões |
| [CONTRIBUTING](../CONTRIBUTING.md) | Guia de contribuição |
| [SECURITY](../SECURITY.md) | Política de segurança |
| [LICENSE](../LICENSE) | Licença BSD-3-Clause |

### Fixtures visuais

| Diretório | Conteúdo |
|-----------|----------|
| [spec/fixtures/generated/pdf/](../spec/fixtures/generated/pdf/) | 41 PDFs de boletos (todos os bancos, com/sem PIX, via RGhost e Prawn) |
| [spec/fixtures/generated/remessa/](../spec/fixtures/generated/remessa/) | 13 arquivos CNAB 240/400 de exemplo |

Para regenerar os fixtures: `bin/generate_fixtures`

---

## 🏦 Bancos suportados (18)

### Boleto

001 Banco do Brasil · 004 Banco do Nordeste · 021 Banestes · 033 Santander
041 Banrisul · 070 Banco de Brasília · 085 AILOS · 097 CREDISIS
104 Caixa · 136 Unicred · 237 Bradesco · **336 C6 Bank** · 341 Itaú
399 HSBC · 422 Safra · 745 Citibank · 748 Sicredi · 756 Sicoob

### CNAB (Remessa/Retorno)

- **CNAB 240**: 9 bancos (Banco do Brasil, Caixa, Santander, Sicoob, Sicredi, Unicred, AILOS, + PIX em 3)
- **CNAB 400**: 13 bancos (todos os que suportam retorno, + PIX em 4)
- **CNAB 444**: Itaú

### PIX (Boleto Híbrido)

| Banco | Formato | Classe |
|---|:---:|---|
| Santander (033) | CNAB 400 | `Cnab400::SantanderPix` |
| Bradesco (237) | CNAB 400 | `Cnab400::BradescoPix` |
| Itaú (341) | CNAB 400 | `Cnab400::ItauPix` |
| C6 Bank (336) | CNAB 400 | `Cnab400::BancoC6Pix` |
| Banco do Brasil (001) | CNAB 240 | `Cnab240::BancoBrasilPix` |
| Caixa (104) | CNAB 240 | `Cnab240::CaixaPix` |
| Sicoob (756) | CNAB 240 | `Cnab240::SicoobPix` |

---

## 🔗 Recursos online

- [Wiki oficial](https://github.com/Maxwbh/brcobranca/wiki) — Documentação colaborativa
- [RubyDoc](http://rubydoc.info/gems/brcobranca) — Referência da API
- [RubyGems](https://rubygems.org/gems/brcobranca) — Página da gem
- [Issues](https://github.com/Maxwbh/brcobranca/issues) — Reportar problemas

---

## 💡 Versões Ruby suportadas

- Ruby 3.0, 3.1, 3.2, 3.3, 3.4+

---

**Mantido por:** [Maxwell da Silva Oliveira](https://github.com/Maxwbh) — M&S do Brasil LTDA
**Fork de:** [kivanio/brcobranca](https://github.com/kivanio/brcobranca) (autor original)
