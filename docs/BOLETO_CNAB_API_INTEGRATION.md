# Integração brcobranca + boleto_cnab_api

> Guia para atualizar o [boleto_cnab_api](https://github.com/Maxwbh/boleto_cnab_api)
> (API REST para brcobranca) e expor as novas funcionalidades via HTTP.

Este documento descreve **o que precisa ser feito no `boleto_cnab_api`** para
aproveitar as novas features desta versão do brcobranca.

---

## Versão mínima do brcobranca

```ruby
# Gemfile do boleto_cnab_api
gem 'brcobranca', github: 'Maxwbh/brcobranca', branch: 'master'
# Recomendado pinned a uma tag específica após merge:
# gem 'brcobranca', '~> 12.7'  (ou superior)
```

---

## Índice

1. [Novos bancos](#1-novos-bancos)
2. [PIX em 7 bancos](#2-pix-em-7-bancos)
3. [Sicoob Carteira 9 (nova modalidade)](#3-sicoob-carteira-9)
4. [Sicoob layout 810](#4-sicoob-layout-810)
5. [Template Prawn (sem GhostScript)](#5-template-prawn)
6. [API de Serialização para REST](#6-api-de-serialização)
7. [Endpoints novos sugeridos](#7-endpoints-novos-sugeridos)
8. [Checklist de migração](#8-checklist-de-migração)

---

## 1. Novos bancos

### Banco C6 (336) — CNAB 400

**Classe de boleto:** `Brcobranca::Boleto::BancoC6`
**Classe de remessa:** `Brcobranca::Remessa::Cnab400::BancoC6`
**Classe de retorno:** `Brcobranca::Retorno::Cnab400::BancoC6`
**Aliases no factory:** `'336'`, `'c6'`, `'banco_c6'`

### Exemplo de request HTTP no boleto_cnab_api

```http
POST /api/boleto/data
Content-Type: application/json

{
  "bank": "banco_c6",
  "agencia": "0001",
  "convenio": "000000123456",
  "nosso_numero": "0000000001",
  "carteira": "10",
  "valor": 100.00,
  "data_vencimento": "2026-01-15",
  "cedente": "Empresa Exemplo LTDA",
  "documento_cedente": "12345678000100",
  "sacado": "Cliente",
  "sacado_documento": "12345678900"
}
```

### Implementação no boleto_cnab_api

```ruby
# lib/boleto_api.rb
def self.get_boleto(bank, values)
  # Adicionar 'banco_c6' ao mapeamento:
  klass_name = case bank
               when 'banco_c6', '336', 'c6' then 'BancoC6'
               # ... outros bancos
               end
  Brcobranca::Boleto.const_get(klass_name).new(values.to_h)
end
```

---

## 2. PIX em 7 bancos

A gem agora suporta geração de remessa CNAB com PIX (Boleto Híbrido) em:

| Banco | Classe no brcobranca | Formato |
|---|---|:---:|
| Santander (033) | `Cnab400::SantanderPix` | 400 |
| Bradesco (237) | `Cnab400::BradescoPix` | 400 |
| Itaú (341) | `Cnab400::ItauPix` | 400 |
| C6 Bank (336) | `Cnab400::BancoC6Pix` | 400 |
| Banco do Brasil (001) | `Cnab240::BancoBrasilPix` | 240 |
| Caixa (104) | `Cnab240::CaixaPix` | 240 |
| Sicoob (756) | `Cnab240::SicoobPix` | 240 |

### Endpoint sugerido no boleto_cnab_api

```http
POST /api/remessa/pix
Content-Type: application/json

{
  "bank": "bradesco",
  "formato": "cnab400",
  "carteira": "09",
  "agencia": "1234",
  "conta_corrente": "12345678",
  "digito_conta": "1",
  "codigo_empresa": "12345",
  "empresa_mae": "Empresa LTDA",
  "documento_cedente": "12345678000100",
  "sequencial_remessa": "1",
  "pagamentos": [
    {
      "valor": 100.00,
      "data_vencimento": "2026-01-15",
      "nosso_numero": "001",
      "documento_sacado": "12345678900",
      "nome_sacado": "Cliente",
      "endereco_sacado": "Rua Exemplo, 100",
      "bairro_sacado": "Centro",
      "cep_sacado": "00000000",
      "cidade_sacado": "Cidade",
      "uf_sacado": "UF",
      "codigo_chave_dict": "12345678000100",
      "tipo_chave_dict": "cnpj",
      "valor_maximo_pix": 100.00,
      "valor_minimo_pix": 100.00,
      "txid": "TXID20260115001"
    }
  ]
}
```

### Implementação no boleto_cnab_api

```ruby
desc 'Gera remessa CNAB com registro/segmento PIX'
params do
  requires :bank, type: String
  requires :formato, type: String, values: %w[cnab240 cnab400]
  requires :pagamentos, type: Array do
    requires :codigo_chave_dict, type: String
    requires :tipo_chave_dict, type: String,
             values: %w[cpf cnpj email telefone chave_aleatoria]
    # ... demais campos
  end
end
post 'remessa/pix' do
  pagamentos = params[:pagamentos].map do |p|
    Brcobranca::Remessa::PagamentoPix.new(p.to_h.symbolize_keys)
  end

  # Mapeia para classe PIX correta
  klass = resolve_pix_class(params[:bank], params[:formato])
  remessa = klass.new(params.except(:bank, :formato, :pagamentos).to_h.symbolize_keys.merge(pagamentos: pagamentos))

  content_type 'text/plain'
  remessa.gera_arquivo
end

# Helper
def resolve_pix_class(bank, formato)
  mapeamento = {
    'cnab400' => {
      'santander' => Brcobranca::Remessa::Cnab400::SantanderPix,
      'bradesco'  => Brcobranca::Remessa::Cnab400::BradescoPix,
      'itau'      => Brcobranca::Remessa::Cnab400::ItauPix,
      'banco_c6'  => Brcobranca::Remessa::Cnab400::BancoC6Pix,
      '336'       => Brcobranca::Remessa::Cnab400::BancoC6Pix
    },
    'cnab240' => {
      'banco_brasil' => Brcobranca::Remessa::Cnab240::BancoBrasilPix,
      'caixa'        => Brcobranca::Remessa::Cnab240::CaixaPix,
      'sicoob'       => Brcobranca::Remessa::Cnab240::SicoobPix
    }
  }
  mapeamento.dig(formato, bank) || raise('PIX não suportado para este banco/formato')
end
```

---

## 3. Sicoob Carteira 9

Nova modalidade 2024/2025 do Sicoob. Usa **Número do Contrato** em vez do
Código do Cedente no código de barras.

### Novo campo: `numero_contrato`

```ruby
boleto = Brcobranca::Boleto::Sicoob.new(
  # ... campos padrão
  carteira: '9',               # Carteira 9 ativa a nova composição
  numero_contrato: '1234567'   # Fornecido pelo Sicoob (até 7 dígitos)
)
```

### No boleto_cnab_api

Adicionar `numero_contrato` como parâmetro opcional para o Sicoob:

```ruby
params do
  optional :numero_contrato, type: String, regexp: /\A\d{1,7}\z/,
           desc: 'Número do Contrato Sicoob (obrigatório se carteira = 9)'
end
```

---

## 4. Sicoob layout 810

Opção alternativa onde o cliente já envia o DV do nosso número calculado.

### Novo campo: `versao_layout_arquivo_opcao`

```ruby
remessa = Brcobranca::Remessa::Cnab240::Sicoob.new(
  versao_layout_arquivo_opcao: '810',  # '081' (padrão) ou '810'
  # ... demais campos
)
```

### No boleto_cnab_api

```ruby
optional :versao_layout, type: String, values: %w[081 810],
         desc: 'Sicoob CNAB 240: 081 (padrão) ou 810 (cliente calcula DV)'
```

---

## 5. Template Prawn

Alternativa ao RGhost que **não requer GhostScript**. Útil para:
- Containers Alpine/Docker mínimos
- Ambientes serverless (Lambda, Cloud Run)
- Windows sem GhostScript instalado
- Reduzir tamanho da imagem Docker

### Dependências opcionais

Adicionar no `Gemfile` do `boleto_cnab_api`:

```ruby
group :prawn do
  gem 'prawn'
  gem 'prawn-table'
  gem 'barby'
  gem 'rqrcode'
  gem 'chunky_png'
end
```

### Uso via HTTP

```ruby
desc 'Gera PDF do boleto usando template Prawn (sem GhostScript)'
post 'boleto/prawn' do
  require 'brcobranca/boleto/template/prawn_bolepix'

  boleto = BoletoApi.get_boleto(params[:bank], params)
  boleto.extend(Brcobranca::Boleto::Template::PrawnBolepix)

  content_type 'application/pdf'
  boleto.to(:pdf)
end
```

### Ou por configuração global

```ruby
# config/initializers/brcobranca.rb
if ENV['BRCOBRANCA_GERADOR'] == 'prawn'
  require 'brcobranca/boleto/template/prawn_bolepix'
  Brcobranca.setup { |c| c.gerador = :prawn_bolepix }
end
```

---

## 6. API de Serialização

Todas as classes já suportam `to_hash`, `as_json`, `to_json`, `valido?`,
`to_hash_seguro` (desde v12.2.0-v12.5.0). O `boleto_cnab_api` deve sempre
usar esses métodos em vez de mapear campos manualmente.

### Antes (duplicação de código)

```ruby
get 'boleto/data' do
  boleto = BoletoApi.get_boleto(params[:bank], params)
  {
    codigo_barras: boleto.codigo_barras,
    linha_digitavel: boleto.linha_digitavel,
    nosso_numero: boleto.nosso_numero_boleto,
    # ... mais 10 campos manuais
  }
end
```

### Depois (usando API de serialização)

```ruby
get 'boleto/data' do
  boleto = BoletoApi.get_boleto(params[:bank], params)
  boleto.as_json(somente_calculados: true)
end

get 'boleto/hash' do
  boleto = BoletoApi.get_boleto(params[:bank], params)
  boleto.as_json  # dados de entrada + calculados
end

get 'boleto/seguro' do
  # Retorna com flag valid: true/false + errors
  BoletoApi.get_boleto(params[:bank], params).as_json_seguro
end
```

---

## 7. Endpoints novos sugeridos

| Método | Endpoint | Descrição | Classe usada |
|---|---|---|---|
| `POST` | `/api/remessa/pix` | Gera remessa com PIX | `*Pix` classes |
| `POST` | `/api/boleto/prawn` | PDF via Prawn (sem GS) | `PrawnBolepix` |
| `POST` | `/api/boleto/hybrid` | Boleto com QR Code PIX | `RghostBolepix` |
| `GET` | `/api/boleto/seguro` | Valida sem exceção | `to_hash_seguro` |
| `GET` | `/api/bancos` | Lista bancos suportados | `Remessa.bancos_disponiveis` |
| `GET` | `/api/bancos/suporta_pix` | Lista bancos com PIX | novo helper |

### Health check / metadata

```ruby
get '/api/metadata' do
  {
    brcobranca_version: Brcobranca::VERSION,
    bancos_suportados: Brcobranca::Remessa.bancos_disponiveis,
    formatos_remessa: Brcobranca::Remessa::FORMATOS,
    formatos_retorno: Brcobranca::Retorno::FORMATOS,
    prawn_disponivel: defined?(Brcobranca::Boleto::Template::PRAWN_AVAILABLE) &&
                      Brcobranca::Boleto::Template::PRAWN_AVAILABLE
  }
end
```

---

## 8. Checklist de migração

### Gemfile
- [ ] Atualizar versão do brcobranca para a nova (>= 12.7 com PR merged ou via `github:`)
- [ ] Adicionar gems opcionais (grupo `:prawn`) se usar template Prawn

### Endpoints novos
- [ ] `POST /api/remessa/pix` — remessa com PIX em 7 bancos
- [ ] `POST /api/boleto/prawn` — PDF sem GhostScript
- [ ] `GET /api/bancos` — lista bancos disponíveis
- [ ] `GET /api/metadata` — versão e recursos ativos

### Endpoints existentes (refatorar)
- [ ] `POST /api/boleto/data` — adicionar suporte ao `banco_c6`
- [ ] `POST /api/boleto/validate` — adicionar suporte ao `banco_c6`
- [ ] Aceitar parâmetros `numero_contrato` e `versao_layout_arquivo_opcao` para Sicoob

### Configuração do ambiente
- [ ] Dockerfile: opção de build sem GhostScript (usando Prawn)
- [ ] Variável de ambiente `BRCOBRANCA_GERADOR=prawn` para ativar Prawn global
- [ ] CI testando ambos os geradores (RGhost + Prawn)

### Documentação
- [ ] README do boleto_cnab_api: listar novo banco C6
- [ ] README: documentar novos endpoints PIX
- [ ] Swagger/OpenAPI: adicionar schemas dos novos endpoints
- [ ] Postman collection: incluir exemplos dos novos endpoints

### Testes
- [ ] Testes de integração para C6 Bank (CNAB 400)
- [ ] Testes para remessa PIX (7 bancos)
- [ ] Teste de geração via Prawn (sem GhostScript)
- [ ] Teste do Sicoob Carteira 9 com `numero_contrato`

---

## Referências

- [brcobranca GitHub](https://github.com/Maxwbh/brcobranca)
- [boleto_cnab_api GitHub](https://github.com/Maxwbh/boleto_cnab_api)
- [CHANGELOG brcobranca](../CHANGELOG.md)
- [API de Serialização](./api_referencia.md)
- [TODO Integração](./TODO_INTEGRACAO.md)

---

**Última atualização:** consulte o CHANGELOG para a versão mais recente.
