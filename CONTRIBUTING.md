# Guia de Contribuição

Obrigado por considerar contribuir com BRCobranca! 🎉

Este documento fornece diretrizes para contribuir com o projeto. Ao participar deste projeto, você concorda em respeitar essas diretrizes.

## Índice

- [Código de Conduta](#código-de-conduta)
- [Como Posso Contribuir?](#como-posso-contribuir)
- [Processo de Desenvolvimento](#processo-de-desenvolvimento)
- [Guia de Estilo](#guia-de-estilo)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Versionamento](#versionamento)

## Código de Conduta

Este projeto segue um Código de Conduta. Ao participar, você se compromete a manter um ambiente respeitoso e acolhedor para todos.

## Como Posso Contribuir?

### Reportando Bugs

Antes de criar um relatório de bug, verifique se o problema já não foi reportado. Ao criar um relatório:

1. Use um título claro e descritivo
2. Descreva os passos exatos para reproduzir o problema
3. Forneça exemplos específicos
4. Descreva o comportamento observado e o esperado
5. Inclua informações do ambiente (versão Ruby, SO, etc.)

**Template de Bug Report:**

```markdown
## Descrição
[Descrição clara do bug]

## Passos para Reproduzir
1. ...
2. ...
3. ...

## Comportamento Esperado
[O que deveria acontecer]

## Comportamento Atual
[O que está acontecendo]

## Ambiente
- BRCobranca versão:
- Ruby versão:
- Sistema Operacional:
- GhostScript versão:

## Código de Exemplo
```ruby
# Código que reproduz o problema
```
```

### Sugerindo Melhorias

Sugestões de melhorias são bem-vindas! Inclua:

1. Descrição detalhada da melhoria
2. Por que essa mudança seria útil
3. Exemplos de uso
4. Possíveis implementações

### Pull Requests

1. **Fork** o repositório
2. **Clone** seu fork localmente
3. **Crie uma branch** para sua feature (`git checkout -b feature/MinhaNovaFeature`)
4. **Faça commit** das suas mudanças
5. **Push** para a branch (`git push origin feature/MinhaNovaFeature`)
6. **Abra um Pull Request**

#### Checklist para Pull Requests

- [ ] Código segue o guia de estilo do projeto
- [ ] Todos os testes passam (`bundle exec rake spec`)
- [ ] Testes adicionados para novas funcionalidades
- [ ] Documentação atualizada se necessário
- [ ] CHANGELOG.md atualizado na seção [Unreleased]
- [ ] Commits seguem o padrão de mensagens

## Processo de Desenvolvimento

### Configuração do Ambiente

```bash
# Clone o repositório
git clone https://github.com/kivanio/brcobranca.git
cd brcobranca

# Instale as dependências
bundle install

# Execute os testes
bundle exec rake spec
```

### Requisitos

- Ruby >= 2.7.0
- GhostScript > 9.0 (para geração de PDF e código de barras)
- Bundler

### Executando Testes

```bash
# Executar todos os testes
bundle exec rake spec

# Executar um teste específico
bundle exec rspec spec/path/to/spec_file.rb

# Executar testes com cobertura
bundle exec rake spec
```

### Linting

O projeto usa RuboCop para manter a consistência do código:

```bash
# Verificar problemas de estilo
bundle exec rubocop

# Auto-corrigir problemas simples
bundle exec rubocop -a
```

## Guia de Estilo

### Ruby

- Siga o [Ruby Style Guide](https://rubystyle.guide/)
- Use 2 espaços para indentação (não tabs)
- Mantenha linhas com no máximo 120 caracteres
- Use `frozen_string_literal: true` em todos os arquivos
- Prefira métodos de classe a variáveis de instância quando apropriado

### Commits

Use mensagens de commit claras e descritivas seguindo o padrão:

```
tipo(escopo): descrição curta

Descrição mais detalhada se necessário.

- Lista de mudanças
- Outra mudança
```

**Tipos de commit:**
- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Mudanças na documentação
- `style`: Formatação, ponto e vírgula faltando, etc
- `refactor`: Refatoração de código
- `test`: Adição ou correção de testes
- `chore`: Atualização de tarefas de build, configurações, etc

**Exemplos:**

```
feat(bradesco): Adiciona suporte para carteira 26

Implementa geração de boleto para a carteira 26 do Bradesco
conforme especificação técnica de 2024.

- Adiciona validação de campos específicos
- Atualiza cálculo do dígito verificador
- Adiciona testes de integração
```

```
fix(sicoob): Corrige cálculo do nosso número

O cálculo estava usando sequencial incorreto para carteiras 1/3.
Agora segue especificação oficial do banco.

Fixes #123
```

### Documentação

- Use YARD para documentar métodos públicos
- Inclua exemplos de uso quando apropriado
- Mantenha a documentação atualizada com as mudanças de código

```ruby
# Calcula o dígito verificador do nosso número
#
# @param numero [String] o número base para cálculo
# @return [String] o dígito verificador calculado
#
# @example
#   calcula_dv_nosso_numero("123456")
#   #=> "7"
def calcula_dv_nosso_numero(numero)
  # implementação
end
```

## Estrutura do Projeto

```
brcobranca/
├── assets/              # Logos e templates
├── docs/                # Documentação
│   ├── banks/          # Documentação por banco
│   ├── deployment/     # Guias de deploy
│   ├── getting-started/# Tutoriais iniciais
│   └── guides/         # Guias diversos
├── lib/
│   └── brcobranca/
│       ├── boleto/     # Classes de boleto por banco
│       ├── remessa/    # Classes de remessa
│       ├── retorno/    # Classes de retorno
│       └── util/       # Utilitários (cálculo, formatação, etc)
├── spec/               # Testes RSpec
└── ...
```

### Adicionando Suporte a um Novo Banco

1. Crie a classe do banco em `lib/brcobranca/boleto/`
2. Herde de `Brcobranca::Boleto::Base`
3. Implemente os métodos necessários
4. Adicione testes em `spec/brcobranca/boleto/`
5. Adicione documentação em `docs/banks/`
6. Atualize o README.md

**Exemplo básico:**

```ruby
module Brcobranca
  module Boleto
    class NovoBanco < Base
      validates :agencia, :conta_corrente, presence: true

      def codigo_banco
        "999"
      end

      def nome_banco
        "NOVO BANCO S.A."
      end

      # ... outros métodos necessários
    end
  end
end
```

## Versionamento

Este projeto segue [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Mudanças incompatíveis com versões anteriores
- **MINOR** (0.X.0): Novas funcionalidades compatíveis
- **PATCH** (0.0.X): Correções de bugs

### Processo de Release

1. Atualize `lib/brcobranca/version.rb`
2. Atualize a seção `[Unreleased]` no CHANGELOG.md
3. Crie uma tag: `git tag -a v12.0.0 -m "Release 12.0.0"`
4. Push da tag: `git push origin v12.0.0`
5. A gem será automaticamente publicada no RubyGems

## Recursos Adicionais

- [Wiki do Projeto](https://github.com/kivanio/brcobranca/wiki)
- [Issues](https://github.com/kivanio/brcobranca/issues)
- [Pull Requests](https://github.com/kivanio/brcobranca/pulls)
- [RubyDoc](http://rubydoc.info/gems/brcobranca)

## Dúvidas?

Sinta-se à vontade para:
- Abrir uma [issue](https://github.com/kivanio/brcobranca/issues) para discussão
- Consultar a [Wiki](https://github.com/kivanio/brcobranca/wiki)
- Entrar em contato com os mantenedores

## Licença

Ao contribuir com este projeto, você concorda que suas contribuições serão licenciadas sob a licença BSD do projeto.

---

**Obrigado por contribuir com BRCobranca!**
