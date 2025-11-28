# Guia de Instalação

Este guia fornece instruções detalhadas para instalar e configurar o BRCobranca em diferentes ambientes.

## Índice

- [Requisitos](#requisitos)
- [Instalação via RubyGems](#instalação-via-rubygems)
- [Instalação via Bundler](#instalação-via-bundler)
- [Instalação do GhostScript](#instalação-do-ghostscript)
- [Configuração](#configuração)
- [Verificação da Instalação](#verificação-da-instalação)
- [Resolução de Problemas](#resolução-de-problemas)

## Requisitos

### Software Necessário

- **Ruby**: >= 2.7.0 (recomendado: 3.0+)
- **GhostScript**: > 9.0 (necessário para geração de PDFs e códigos de barras)
- **Bundler**: >= 2.0 (recomendado)

### Verificando Requisitos

```bash
# Verificar versão do Ruby
ruby --version
# Saída esperada: ruby 3.x.x ou 2.7+

# Verificar versão do GhostScript
gs --version
# Saída esperada: 9.x ou superior

# Verificar Bundler
bundle --version
# Saída esperada: Bundler version 2.x.x
```

## Instalação via RubyGems

A forma mais simples de instalar o BRCobranca é através do RubyGems:

```bash
gem install brcobranca
```

### Instalando uma Versão Específica

```bash
# Instalar versão específica
gem install brcobranca -v 12.0.0

# Instalar última versão pré-release
gem install brcobranca --pre
```

### Verificando a Instalação

```bash
gem list brcobranca
```

Saída esperada:
```
*** LOCAL GEMS ***
brcobranca (12.0.0)
```

## Instalação via Bundler

### Em Projetos Ruby/Rails

Adicione ao seu `Gemfile`:

```ruby
# Última versão estável
gem 'brcobranca'

# Ou especifique uma versão
gem 'brcobranca', '~> 12.0'

# Ou use a versão de desenvolvimento
gem 'brcobranca', github: 'kivanio/brcobranca'
```

Depois execute:

```bash
bundle install
```

### Otimizando a Instalação

Para instalações mais rápidas em produção:

```ruby
# Gemfile
gem 'brcobranca', '~> 12.0', require: 'brcobranca'
```

```bash
# Instalar sem gems de desenvolvimento
bundle install --without development test

# Para ambientes de produção
bundle install --deployment --without development test
```

## Instalação do GhostScript

O GhostScript é essencial para geração de PDFs e códigos de barras.

### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install ghostscript
```

### CentOS/RHEL/Fedora

```bash
sudo yum install ghostscript
# ou
sudo dnf install ghostscript
```

### macOS

```bash
# Usando Homebrew
brew install ghostscript
```

### Windows

1. Baixe o instalador de [ghostscript.com/download/gsdnld.html](https://ghostscript.com/download/gsdnld.html)
2. Execute o instalador
3. Adicione o GhostScript ao PATH do sistema

### Verificando a Instalação do GhostScript

```bash
gs --version
```

Se o comando não for encontrado, verifique se o GhostScript está no PATH:

```bash
# Linux/macOS
which gs

# Verificar funcionalidade
gs -sDEVICE=pdfwrite -o test.pdf -c quit
```

## Configuração

### Configuração Básica (Rails)

Crie um inicializador em `config/initializers/brcobranca.rb`:

```ruby
# config/initializers/brcobranca.rb

# Configuração global (opcional)
Brcobranca.configure do |config|
  # config.gerador = :rghost (padrão)
end

# Configurar locale para português do Brasil
I18n.locale = :'pt-BR'
```

### Configuração para Outros Frameworks Ruby

```ruby
require 'brcobranca'

# Configurar encoding
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
```

### Variáveis de Ambiente (Recomendado para Produção)

Crie um arquivo `.env` (não commitar este arquivo!):

```bash
# .env
BANCO_CODIGO=237
BANCO_AGENCIA=1234
BANCO_CONTA=12345
BANCO_DIGITO=1
CEDENTE_NOME="Minha Empresa LTDA"
CEDENTE_DOCUMENTO=12345678000199
```

Use com a gem `dotenv`:

```ruby
# Gemfile
gem 'dotenv-rails', groups: [:development, :test]

# Depois use as variáveis
boleto.agencia = ENV['BANCO_AGENCIA']
```

## Verificação da Instalação

### Teste Básico

Crie um arquivo `test_brcobranca.rb`:

```ruby
require 'brcobranca'

# Criar um boleto de teste
boleto = Brcobranca::Boleto::BancoDoBrasil.new
boleto.cedente = "Empresa Teste"
boleto.documento_cedente = "12345678000199"
boleto.sacado = "Cliente Teste"
boleto.sacado_documento = "12345678900"
boleto.agencia = "1234"
boleto.conta_corrente = "123456"
boleto.convenio = "1234567"
boleto.numero_documento = "123456"
boleto.valor = 100.00
boleto.data_vencimento = Date.today + 30
boleto.data_documento = Date.today

# Validar boleto
if boleto.valid?
  puts "✓ Boleto criado com sucesso!"
  puts "  Linha digitável: #{boleto.linha_digitavel}"

  # Testar geração de PDF
  begin
    pdf = boleto.to(:pdf)
    puts "✓ Geração de PDF funcionando!"

    # Salvar PDF de teste
    File.open('boleto_teste.pdf', 'wb') { |f| f.write(pdf) }
    puts "✓ PDF salvo como 'boleto_teste.pdf'"
  rescue => e
    puts "✗ Erro ao gerar PDF: #{e.message}"
    puts "  Verifique se o GhostScript está instalado corretamente"
  end
else
  puts "✗ Erro na validação do boleto:"
  boleto.errors.full_messages.each do |msg|
    puts "  - #{msg}"
  end
end
```

Execute o teste:

```bash
ruby test_brcobranca.rb
```

### Teste em Aplicação Rails

No console do Rails:

```bash
rails console
```

```ruby
# No console Rails
boleto = Brcobranca::Boleto::BancoDoBrasil.new
boleto.cedente = "Teste"
boleto.valid?
```

## Resolução de Problemas

### Erro: "GhostScript not found"

**Problema**: GhostScript não está instalado ou não está no PATH.

**Solução**:
```bash
# Verificar se está instalado
which gs

# Se não estiver, instalar
# Ubuntu/Debian
sudo apt-get install ghostscript

# macOS
brew install ghostscript
```

### Erro: "LoadError: cannot load such file -- brcobranca"

**Problema**: Gem não instalada ou não carregada.

**Solução**:
```bash
# Verificar se a gem está instalada
gem list brcobranca

# Se não estiver, instalar
gem install brcobranca

# Em projetos com Bundler
bundle install
```

### Erro: "invalid byte sequence in UTF-8"

**Problema**: Problemas de encoding.

**Solução**:
```ruby
# Adicionar no início do arquivo ou inicializador
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
```

### Erro ao Gerar PDF em Produção (Heroku/Render)

**Problema**: GhostScript não disponível no ambiente.

**Solução para Heroku**:

Adicione o buildpack do GhostScript:

```bash
heroku buildpacks:add --index 1 https://github.com/buitron/heroku-buildpack-ghostscript
```

**Solução para Render**:

Adicione ao `render.yaml`:

```yaml
services:
  - type: web
    name: myapp
    env: ruby
    buildCommand: |
      bundle install
      apt-get update
      apt-get install -y ghostscript
    startCommand: bundle exec puma -C config/puma.rb
```

### Problemas com Dependências

```bash
# Limpar cache de gems
gem cleanup

# Reinstalar dependências
bundle clean --force
bundle install

# Em caso de conflitos
rm Gemfile.lock
bundle install
```

### Erro: "You must have Ghostscript installed"

**Problema**: GhostScript instalado mas não detectado pela gem rghost.

**Solução**:

```ruby
# Verificar configuração do RGhost
require 'rghost'
puts RGhost::Config::GS[:path]

# Se o caminho estiver errado, configure manualmente
RGhost::Config::GS[:path] = '/usr/bin/gs' # ou caminho correto
```

## Performance e Otimização

### Cache de Templates

Para melhor performance, considere cachear os templates de boleto:

```ruby
# Em Rails
Rails.cache.fetch("boleto_template_#{banco}") do
  # gerar template
end
```

### Geração em Background

Para geração de muitos boletos, use jobs em background:

```ruby
# Sidekiq
class BoletoJob < ApplicationJob
  queue_as :default

  def perform(boleto_params)
    boleto = Brcobranca::Boleto::BancoDoBrasil.new(boleto_params)
    pdf = boleto.to(:pdf)
    # salvar ou enviar PDF
  end
end
```

### Limites de Memória

Para ambientes com pouca memória (como plano free do Render):

```ruby
# Processar boletos em lotes pequenos
boletos.each_slice(10) do |lote|
  lote.each { |b| processar_boleto(b) }
  GC.start # Forçar garbage collection
end
```

## Próximos Passos

Após a instalação bem-sucedida:

1. Consulte o [Guia de Início Rápido](getting-started/quick-start.md)
2. Veja a [Documentação de Campos por Banco](banks/fields-reference.md)
3. Explore os [Exemplos de Uso](https://github.com/kivanio/brcobranca_exemplo)

## Suporte

- **Documentação**: [Wiki Oficial](https://github.com/kivanio/brcobranca/wiki)
- **Issues**: [GitHub Issues](https://github.com/kivanio/brcobranca/issues)
- **Discussões**: [GitHub Discussions](https://github.com/kivanio/brcobranca/discussions)

---

**Instalação bem-sucedida?** Contribua melhorando esta documentação! 🎉
