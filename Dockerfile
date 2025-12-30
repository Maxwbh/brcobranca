# Dockerfile para BRCobranca
# Utilizado para testes e CI/CD no Render.com e outras plataformas

FROM ruby:3.3-slim

# Metadados
LABEL maintainer="Maxwell Oliveira <maxwbh@gmail.com>"
LABEL description="BRCobranca - Gem para geração de boletos e arquivos CNAB"
LABEL company="M&S do Brasil LTDA - www.msbrasil.inf.br"

# Instala dependências do sistema
RUN apt-get update && apt-get install -y \
    build-essential \
    ghostscript \
    libgs-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# Define diretório de trabalho
WORKDIR /app

# Copia arquivos de dependências primeiro (para cache do Docker)
COPY Gemfile Gemfile.lock brcobranca.gemspec ./
COPY lib/brcobranca/version.rb lib/brcobranca/version.rb

# Instala dependências Ruby
RUN bundle install --jobs 4 --retry 3

# Copia o resto do código
COPY . .

# Comando padrão: executa os testes
CMD ["bundle", "exec", "rspec", "--format", "documentation"]
