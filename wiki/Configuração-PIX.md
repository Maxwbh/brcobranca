# Configuração PIX

O BRCobranca suporta PIX em dois níveis:

1. **Boleto com QR Code PIX** — PDF com QR Code para pagamento via PIX
2. **Remessa CNAB com registro PIX** — arquivo CNAB com chave DICT e TXID para o banco

---

## Fluxo completo

```
Cadastro da empresa
  └── chave_pix + tipo_chave_pix
        │
        ├─── Boleto (PDF)
        │      ├── chave_pix, tipo_chave_pix, txid (dados estruturados)
        │      └── emv (string EMV → QR Code no PDF)
        │
        └─── Remessa (CNAB)
               └── PagamentoPix com codigo_chave_dict, tipo_chave_dict, txid
```

---

## 1. Campos PIX no boleto

Desde a v12.8.0, o `Boleto::Base` aceita campos PIX opcionais:

```ruby
boleto = Brcobranca::Boleto::Sicoob.new(
  # campos obrigatórios do banco...
  agencia: '4327',
  convenio: '229385',
  nosso_numero: '1',
  carteira: '1',
  valor: 100.00,
  cedente: 'Minha Empresa LTDA',
  documento_cedente: '12345678000100',
  sacado: 'Cliente',
  sacado_documento: '12345678901',

  # Campos PIX (opcionais)
  chave_pix: '12345678000100',          # chave do recebedor
  tipo_chave_pix: 'cnpj',              # cpf, cnpj, email, telefone, chave_aleatoria
  txid: 'TXID20260528001',             # identificador da transação

  # EMV para QR Code (opcional — necessário para gerar QR Code no PDF)
  emv: '00020126580014br.gov.bcb.pix0136...'
)
```

### Acessando os dados PIX

```ruby
boleto.dados_pix
# => {
#   chave_pix: '12345678000100',
#   tipo_chave_pix: 'cnpj',
#   txid: 'TXID20260528001',
#   emv: '00020126580014br.gov.bcb.pix...',
#   qrcode_disponivel: true          # true se emv presente
# }

# Via to_hash/as_json (para APIs)
boleto.to_hash[:chave_pix]           # nos dados de entrada
boleto.to_hash[:pix][:chave_pix]     # nos dados calculados

# Campos omitidos quando nil (não poluem o JSON)
boleto_sem_pix = Brcobranca::Boleto::Sicoob.new(...)
boleto_sem_pix.to_hash.key?(:chave_pix)  # => false
```

---

## 2. Boleto PDF com QR Code PIX

### Via RGhost (padrão)

```ruby
Brcobranca.setup { |c| c.gerador = :rghost_bolepix }

boleto = Brcobranca::Boleto::Sicoob.new(
  # ... campos normais
  chave_pix: '12345678000100',
  tipo_chave_pix: 'cnpj',
  emv: '00020126580014br.gov.bcb.pix0136...'
)

File.write('boleto_pix.pdf', boleto.to(:pdf))
```

### Via Prawn (sem GhostScript)

```ruby
require 'brcobranca/boleto/template/prawn_bolepix'

boleto = Brcobranca::Boleto::Sicoob.new(
  # ... campos normais + emv
)
boleto.extend(Brcobranca::Boleto::Template::PrawnBolepix)

File.write('boleto_pix.pdf', boleto.to(:pdf))
```

> Requer: `gem install prawn prawn-table barby rqrcode chunky_png`

### Personalizar label PIX

```ruby
# Global
Brcobranca.setup { |c| c.pix_label = 'Pague via PIX' }

# Por boleto
boleto.pix_label = 'Escaneie o QR Code'
```

---

## 3. Remessa CNAB com registro PIX

Para incluir o registro/segmento PIX no arquivo de remessa, use `PagamentoPix` em vez de `Pagamento`:

