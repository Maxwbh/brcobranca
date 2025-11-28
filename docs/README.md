# 📚 Documentação BRCobrança

Bem-vindo à documentação completa da gem BRCobrança! Este é o índice central de toda a documentação do projeto.

## 🚀 Começando

### Para Iniciantes
- **[Guia de Início Rápido](getting-started/quick-start.md)** - Tutorial passo a passo para começar a usar a gem
  - Instalação
  - Configuração básica
  - Seu primeiro boleto
  - Exemplos por banco
  - Integração com Rails

## 🏦 Documentação de Bancos

### Referências de Campos
- **[Campos por Banco](banks/fields-reference.md)** - Resumo dos campos obrigatórios, opcionais e validações
- **[Campos Completos por Banco](banks/complete-fields-by-bank.md)** - Documentação detalhada com todos os campos de cada banco
- **[Validação de Campos](banks/field-validation.md)** - Regras de validação específicas por banco

### Guias Específicos de Bancos
- **[Banco do Brasil - Guia Completo](banks/banco-do-brasil-guide.md)** - Implementação detalhada para o Banco do Brasil
- **[Sicoob - Troubleshooting API](banks/sicoob-api-troubleshooting.md)** - Solução de problemas específicos do Sicoob

## 📖 Guias e Referências

### Políticas e Boas Práticas
- **[Política de Campos de Boleto](guides/boleto-field-policy.md)** - Diretrizes sobre campos opcionais e obrigatórios

### Integração e Desenvolvimento
- Exemplos de integração com aplicações Rails
- Padrões de uso recomendados
- Tratamento de erros

## 🚀 Deploy e Produção

### Guias de Deployment
- **[Deploy no Render](deployment/render-guide.md)** - Guia completo para deploy otimizado no Render (plano free)
  - Configuração do ambiente
  - Otimização de recursos
  - Boas práticas

## 📋 Referência Rápida

### Bancos Suportados

| Código | Banco                  | Boleto | CNAB 240 | CNAB 400 |
|--------|------------------------|--------|----------|----------|
| 001    | Banco do Brasil        | ✅     | ✅       | ✅       |
| 004    | Banco do Nordeste      | ✅     | ❌       | ✅       |
| 021    | Banestes               | ✅     | ❌       | ❌       |
| 033    | Santander              | ✅     | ✅       | ✅       |
| 041    | Banrisul               | ✅     | ❌       | ✅       |
| 070    | Banco de Brasília      | ✅     | ❌       | ✅       |
| 085    | AILOS                  | ✅     | ✅       | ❌       |
| 097    | CREDISIS               | ✅     | ❌       | ✅       |
| 104    | Caixa                  | ✅     | ✅       | ❌       |
| 136    | Unicred                | ✅     | ✅       | ✅       |
| 237    | Bradesco               | ✅     | ❌       | ✅       |
| 341    | Itaú                   | ✅     | ❌       | ✅+444   |
| 399    | HSBC                   | ✅     | ❌       | ❌       |
| 745    | Citibank               | ✅     | ❌       | ✅       |
| 748    | Sicredi                | ✅     | ✅       | ❌       |
| 756    | Sicoob                 | ✅     | ✅       | ✅       |

### Formatos de Arquivo

#### Boletos
- **PDF** - Geração via RGhost ou Prawn
- **HTML** - Visualização web
- **JSON** - Dados estruturados para APIs

#### Remessa (Envio para o banco)
- **CNAB 240** - Formato moderno (9 bancos suportados)
- **CNAB 400** - Formato legado (13 bancos suportados)
- **CNAB 444** - Formato específico do Itaú

#### Retorno (Resposta do banco)
- **CNAB 240** - 5 bancos suportados
- **CNAB 400** - 9 bancos suportados
- **CBR643** - Formato Banco do Brasil

## 🔗 Links Úteis

### Recursos Externos
- **[Repositório GitHub](https://github.com/kivanio/brcobranca)** - Código-fonte e issues
- **[Wiki Oficial](https://github.com/kivanio/brcobranca/wiki)** - Documentação colaborativa
- **[RubyGems](https://rubygems.org/gems/brcobranca)** - Página da gem
- **[RubyDoc](http://rubydoc.info/gems/brcobranca)** - Documentação da API

### Aplicações de Exemplo
- [brcobranca.herokuapp.com](https://brcobranca.herokuapp.com) - Demo online
- [brcobranca_exemplo](http://github.com/kivanio/brcobranca_exemplo) - Exemplo oficial
- [brcobranca_app](https://github.com/thiagoc7/brcobranca_app) - App comunitário
- [API Server](https://github.com/akretion/boleto_cnab_api) - REST API (by Akretion)

## 🤝 Contribuindo

Veja o arquivo [CONTRIBUTING.md](../CONTRIBUTING.md) (se disponível) ou abra uma issue no GitHub.

## 📝 Licença

BRCobrança está licenciada sob a licença BSD. Veja o arquivo LICENSE para mais detalhes.

---

**Última atualização:** 2025-11-26
**Versão da documentação:** 2.0
**Mantido por:** Comunidade BRCobrança
