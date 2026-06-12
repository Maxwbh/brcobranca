# Migração RGhost para Prawn

O template **Prawn** é uma alternativa puro-Ruby ao RGhost que **não requer GhostScript**.

---

## Comparação

| Aspecto | RGhost | Prawn |
|---------|--------|-------|
| **Dependência de sistema** | GhostScript obrigatório | Nenhuma |
| **Gems Ruby** | `rghost`, `rghost_barcode` | `prawn`, `prawn-table`, `barby`, `rqrcode`, `chunky_png` |
| **Boleto tradicional** | ✅ `:rghost` | ❌ (somente bolepix) |
| **Boleto PIX (bolepix)** | ✅ `:rghost_bolepix` | ✅ `PrawnBolepix` |
| **Carnê** | ✅ `:rghost_carne` | ❌ |
| **Formatos de saída** | PDF, JPG, PNG, PS | PDF |
| **Docker-friendly** | Precisa `apt-get install ghostscript` | Nenhum pacote extra |

---

## 1. Instalar dependências

```ruby
# Gemfile
gem 'prawn', '~> 2.4'
gem 'prawn-table', '~> 0.2'
gem 'barby', '~> 0.6'
gem 'rqrcode', '~> 2.0'
gem 'chunky_png', '~> 1.4'
```

```bash
bundle install
```

> Todas são gems puro-Ruby — sem compilação nativa.

---

## 2. Gerar boleto com Prawn

```ruby
require 'brcobranca'
require 'brcobranca/boleto/template/prawn_bolepix'

boleto = Brcobranca::Boleto::Sicoob.new(
  agencia: '4327',
  convenio: '229385',
  nosso_numero: '1',
  carteira: '1',
  valor: 100.00,
  data_vencimento: Date.today + 30,
  cedente: 'Minha Empresa LTDA',
  documento_cedente: '12345678000100',
  sacado: 'Cliente',
  sacado_documento: '12345678901',
  # PIX (opcional)
  emv: '00020126580014br.gov.bcb.pix0136...'
)

# Estender com o template Prawn
boleto.extend(Brcobranca::Boleto::Template::PrawnBolepix)

# Gerar PDF
File.write('boleto.pdf', boleto.to(:pdf))
```

### Múltiplos boletos

```ruby
boletos = [boleto1, boleto2, boleto3]

# Cada boleto precisa do extend
boletos.each { |b| b.extend(Brcobranca::Boleto::Template::PrawnBolepix) }

# Lote em PDF único
pdf = Brcobranca::Boleto::Template::PrawnBolepix.lote(boletos)
File.write('lote.pdf', pdf)
```

---

## 3. Diferenças no layout

O template Prawn gera um PDF com:

- **Recibo do Pagador** (parte superior)
- **Ficha de Compensação** (parte inferior)
- **QR Code PIX** (quando `emv` está presente)
- Cores e sombreados seguindo o padrão FEBRABAN
- Linha tracejada de corte entre recibo e ficha

O layout é baseado no modelo oficial do Sicoob e segue o padrão dos boletos bancários brasileiros.

---

## 4. Quando usar cada template

### Use RGhost quando:
- Precisa de boleto tradicional (sem PIX)
- Precisa de carnê (3 por página)
- Precisa de formatos além de PDF (JPG, PNG)
- GhostScript já está instalado no ambiente

### Use Prawn quando:
- Não pode instalar GhostScript (ex: hosting restrito)
- Ambiente Docker e quer imagem menor
- Precisa apenas de PDF com PIX
- Quer dependências 100% Ruby (sem pacotes do SO)

---

## 5. Verificar disponibilidade

```ruby
# Verificar se as gems Prawn estão disponíveis
if defined?(Brcobranca::Boleto::Template::PrawnBolepix) &&
   Brcobranca::Boleto::Template::PrawnBolepix::PRAWN_AVAILABLE
  # Prawn está disponível
  boleto.extend(Brcobranca::Boleto::Template::PrawnBolepix)
else
  # Fallback para RGhost
  Brcobranca.setup { |c| c.gerador = :rghost_bolepix }
end
```

---

## Exemplos visuais

Dois boletos Sicoob com PIX versionados em `spec/fixtures/generated/pdf/`,
um por template (ambos validados com leitura de QR Code e código de barras):

| Arquivo | Template |
|---|---|
| `sicoob_pix.pdf` | RGhost |
| `prawn_sicoob_pix.pdf` | Prawn |

Para gerar o conjunto completo localmente (18 bancos): `bin/generate_fixtures`
