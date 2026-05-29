# FAQ e Troubleshooting

## Erros comuns

### GhostScript não encontrado

```
RuntimeError: Ghostscript not found in your system environment (linux).
```

**Causa:** GhostScript não está instalado ou não está no PATH.

**Solução:**

```bash
# Ubuntu/Debian
sudo apt-get install ghostscript

# macOS
brew install ghostscript

# Alpine (Docker)
apk add ghostscript

# Verificar
which gs && gs --version
```

**Alternativa sem GhostScript:** use o [[Migração RGhost para Prawn|template Prawn]].

---

### RGhost::VERSION não definido

```
NameError: uninitialized constant RGhost::VERSION
```

**Causa:** A gem `rghost` v0.9.9 removeu o require do arquivo de versão.

**Solução:** O BRCobranca (v12.6+) já tem um fallback automático. Atualize a gem:

```bash
bundle update brcobranca
```

---

### Boleto inválido

```
Brcobranca::BoletoInvalido: Boleto inválido
```

**Solução:** verifique os campos obrigatórios:

```ruby
boleto = Brcobranca::Boleto::Sicoob.new(params)

unless boleto.valid?
  puts boleto.errors.full_messages
  # => ["Agencia nao pode estar em branco.", "Nosso numero nao e um numero."]
end

# Ou use o método seguro (nunca lança exceção)
resultado = boleto.to_hash_seguro
puts resultado[:errors] unless resultado[:valid]
```

---

### Remessa inválida

```
Brcobranca::RemessaInvalida: Remessa inválida
```

**Causa:** campos obrigatórios da remessa ou do pagamento estão ausentes/inválidos.

**Solução:**

```ruby
remessa = Brcobranca::Remessa::Cnab400::Bradesco.new(params)

unless remessa.valid?
  puts remessa.errors.full_messages
end

# Verificar também cada pagamento
remessa.pagamentos.each do |pag|
  puts pag.errors.full_messages unless pag.valid?
end
```

---

### Encoding de caracteres

```
Encoding::UndefinedConversionError: "\xC3" from UTF-8 to ASCII
```

**Solução:**

```ruby
Brcobranca.setup do |config|
  config.external_encoding = 'utf-8'
end
```

---

### Nosso número com tamanho incorreto

**Causa:** cada banco tem um tamanho específico para o nosso número.

| Banco | Tamanho nosso_numero |
|---|---|
| Banco do Brasil | 5-17 (varia por convênio) |
| Bradesco | 11 |
| Itaú | 8 |
| Santander | 7 |
| Sicoob | 7 |
| C6 Bank | 10 |
| Caixa | 15-17 |

Consulte [[Bancos Suportados]] ou [Campos por Banco](https://github.com/Maxwbh/brcobranca/blob/master/docs/campos_por_banco.md).

---

## Perguntas frequentes

### Posso gerar boleto sem GhostScript?

Sim. Use o template Prawn:

```ruby
require 'brcobranca/boleto/template/prawn_bolepix'

boleto.extend(Brcobranca::Boleto::Template::PrawnBolepix)
File.write('boleto.pdf', boleto.to(:pdf))
```

Veja [[Migração RGhost para Prawn]].

---

### Como gerar múltiplos boletos em um único PDF?

```ruby
boletos = [boleto1, boleto2, boleto3]
pdf = Brcobranca::Boleto::Base.lote(boletos, formato: :pdf)
File.write('lote.pdf', pdf)
```

---

### Quais bancos suportam PIX na remessa?

7 bancos: Santander, Bradesco, Itaú, C6 (CNAB 400) + Banco do Brasil, Caixa, Sicoob (CNAB 240).

```ruby
Brcobranca::Bancos.com_pix.map { |b| "#{b[:codigo]} - #{b[:nome]}" }
```

Veja [[Configuração PIX]] para o fluxo completo.

---

### Como sei quais campos são obrigatórios para cada banco?

Use a referência: [Campos por Banco](https://github.com/Maxwbh/brcobranca/blob/master/docs/campos_por_banco.md)

Ou programaticamente:

```ruby
banco = Brcobranca::Bancos.find('756')
banco[:carteiras]   # => ["1", "3", "9"]
banco[:cnab].keys   # => ["240", "400"]
```

---

### Como processar um arquivo de retorno sem saber o formato?

Use a factory com auto-detecção:

```ruby
# Auto-detecta formato (CNAB 240/400) e banco
resultado = Brcobranca::Retorno.parse('retorno.ret')

resultado.each do |registro|
  puts registro.to_hash
end
```

---

### O boleto gerado fica em branco / sem código de barras

**Causas possíveis:**

1. **GhostScript não instalado** — verifique com `gs --version`
2. **Boleto inválido** — verifique `boleto.valid?` antes de gerar
3. **Carteira não suportada** — consulte as carteiras válidas do banco
4. **Valor zero** — o boleto precisa de um valor > 0

---

### Docker: como configurar?

```dockerfile
FROM ruby:3.4-slim

RUN apt-get update && apt-get install -y \
    build-essential \
    ghostscript \
    libgs-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
```

Veja o `Dockerfile` na raiz do projeto para um exemplo completo.
