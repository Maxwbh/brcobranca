# Bancos Suportados

O BRCobranca suporta **18 bancos brasileiros** com diferentes níveis de funcionalidade.

---

## Matriz completa

| Cód | Banco | Boleto | Rem 240 | Rem 400 | Ret 240 | Ret 400 | PIX | Carteiras |
|:---:|---|:---:|:---:|:---:|:---:|:---:|:---:|---|
| 001 | Banco do Brasil | ✅ | ✅ | ✅ | — | ✅ | ✅ 240 | 11, 12, 15, 16, 17, 18, 31, 51 |
| 004 | Banco do Nordeste | ✅ | — | ✅ | — | ✅ | — | 21, 41 |
| 021 | Banestes | ✅ | — | — | — | — | — | 11 |
| 033 | Santander | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ 400 | 101, 102, 201 |
| 041 | Banrisul | ✅ | — | ✅ | — | ✅ | — | 1, 2 |
| 070 | Banco de Brasília | ✅ | — | ✅ | — | ✅ | — | 1, 2 |
| 085 | AILOS | ✅ | ✅ | — | ✅ | — | — | 1 |
| 097 | CREDISIS | ✅ | — | ✅ | — | ✅ | — | 18 |
| 104 | Caixa Econômica | ✅ | ✅ | — | ✅ | — | ✅ 240 | 1, 2 |
| 136 | Unicred | ✅ | ✅ | ✅ | — | ✅ | — | 21 |
| 237 | Bradesco | ✅ | — | ✅ | — | ✅ | ✅ 400 | 06, 09, 19, 21, 22 |
| 336 | C6 Bank | ✅ | — | ✅ | — | ✅ | ✅ 400 | 10, 20 |
| 341 | Itaú | ✅ | — | ✅ (+444) | — | ✅ | ✅ 400 | 104, 108, 109, 112, 115, 121, 147, 150, 175, 176, 196 |
| 399 | HSBC | ✅ | — | — | — | — | — | CNR, CSB |
| 422 | Safra | ✅ | — | — | — | — | — | 1, 2 |
| 745 | Citibank | ✅ | — | ✅ | — | — | — | 1, 2, 3 |
| 748 | Sicredi | ✅ | ✅ | — | ✅ | — | — | 1, 3 |
| 756 | Sicoob | ✅ | ✅ | ✅ | ✅ | — | ✅ 240 | 1, 3, 9 |

---

## Consulta programática

```ruby
# Todos os bancos
Brcobranca::Bancos.todos.size  # => 18

# Buscar por código
banco = Brcobranca::Bancos.find('756')
banco[:nome]        # => "Sicoob"
banco[:carteiras]   # => ["1", "3", "9"]
banco[:pix]         # => { "240" => "Cnab240::SicoobPix" }

# Filtrar por capacidade
Brcobranca::Bancos.com_pix.size           # => 7
Brcobranca::Bancos.com_remessa('240')     # bancos com CNAB 240
Brcobranca::Bancos.com_retorno('400')     # bancos com retorno CNAB 400
Brcobranca::Bancos.formatos_cnab          # => ["240", "400", "444"]

# JSON para API REST
Brcobranca::Bancos.to_json
```

---

## Carteiras especiais

### Sicoob (756)

| Carteira | Modalidade | Descrição |
|:---:|---|---|
| 1 / 01 | Simples Com Registro | Carteira padrão |
| 3 / 03 | Garantida Caucionada | Cobrança garantida |
| **9** | Contrato (2024/2025) | Usa `numero_contrato` no código de barras |

```ruby
# Carteira 9 — requer numero_contrato
boleto = Brcobranca::Boleto::Sicoob.new(
  carteira: '9',
  numero_contrato: '1234567',   # fornecido pelo Sicoob
  # ... demais campos
)
```

**Layout CNAB 240:** `'081'` (padrão) ou `'810'` (cliente calcula DV do nosso número)

### C6 Bank (336)

| Carteira | Descrição |
|:---:|---|
| 10 | Cobrança Simples — Emissão Banco |
| 20 | Cobrança Simples — Emissão Cliente |

```ruby
boleto = Brcobranca::Boleto::BancoC6.new(
  agencia: '0001',
  convenio: '000000123456',   # 12 dígitos
  carteira: '10',
  nosso_numero: '0000000001', # 10 dígitos
  # ...
)
```

---

## Classes por banco

### Boleto

Todas as classes herdam de `Brcobranca::Boleto::Base`:

```
Brcobranca::Boleto::BancoBrasil
Brcobranca::Boleto::BancoNordeste
Brcobranca::Boleto::Banestes
Brcobranca::Boleto::Santander
Brcobranca::Boleto::Banrisul
Brcobranca::Boleto::BancoBrasilia
Brcobranca::Boleto::Ailos
Brcobranca::Boleto::Credisis
Brcobranca::Boleto::Caixa
Brcobranca::Boleto::Unicred
Brcobranca::Boleto::Bradesco
Brcobranca::Boleto::BancoC6
Brcobranca::Boleto::Itau
Brcobranca::Boleto::Hsbc
Brcobranca::Boleto::Safra
Brcobranca::Boleto::Citibank
Brcobranca::Boleto::Sicredi
Brcobranca::Boleto::Sicoob
```

### Remessa PIX

```
Brcobranca::Remessa::Cnab400::SantanderPix
Brcobranca::Remessa::Cnab400::BradescoPix
Brcobranca::Remessa::Cnab400::ItauPix
Brcobranca::Remessa::Cnab400::BancoC6Pix
Brcobranca::Remessa::Cnab240::BancoBrasilPix
Brcobranca::Remessa::Cnab240::CaixaPix
Brcobranca::Remessa::Cnab240::SicoobPix
```

---

## Próximos passos

- [[Primeiros Passos]] — criar primeiro boleto
- [[Configuração PIX]] — adicionar PIX
- [Campos por Banco](https://github.com/Maxwbh/brcobranca/blob/master/docs/campos_por_banco.md) — referência detalhada
