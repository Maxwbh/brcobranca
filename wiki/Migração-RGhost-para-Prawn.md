# Migração RGhost para Prawn

O template **Prawn** é uma alternativa puro-Ruby ao RGhost que **não requer GhostScript**.

---

## Comparação

| Aspecto | RGhost | Prawn |
|---------|--------|-------|
| **Dependência de sistema** | GhostScript obrigatório | Nenhuma |
| **Gems Ruby** | `rghost`, `rghost_barcode` | `prawn`, `prawn-table`, `barby`, `rqrcode`, `chunky_png` |
| **Boleto híbrido com PIX** | ✅ `:rghost_bolepix` | ✅ `PrawnBolepix` (layout moderno) |
| **Carnê (3/página)** | ✅ `:rghost_carne` | ✅ `PrawnCarne` |
| **QR Code PIX** | rasterizado | vetorial (nítido em qualquer DPI) |
| **Tema (logo, cor, marca d'água)** | ❌ | ✅ |
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

## 3. Gerar carnê com Prawn

O `PrawnCarne` substitui o `:rghost_carne`: canhoto destacável + Ficha de
Compensação, **3 parcelas por página A4**, com a célula "Pague com Pix"
integrada ao bloco de instruções quando há `emv`.

```ruby
require 'brcobranca/boleto/template/prawn_carne'

# Uma parcela por objeto boleto (com emv opcional para o QR Code PIX)
parcelas = (1..12).map do |n|
  Brcobranca::Boleto::Sicoob.new(
    agencia: '4327', convenio: '229385', carteira: '1',
    nosso_numero: n.to_s, valor: 100.00,
    data_vencimento: Date.today + (n * 30),
    cedente: 'Minha Empresa LTDA', documento_cedente: '12345678000100',
    sacado: 'Cliente', sacado_documento: '12345678901',
    emv: '00020126580014br.gov.bcb.pix0136...'
  )
end

# 3 parcelas por página, com linhas de corte
pdf = Brcobranca::Boleto::Template::PrawnCarne.lote_carne(parcelas)
File.write('carne.pdf', pdf)

# Ou um único carnê em página 21x9cm:
# parcelas.first.extend(Brcobranca::Boleto::Template::PrawnCarne).to_carne(:pdf)
```

---

## 4. Diferenças no layout

O template Prawn gera um PDF com **layout moderno** (grade fina e clara, muito
branco, inspirado nos boletos híbridos do mercado):

- **Recibo do Pagador** com caixas de resumo destacadas (Vencimento, Valor, Nosso Número)
- **Ficha de Compensação** no padrão FEBRABAN, com a célula "Pague com Pix"
  integrada ao bloco de instruções quando há `emv`
- **QR Code PIX vetorial** (nítido em qualquer DPI) — validado com `zbarimg`
- Linha tracejada de corte entre recibo e ficha
- **Tema opcional**: logo da empresa, cor da marca, selo "PARCELA n/N",
  marca d'água e fonte TTF (ver [[Configuração PIX]] e o README)

---

## 5. Quando usar cada template

### Use Prawn (recomendado) quando:
- Quer o **layout moderno** (boleto híbrido e carnê) com QR Code PIX vetorial
- Não pode/não quer instalar GhostScript (hosting restrito, imagem Docker menor)
- Quer dependências 100% Ruby (sem pacotes do SO)
- Precisa de **tema personalizável** (logo, cor da marca, marca d'água)

### Use RGhost (legado) quando:
- Precisa de formatos além de PDF (JPG, PNG, PS)
- Já tem uma integração existente sobre o RGhost e GhostScript instalado

---

## 6. Verificar disponibilidade

```ruby
# Verificar se as gems Prawn estão disponíveis
# (a constante PRAWN_AVAILABLE fica no módulo Template)
if defined?(Brcobranca::Boleto::Template::PRAWN_AVAILABLE) &&
   Brcobranca::Boleto::Template::PRAWN_AVAILABLE
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
| `prawn_carne_sicoob_pix.pdf` | Prawn (carnê 3/página) |

Para gerar o conjunto completo localmente (18 bancos): `bin/generate_fixtures`