```ruby
pagamento_pix = Brcobranca::Remessa::PagamentoPix.new(
  # Campos padrão do pagamento
  valor: 100.00,
  data_vencimento: Date.today + 30,
  nosso_numero: '001',
  documento_sacado: '12345678901',
  nome_sacado: 'Cliente Exemplo',
  endereco_sacado: 'Rua Exemplo, 100',
  bairro_sacado: 'Centro',
  cep_sacado: '00000000',
  cidade_sacado: 'Cidade',
  uf_sacado: 'UF',

  # Campos PIX (obrigatórios no PagamentoPix)
  codigo_chave_dict: '12345678000100',
  tipo_chave_dict: 'cnpj',
  txid: 'TXID20260528001',

  # Campos PIX opcionais
  valor_maximo_pix: 100.00,
  valor_minimo_pix: 100.00,
  tipo_pagamento_pix: '00',         # default: '00'
  tipo_valor_pix: '1'               # default: '1'
)
```

### CNAB 400 (Bradesco, Itaú, Santander, C6)

Gera o **Registro tipo 8** (detalhe PIX com chave DICT):

```ruby
remessa = Brcobranca::Remessa::Cnab400::BradescoPix.new(
  # campos padrão da remessa Bradesco...
  pagamentos: [pagamento_pix]
)

File.write('remessa_pix.rem', remessa.gera_arquivo)
```

### CNAB 240 (Sicoob, Caixa, Banco do Brasil)

Gera o **Segmento Y-03** (PIX conforme FEBRABAN):

```ruby
remessa = Brcobranca::Remessa::Cnab240::SicoobPix.new(
  # campos padrão da remessa Sicoob...
  pagamentos: [pagamento_pix]
)

File.write('remessa_pix.rem', remessa.gera_arquivo)
```

---

## 4. Bancos com PIX

| Banco | Formato | Classe de remessa PIX |
|---|:---:|---|
| Santander (033) | CNAB 400 | `Cnab400::SantanderPix` |
| Bradesco (237) | CNAB 400 | `Cnab400::BradescoPix` |
| Itaú (341) | CNAB 400 | `Cnab400::ItauPix` |
| C6 Bank (336) ¹ | CNAB 400 | `Cnab400::BancoC6Pix` |
| Banco do Brasil (001) | CNAB 240 | `Cnab240::BancoBrasilPix` |
| Caixa (104) | CNAB 240 | `Cnab240::CaixaPix` |
| Sicoob (756) | CNAB 240 | `Cnab240::SicoobPix` |

> ¹ **C6 Bank:** `BancoC6Pix` gera o registro tipo 8 no padrão FEBRABAN (aceita
> os 5 tipos de chave DICT). O manual CNAB 400 do C6, porém, não define esse
> registro — o PIX oficial do C6 (Bolepix) é oferecido pela **API REST** e
> aceita **apenas chave aleatória (EVP)**. Confirme o suporte com o banco antes
> de usar essa classe em produção.

### Descobrir programaticamente

```ruby
Brcobranca::Bancos.com_pix
# => [{ codigo: "001", nome: "Banco do Brasil", ... }, ...]

Brcobranca::Bancos.com_pix.map { |b| "#{b[:codigo]} - #{b[:nome]}" }
# => ["001 - Banco do Brasil", "033 - Santander", ...]
```

---

## 5. Tipos de chave DICT

| Tipo | Valor para `tipo_chave_dict` | Formato esperado |
|---|---|---|
| CPF | `'cpf'` | 11 dígitos |
| CNPJ | `'cnpj'` | 14 caracteres |
| Email | `'email'` | formato RFC email |
| Telefone | `'telefone'` | `+DDDNNNNNNNNN` (12-13 chars) |
| Chave aleatória | `'chave_aleatoria'` | 1 a 77 caracteres (UUID) |

---

## Próximos passos

- [[Bancos Suportados]] — campos obrigatórios por banco
- [Campos por Banco](https://github.com/Maxwbh/brcobranca/blob/master/docs/campos_por_banco.md) — detalhes de cada campo PIX
