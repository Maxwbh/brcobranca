# Sistema de Versionamento

O BRCobranca utiliza [Semantic Versioning (SemVer)](https://semver.org/) para gerenciar suas versões.

## Formato de Versão

As versões seguem o formato: `MAJOR.MINOR.PATCH`

- **MAJOR** (X.0.0): Mudanças incompatíveis com versões anteriores (breaking changes)
- **MINOR** (0.X.0): Novas funcionalidades compatíveis com versões anteriores
- **PATCH** (0.0.X): Correções de bugs compatíveis com versões anteriores

### Exemplos

```
12.0.0 → 12.0.1  (patch: correção de bug)
12.0.1 → 12.1.0  (minor: nova feature)
12.1.0 → 13.0.0  (major: breaking change)
```

## Sistema de Versionamento Automático

O projeto possui dois métodos para incrementar versões:

### 1. Versionamento Manual (Recomendado para Releases)

Use o script `bin/bump_version` para controle manual:

```bash
# Incrementar PATCH (12.0.0 → 12.0.1)
bin/bump_version patch

# Incrementar MINOR (12.0.0 → 12.1.0)
bin/bump_version minor

# Incrementar MAJOR (12.0.0 → 13.0.0)
bin/bump_version major
```

O script automaticamente:
1. Atualiza `lib/brcobranca/version.rb`
2. Atualiza `CHANGELOG.md` com a nova versão e data
3. Exibe instruções para commit e tag

**Workflow recomendado:**

```bash
# 1. Fazer suas mudanças
git add .
git commit -m "feat: Nova funcionalidade X"

# 2. Incrementar versão apropriada
bin/bump_version minor

# 3. Revisar mudanças no CHANGELOG.md
# Adicione descrições detalhadas das mudanças

# 4. Commitar a versão
git add lib/brcobranca/version.rb CHANGELOG.md
git commit -m "chore: Bump version to 12.1.0"

# 5. Criar tag
git tag -a v12.1.0 -m "Release 12.1.0"

# 6. Push
git push origin main
git push --tags
```

### 2. Versionamento Automático via CI/CD

O projeto possui um workflow GitHub Actions que incrementa versões automaticamente baseado em mensagens de commit.

**Ativação:** Commits no branch `main`/`master`

**Regras de detecção:**

| Mensagem de Commit | Tipo de Bump | Exemplo |
|-------------------|--------------|---------|
| `feat!:` ou `BREAKING CHANGE:` | MAJOR | `feat!: Remove suporte Ruby 2.6` |
| `feat:` ou `feature:` | MINOR | `feat: Adiciona banco Nubank` |
| Qualquer outra | PATCH | `fix: Corrige cálculo DV` |

**Exemplos de mensagens:**

```bash
# MAJOR bump (13.0.0)
git commit -m "feat!: Remove deprecated methods"
git commit -m "feat: New API

BREAKING CHANGE: Old API removed"

# MINOR bump (12.1.0)
git commit -m "feat: Add support for Banco XYZ"
git commit -m "feature(sicoob): Add new carteira support"

# PATCH bump (12.0.1)
git commit -m "fix: Correct barcode calculation"
git commit -m "docs: Update README"
git commit -m "refactor: Improve code quality"
```

**O workflow automaticamente:**
1. Detecta o tipo de mudança
2. Incrementa a versão apropriadamente
3. Atualiza `version.rb` e `CHANGELOG.md`
4. Cria commit de versão
5. Cria tag Git
6. Cria GitHub Release
7. Faz push das mudanças

**Desabilitar auto-bump:**

Para commits que não devem gerar nova versão, adicione `[skip ci]` na mensagem:

```bash
git commit -m "docs: Update typos [skip ci]"
```

## Padrão de Mensagens de Commit

O projeto segue o [Conventional Commits](https://www.conventionalcommits.org/):

```
<tipo>(<escopo opcional>): <descrição>

<corpo opcional>

<rodapé opcional>
```

### Tipos de Commit

- `feat`: Nova funcionalidade (MINOR bump)
- `fix`: Correção de bug (PATCH bump)
- `docs`: Documentação (PATCH bump)
- `style`: Formatação (PATCH bump)
- `refactor`: Refatoração sem mudança de comportamento (PATCH bump)
- `perf`: Melhorias de performance (PATCH bump)
- `test`: Testes (PATCH bump)
- `chore`: Tarefas de manutenção (PATCH bump)
- `ci`: Mudanças no CI/CD (PATCH bump)

### Breaking Changes

Para indicar breaking changes, use:

1. `!` após o tipo/escopo: `feat!:` ou `feat(api)!:`
2. Rodapé `BREAKING CHANGE:` no corpo do commit

```bash
# Método 1
git commit -m "feat!: Change API response format"

# Método 2
git commit -m "feat: Change API response format

BREAKING CHANGE: API now returns JSON instead of XML"
```

## Gerenciamento do CHANGELOG

### Estrutura

O `CHANGELOG.md` segue o formato [Keep a Changelog](https://keepachangelog.com/):

```markdown
## [Unreleased]

### Added
- Nova funcionalidade X

### Changed
- Mudança no comportamento Y

### Fixed
- Correção do bug Z

## [12.0.1] - 2024-11-27

### Fixed
- Correção do cálculo do DV
```

### Categorias

- **Added**: Novas funcionalidades
- **Changed**: Mudanças em funcionalidades existentes
- **Deprecated**: Funcionalidades marcadas como obsoletas
- **Removed**: Funcionalidades removidas
- **Fixed**: Correções de bugs
- **Security**: Correções de vulnerabilidades

### Workflow

1. **Durante desenvolvimento**: Adicione mudanças na seção `[Unreleased]`

```markdown
## [Unreleased]

### Added
- Suporte ao Banco Nubank (#123)

### Fixed
- Correção no cálculo do nosso número do Sicoob (#124)
```

2. **Ao fazer release**: O script `bin/bump_version` move `[Unreleased]` para a nova versão

```markdown
## [Unreleased]

<!-- Próximas mudanças -->

## [12.1.0] - 2024-11-27

### Added
- Suporte ao Banco Nubank (#123)

### Fixed
- Correção no cálculo do nosso número do Sicoob (#124)
```

## Publicação no RubyGems

### Manual

```bash
# 1. Construir a gem
gem build brcobranca.gemspec

# 2. Publicar
gem push brcobranca-12.0.1.gem

# Ou usar rake
bundle exec rake release
```

### Automática (CI/CD)

O projeto pode ser configurado para publicar automaticamente no RubyGems quando uma tag é criada:

1. Configure o secret `RUBYGEMS_API_KEY` no GitHub
2. O workflow detectará a tag e publicará automaticamente

## Verificando Versões

### Versão Atual

```ruby
# Em Ruby
require 'brcobranca'
puts Brcobranca::VERSION

# Via CLI
ruby -r brcobranca -e "puts Brcobranca::VERSION"

# Via gem
gem list brcobranca
```

### Histórico de Versões

- **CHANGELOG.md**: Histórico detalhado de mudanças
- **GitHub Releases**: https://github.com/kivanio/brcobranca/releases
- **RubyGems**: https://rubygems.org/gems/brcobranca/versions
- **Git Tags**: `git tag -l`

## Política de Suporte

| Versão | Status | Suporte | Segurança |
|--------|--------|---------|-----------|
| 12.x | Estável | ✅ Ativo | ✅ Ativo |
| 11.x | Manutenção | ⚠️ Crítico apenas | ✅ Ativo |
| 10.x | Obsoleto | ❌ Não | ❌ Não |
| < 10.0 | Obsoleto | ❌ Não | ❌ Não |

## Migrando entre Versões

### MAJOR (Breaking Changes)

Consulte a seção `BREAKING CHANGES` no CHANGELOG para instruções de migração.

Exemplo:
```markdown
## [13.0.0] - 2025-01-15

### BREAKING CHANGES
- Removido método `legacy_method`. Use `new_method` ao invés.

  Antes:
  ```ruby
  boleto.legacy_method
  ```

  Depois:
  ```ruby
  boleto.new_method
  ```
```

### MINOR/PATCH

Atualizações MINOR e PATCH são retrocompatíveis. Basta atualizar:

```bash
bundle update brcobranca
```

## Boas Práticas

### Para Desenvolvedores

1. **Sempre atualize o CHANGELOG** antes de fazer release
2. **Use mensagens de commit semânticas** para auto-bump funcionar
3. **Teste antes de fazer release** (`bundle exec rake spec`)
4. **Documente breaking changes** claramente
5. **Crie tags anotadas** com mensagens descritivas

### Para Usuários

1. **Fixe versões MINOR** no Gemfile: `gem 'brcobranca', '~> 12.0'`
2. **Leia o CHANGELOG** antes de atualizar versões MAJOR
3. **Teste em staging** antes de atualizar em produção
4. **Acompanhe releases** via GitHub Watch

## Recursos

- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Releases](https://github.com/kivanio/brcobranca/releases)
- [RubyGems Versions](https://rubygems.org/gems/brcobranca/versions)

## Perguntas Frequentes

### Como sei qual tipo de bump usar?

- **Quebrou algo?** → MAJOR
- **Adicionou funcionalidade?** → MINOR
- **Apenas consertou?** → PATCH

### Posso pular versões?

Não é recomendado. O SemVer funciona melhor com incrementos sequenciais.

### E se eu esquecer de atualizar o CHANGELOG?

O script `bin/bump_version` ajuda, mas é sua responsabilidade adicionar descrições significativas das mudanças.

### Como desfazer um release?

```bash
# Deletar tag local
git tag -d v12.0.1

# Deletar tag remota
git push --delete origin v12.0.1

# No RubyGems, use yank (dentro de 24h)
gem yank brcobranca -v 12.0.1
```

**⚠️ Atenção:** Yanking é permanente e pode quebrar projetos que dependem dessa versão!

---

**Última atualização**: 2025-11-27
