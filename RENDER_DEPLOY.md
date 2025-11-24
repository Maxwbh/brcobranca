# Deploy no Render (Plano Free) - BRCobrança

Este guia detalha como otimizar e fazer deploy de uma aplicação Ruby on Rails que usa BRCobrança no Render.com usando o plano gratuito.

## Índice

- [Pré-requisitos](#pré-requisitos)
- [Configurações do Render](#configurações-do-render)
- [Otimizações para Plano Free](#otimizações-para-plano-free)
- [Configuração do Banco de Dados](#configuração-do-banco-de-dados)
- [Variáveis de Ambiente](#variáveis-de-ambiente)
- [Build e Deploy](#build-e-deploy)
- [Geração de PDFs](#geração-de-pdfs)
- [Cache e Performance](#cache-e-performance)
- [Monitoramento](#monitoramento)

---

## Pré-requisitos

- Conta no [Render.com](https://render.com)
- Aplicação Rails usando BRCobrança
- Repositório Git (GitHub, GitLab ou Bitbucket)
- Ruby 3.0+ e Rails 6.0+

---

## Configurações do Render

### 1. Criar Web Service

1. Acesse https://dashboard.render.com
2. Clique em **New +** → **Web Service**
3. Conecte seu repositório
4. Configure:
   - **Name:** seu-app-boletos
   - **Environment:** Ruby
   - **Region:** Oregon (us-west) - mais próximo do Brasil
   - **Branch:** main ou master
   - **Build Command:** (ver abaixo)
   - **Start Command:** (ver abaixo)

### 2. Build Command

```bash
bundle install && bundle exec rake assets:precompile && bundle exec rake db:migrate
```

### 3. Start Command

```bash
bundle exec puma -C config/puma.rb
```

---

## Otimizações para Plano Free

O plano free do Render tem limitações importantes:

- **512 MB de RAM**
- **0.1 CPU compartilhado**
- **Desliga após 15 minutos de inatividade**
- **750 horas/mês gratuitas**

### 1. Configurar Puma para Baixo Consumo

**config/puma.rb:**

```ruby
# Render Free Tier Optimization
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 2 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { 1 }
threads min_threads_count, max_threads_count

# Workers reduzido para economizar memória
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "production"

# Usar apenas 1 worker no plano free
workers ENV.fetch("WEB_CONCURRENCY") { 1 }

# Preload para economizar memória
preload_app!

port ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "development" }

# Permitir requests puma control app
activate_control_app

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

plugin :tmp_restart
```

### 2. Configurar Bootsnap

**config/boot.rb:**

```ruby
ENV['BOOTSNAP_CACHE_DIR'] = '/tmp/cache'
require 'bootsnap/setup'
```

### 3. Reduzir Consumo de Memória

**config/environments/production.rb:**

```ruby
Rails.application.configure do
  # Eager load para reduzir consumo
  config.eager_load = true

  # Desabilitar logs excessivos
  config.log_level = :info

  # Não manter todos os logs na memória
  config.logger = ActiveSupport::Logger.new(STDOUT)
  config.log_formatter = ::Logger::Formatter.new

  # Cache no sistema de arquivos (mais leve que Redis no free tier)
  config.cache_store = :file_store, '/tmp/cache'

  # Assets compilados
  config.assets.compile = false
  config.assets.digest = true

  # Comprimir respostas
  config.middleware.use Rack::Deflater
end
```

### 4. Lidar com "Cold Starts"

O Render desliga o serviço após 15 minutos de inatividade. Para manter ativo:

**Opção 1: Serviço de Ping (Recomendado)**

Use um serviço gratuito como:
- [UptimeRobot](https://uptimerobot.com) - 50 monitores grátis
- [Cron-job.org](https://cron-job.org) - Gratuito
- [Pingdom](https://www.pingdom.com) - Trial gratuito

Configure para fazer ping a cada 10-14 minutos:
```
https://seu-app.onrender.com/health
```

**Opção 2: Endpoint de Health Check**

**config/routes.rb:**

```ruby
Rails.application.routes.draw do
  get '/health', to: 'health#index'
  # suas outras rotas
end
```

**app/controllers/health_controller.rb:**

```ruby
class HealthController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    render json: {
      status: 'ok',
      timestamp: Time.current,
      version: Rails.application.config.version
    }, status: :ok
  end
end
```

---

## Configuração do Banco de Dados

### PostgreSQL (Recomendado)

O Render oferece PostgreSQL gratuito com limitações:

- **1 GB de armazenamento**
- **Expira após 90 dias** (renovável)
- **Conexões limitadas**

**Gemfile:**

```ruby
gem 'pg', '~> 1.5'
```

**config/database.yml:**

```yaml
production:
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 2 } %>
  url: <%= ENV['DATABASE_URL'] %>
  # Reduzir pool de conexões para economizar
  pool: 2
  timeout: 5000
```

### Criar Banco no Render

1. No Dashboard, clique em **New +** → **PostgreSQL**
2. Copie a **Internal Database URL**
3. Adicione como variável de ambiente `DATABASE_URL`

---

## Variáveis de Ambiente

Configure no Render Dashboard → Environment:

### Essenciais

```bash
# Rails
RAILS_ENV=production
RAILS_MASTER_KEY=<seu_master_key>
SECRET_KEY_BASE=<gerado_com_rails_secret>

# Database
DATABASE_URL=<render_postgres_url>

# Puma
RAILS_MAX_THREADS=2
WEB_CONCURRENCY=1

# Locale
LANG=pt_BR.UTF-8
LC_ALL=pt_BR.UTF-8
```

### BRCobrança Específico

```bash
# Gerador de PDF (use prawn para menor consumo)
BRCOBRANCA_GERADOR=prawn

# Ambiente de boletos
BOLETO_AMBIENTE=producao
```

### Opcional

```bash
# New Relic (se usar)
NEW_RELIC_LICENSE_KEY=<sua_key>

# Sentry (monitoramento de erros)
SENTRY_DSN=<seu_dsn>
```

---

## Build e Deploy

### 1. Dockerfile (Opcional, mas recomendado)

**Dockerfile:**

```dockerfile
FROM ruby:3.4.3-slim

# Instalar dependências
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    nodejs \
    ghostscript \
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Instalar gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install -j4 --retry 3

# Copiar aplicação
COPY . .

# Precompilar assets
RUN SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

# Limpar cache
RUN bundle exec rails tmp:clear

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

### 2. render.yaml (Build Automatizado)

**render.yaml:**

```yaml
services:
  - type: web
    name: brcobranca-app
    env: ruby
    region: oregon
    plan: free
    buildCommand: bundle install && bundle exec rake assets:precompile && bundle exec rake db:migrate
    startCommand: bundle exec puma -C config/puma.rb
    envVars:
      - key: RAILS_ENV
        value: production
      - key: RAILS_MAX_THREADS
        value: 2
      - key: WEB_CONCURRENCY
        value: 1
      - key: BRCOBRANCA_GERADOR
        value: prawn
      - key: DATABASE_URL
        fromDatabase:
          name: brcobranca-db
          property: connectionString
      - key: RAILS_MASTER_KEY
        sync: false

databases:
  - name: brcobranca-db
    plan: free
    databaseName: brcobranca_production
    user: brcobranca
```

---

## Geração de PDFs

### Usar Prawn (Mais Leve)

```ruby
# config/initializers/brcobranca.rb
Brcobranca.setup do |config|
  config.gerador = :prawn
end
```

**Gemfile:**

```ruby
gem 'brcobranca'
gem 'prawn', '~> 2.4'
gem 'prawn-table', '~> 0.2'
```

### Otimizar Geração de Boletos

```ruby
# app/services/boleto_service.rb
class BoletoService
  CACHE_TTL = 1.hour

  def self.gerar(cobranca_id)
    cobranca = Cobranca.find(cobranca_id)
    cache_key = "boleto/#{cobranca.id}/#{cobranca.updated_at.to_i}"

    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      boleto = criar_boleto(cobranca)
      boleto.to(:pdf)
    end
  end

  private

  def self.criar_boleto(cobranca)
    Brcobranca::Boleto::Itau.new(
      # ... parâmetros
    )
  end
end
```

### Gerar em Background (Recomendado)

Use Sidekiq com Redis gratuito:

**Gemfile:**

```ruby
gem 'sidekiq'
gem 'redis'
```

**app/jobs/gerar_boleto_job.rb:**

```ruby
class GerarBoletoJob < ApplicationJob
  queue_as :default

  def perform(cobranca_id)
    cobranca = Cobranca.find(cobranca_id)
    pdf = BoletoService.gerar(cobranca_id)

    # Salvar em storage (ex: AWS S3)
    cobranca.boleto_pdf.attach(
      io: StringIO.new(pdf),
      filename: "boleto_#{cobranca.id}.pdf",
      content_type: 'application/pdf'
    )
  end
end
```

---

## Cache e Performance

### 1. File Store Cache

```ruby
# config/environments/production.rb
config.cache_store = :file_store, '/tmp/cache'
```

### 2. Redis Externo (Opcional)

Use serviços gratuitos:
- [Redis Cloud](https://redis.com/try-free/) - 30MB grátis
- [Upstash](https://upstash.com/) - 10k comandos/dia grátis

```ruby
# config/initializers/redis.rb
if ENV['REDIS_URL'].present?
  $redis = Redis.new(url: ENV['REDIS_URL'])

  # Configurar cache
  config.cache_store = :redis_cache_store, {
    url: ENV['REDIS_URL'],
    expires_in: 1.hour
  }
end
```

### 3. Comprimir Respostas

```ruby
# config/application.rb
config.middleware.use Rack::Deflater
```

### 4. Fragment Caching

```erb
<!-- app/views/boletos/show.html.erb -->
<% cache @cobranca do %>
  <!-- conteúdo do boleto -->
<% end %>
```

---

## Monitoramento

### 1. Logs

Acessar logs no Render:
```bash
# Via Dashboard ou CLI
render logs -s seu-servico
```

### 2. New Relic (Free Tier)

```ruby
# Gemfile
gem 'newrelic_rpm'

# config/newrelic.yml
common: &default_settings
  license_key: <%= ENV['NEW_RELIC_LICENSE_KEY'] %>
  app_name: BRCobrança App
  monitor_mode: true

production:
  <<: *default_settings
```

### 3. Sentry (Monitoramento de Erros)

```ruby
# Gemfile
gem 'sentry-ruby'
gem 'sentry-rails'

# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.traces_sample_rate = 0.1
  config.environment = Rails.env
end
```

---

## Troubleshooting

### Erro de Memória (R14)

```
Error R14 (Memory quota exceeded)
```

**Soluções:**

1. Reduzir workers do Puma para 1
2. Usar cache file store ao invés de Redis
3. Limpar cache regularmente
4. Desabilitar eager loading desnecessário

### Timeout em Requests

```
Error H12 (Request timeout)
```

**Soluções:**

1. Gerar boletos em background
2. Usar cache para boletos já gerados
3. Otimizar queries do banco

### Build Falha

```
Failed to compile assets
```

**Soluções:**

1. Adicionar `SECRET_KEY_BASE=dummy` no build
2. Verificar NODE_ENV
3. Limpar node_modules e reinstalar

### Serviço Dorme Muito

**Soluções:**

1. Configurar UptimeRobot para ping
2. Implementar endpoint de health check
3. Usar Render Plus ($7/mês) para evitar sleep

---

## Checklist de Deploy

- [ ] Configurar Puma para 1 worker
- [ ] Configurar PostgreSQL
- [ ] Adicionar variáveis de ambiente
- [ ] Configurar RAILS_MASTER_KEY
- [ ] Usar Prawn ao invés de RGhost
- [ ] Implementar cache de boletos
- [ ] Configurar health check endpoint
- [ ] Adicionar UptimeRobot ou similar
- [ ] Configurar Sentry para erros
- [ ] Testar geração de boletos
- [ ] Verificar consumo de memória
- [ ] Configurar backups do banco

---

## Custos Estimados (Free Tier)

| Serviço | Plano | Custo |
|---------|-------|-------|
| Render Web Service | Free | $0 |
| PostgreSQL | Free | $0 |
| Redis (Upstash) | Free | $0 |
| UptimeRobot | Free | $0 |
| **Total** | | **$0/mês** |

### Upgrade Recomendado (Produção)

Para produção com mais tráfego:

| Serviço | Plano | Custo |
|---------|-------|-------|
| Render Web Service | Starter | $7/mês |
| PostgreSQL | Starter | $7/mês |
| Redis (Upstash) | Pay as you go | $2-5/mês |
| **Total** | | **$16-19/mês** |

---

## Recursos Adicionais

- **Render Docs:** https://render.com/docs
- **Rails on Render:** https://render.com/docs/deploy-rails
- **PostgreSQL Render:** https://render.com/docs/databases
- **Render Free Tier:** https://render.com/docs/free

---

## Alternativas ao Render

Se precisar de mais recursos gratuitos:

1. **Fly.io** - 2.5GB RAM grátis
2. **Railway** - $5 crédito/mês
3. **Heroku** - Eco Dynos $5/mês
4. **Google Cloud Run** - Pay as you go (muito barato)

---

## Conclusão

O Render Free Tier é adequado para:
- ✅ Desenvolvimento e staging
- ✅ Projetos pessoais
- ✅ MVPs de baixo tráfego
- ✅ Demos e protótipos

**NÃO recomendado para:**
- ❌ Produção com alto tráfego
- ❌ SLAs críticos
- ❌ Processamento pesado constante

Para produção real, considere o plano Starter ($7/mês) que oferece:
- Sem sleep automático
- Mais memória e CPU
- Uptime melhor

---

**Mantido por:** Maxwell da Silva Oliveira (@maxwbh) - M&S do Brasil Ltda
**Última atualização:** 2025-11-24
