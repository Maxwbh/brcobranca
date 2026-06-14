# API de Serialização - Referência Completa

> **Disponível desde:** v12.2.0 (Boleto) / v12.3.0 (validação segura) / v12.4.0 (Remessa) / v12.5.0 (Retorno)
> **Mantenedor do fork:** Maxwell Oliveira (@maxwbh) — M&S do Brasil LTDA

Este documento descreve a API de serialização do BRCobranca, que permite extrair dados de boletos, remessas e retornos em formatos estruturados (Hash, JSON) — ideal para integração com APIs REST.

---

## Índice

1. [Boleto API](#boleto-api)
2. [Remessa API](#remessa-api)
3. [Retorno API](#retorno-api)
4. [API de Bancos](#api-de-bancos)
5. [Tratamento de Erros](#tratamento-de-erros)
6. [Integração REST](#integração-rest)

---

## Boleto API

### Métodos Disponíveis

| Método | Descrição | Versão |
|--------|-----------|--------|
| `to_hash` | Retorna todos os dados como Hash | 12.2.0 |
| `as_json` | Hash com chaves string | 12.2.0 |
| `to_json` | String JSON | 12.2.0 |
| `dados_entrada` | Campos informados pelo usuário | 12.2.0 |
| `dados_calculados` | Campos gerados (código de barras, etc) | 12.2.0 |
| `banco_nome` | Nome do banco | 12.2.0 |
| `dados_pix` | Dados PIX (chave, tipo, txid, emv, qrcode) | 12.2.0 |
| `valido?` | Validação sem exceção | 12.3.0 |
| `to_hash_seguro` | Hash com status de validação | 12.3.0 |
| `as_json_seguro` | JSON-ready com validação | 12.3.0 |
| `to_json_seguro` | JSON string com validação | 12.3.0 |

### Exemplos

#### Criação e Serialização Básica

```ruby
require 'brcobranca'

# Criar boleto
boleto = Brcobranca::Boleto::Sicoob.new(
  cedente: 'Empresa LTDA',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Exemplo',
  sacado_documento: '12345678901',
  valor: 100.50,
  agencia: '1234',
  conta_corrente: '12345',
  convenio: '123456',
  nosso_numero: '00001'
)

# Todos os dados
boleto.to_hash
#=> {
#     cedente: 'Empresa LTDA',
#     documento_cedente: '12345678000190',
#     valor: 100.50,
#     codigo_barras: '75691234567890123456789012345678901234567890',
#     linha_digitavel: '75691.23456 78901.234567 89012.345678 9 01234567890123',
#     nosso_numero_boleto: '1234/00001-5',
#     ...
#   }

# Apenas dados calculados (para APIs)
boleto.to_hash(somente_calculados: true)
#=> {
#     banco: '756',
#     banco_dv: '0',
#     codigo_barras: '75691234...',
#     linha_digitavel: '75691.23456...',
#     nosso_numero_boleto: '1234/00001-5',
#     nosso_numero_dv: '5'
#   }

# JSON para APIs REST
boleto.to_json
#=> '{"cedente":"Empresa LTDA","codigo_barras":"75691234...",...}'
```

#### Boleto com dados PIX

```ruby
boleto = Brcobranca::Boleto::Sicoob.new(
  # ... campos obrigatórios
  chave_pix: '12345678000100',
  tipo_chave_pix: 'cnpj',
  txid: 'TXID20260528001',
  emv: '00020126580014br.gov.bcb.pix...'  # opcional, para QR Code
)

boleto.dados_pix
#=> {
#     emv: '00020126580014br.gov.bcb.pix...',
#     chave_pix: '12345678000100',
#     tipo_chave_pix: 'cnpj',
#     txid: 'TXID20260528001',
#     qrcode_disponivel: true
#   }

# to_hash inclui os campos PIX em dois níveis:
hash = boleto.to_hash
hash[:chave_pix]         #=> '12345678000100'  (dados_entrada)
hash[:pix][:chave_pix]   #=> '12345678000100'  (dados_calculados)
hash[:pix][:txid]        #=> 'TXID20260528001'

# Sem EMV, apenas chave_pix — qrcode_disponivel fica false
boleto_sem_emv = Brcobranca::Boleto::Sicoob.new(
  # ... campos obrigatórios
  chave_pix: '12345678000100',
  tipo_chave_pix: 'cnpj'
)
boleto_sem_emv.dados_pix[:qrcode_disponivel] #=> false
```

#### Validação Segura (sem exceções)

```ruby
boleto = Brcobranca::Boleto::Sicoob.new # Boleto inválido

# Método tradicional (lança exceção)
begin
  boleto.codigo_barras
rescue Brcobranca::BoletoInvalido => e
  puts e.message
end

# Método seguro (nunca lança exceção)
if boleto.valido?
  processar(boleto)
else
  tratar_erros(boleto.errors.full_messages)
end

# Hash com status de validação
resultado = boleto.to_hash_seguro
#=> {
#     valid: false,
#     errors: ['Cedente não pode estar em branco', 'Agencia não pode estar em branco'],
#     cedente: nil,
#     agencia: nil,
#     ...
#   }

# Para APIs REST
render json: boleto.as_json_seguro
```

---

## Remessa API

### Métodos Disponíveis

#### Pagamento

| Método | Descrição |
|--------|-----------|
| `to_hash` | Todos os atributos do pagamento |
| `as_json` | Hash com chaves string |
| `to_json` | String JSON |
| `valido?` | Validação sem exceção |
| `to_hash_seguro` | Hash com status de validação |

#### Remessa::Base

| Método | Descrição |
|--------|-----------|
| `dados_entrada` | Atributos de entrada |
| `dados_calculados` | Quantidade e valor total |
| `to_hash` | Todos os dados com pagamentos |
| `as_json` | Hash com chaves string |
| `to_json` | String JSON |
| `valido?` | Validação sem exceção |
| `to_hash_seguro` | Hash com status de validação |

### Factory Method

```ruby
# Criação simplificada por banco e formato
remessa = Brcobranca::Remessa.criar(
  banco: :sicoob,        # ou '756'
  formato: :cnab400,     # :cnab240, :cnab400, :cnab444
  empresa_mae: 'Empresa LTDA',
  agencia: '1234',
  conta_corrente: '12345',
  convenio: '123456',
  pagamentos: [pagamento1, pagamento2]
)

# Verificar bancos disponíveis
Brcobranca::Remessa.bancos_disponiveis
#=> ['001', '033', '041', '085', '097', '104', ...]

# Verificar suporte
Brcobranca::Remessa.suporta?(banco: :sicoob, formato: :cnab400)
#=> true

Brcobranca::Remessa.suporta?(banco: :caixa, formato: :cnab400)
#=> false (Caixa só suporta CNAB240)
```

### Exemplos

```ruby
# Criar pagamento
pagamento = Brcobranca::Remessa::Pagamento.new(
  nosso_numero: '00001',
  data_vencimento: Date.parse('2025-12-31'),
  valor: 100.50,
  documento_sacado: '12345678901',
  nome_sacado: 'Cliente Exemplo',
  endereco_sacado: 'Rua Teste, 123',
  bairro_sacado: 'Centro',
  cep_sacado: '12345678',
  cidade_sacado: 'São Paulo',
  uf_sacado: 'SP'
)

# Serializar pagamento
pagamento.to_hash
#=> { nosso_numero: '00001', valor: 100.50, nome_sacado: 'Cliente', ... }

# Validação segura
pagamento.to_hash_seguro
#=> { valid: true, errors: [], nosso_numero: '00001', ... }

# Criar remessa
remessa = Brcobranca::Remessa.criar(
  banco: :sicoob,
  formato: :cnab400,
  empresa_mae: 'Empresa LTDA',
  convenio: '123456',
  agencia: '1234',
  conta_corrente: '12345',
  pagamentos: [pagamento]
)

# Serializar remessa com pagamentos
remessa.to_hash
#=> {
#     empresa_mae: 'Empresa LTDA',
#     quantidade_titulos: 1,
#     valor_total: 100.50,
#     pagamentos: [{ nosso_numero: '00001', ... }]
#   }

# Excluir pagamentos da serialização
remessa.to_hash(incluir_pagamentos: false)
```

---

## Retorno API

### Métodos Disponíveis

#### Retorno::Base

| Método | Descrição |
|--------|-----------|
| `to_hash` | Todos os atributos do registro |
| `as_json` | Hash com chaves string |
| `to_json` | String JSON |
| `dados_titulo` | Nosso número, documento, valor, vencimento |
| `dados_recebimento` | Valor recebido, crédito, juros, desconto |
| `dados_ocorrencia` | Código, motivo, data, sequencial |
| `dados_bancarios` | Agência, cedente, banco recebedor |
| `dados_pix` | Tipo chave, código, txid (quando disponível) |

#### Factory Method

| Método | Descrição |
|--------|-----------|
| `Retorno.parse` | Processa arquivo e retorna Hash serializado |
| `Retorno.load_lines` | Carrega registros como objetos |
| `Retorno.detectar_formato` | Auto-detecta CNAB240/400/CBR643 |
| `Retorno.detectar_banco` | Extrai código do banco do header |
| `Retorno.formato_valido?` | Verifica se arquivo é válido |

### Exemplos

```ruby
# Processamento com auto-detecção completa
resultado = Brcobranca::Retorno.parse('retorno.ret')
#=> {
#     formato: :cnab400,
#     banco: '237',
#     total_registros: 10,
#     registros: [
#       { nosso_numero: '12345', valor_recebido: '10050', ... },
#       { nosso_numero: '12346', valor_recebido: '20000', ... },
#       ...
#     ]
#   }

# Com formato explícito
resultado = Brcobranca::Retorno.parse('retorno.ret', formato: :cnab240)

# Carregar como objetos (para processamento avançado)
registros = Brcobranca::Retorno.load_lines('retorno.ret')
registros.each do |registro|
  puts registro.dados_titulo
  #=> { nosso_numero: '12345', valor_titulo: '10000', ... }

  puts registro.dados_recebimento
  #=> { valor_recebido: '10050', data_credito: '021226', ... }
end

# Detectar formato antes de processar
formato = Brcobranca::Retorno.detectar_formato('arquivo.ret')
#=> :cnab400

banco = Brcobranca::Retorno.detectar_banco('arquivo.ret')
#=> '237' (Bradesco)

# Verificar validade
if Brcobranca::Retorno.formato_valido?('arquivo.ret')
  processar(arquivo)
end
```

---

## API de Bancos

> **Disponível desde:** v12.6.0

O módulo `Brcobranca::Bancos` é um registro central com os metadados dos 18 bancos suportados — uma fonte única de verdade sobre quais bancos, CNAB e PIX estão implementados. Projetado para alimentar endpoints de descoberta em APIs REST.

### Métodos Disponíveis

| Método | Retorno | Descrição |
|--------|---------|-----------|
| `Bancos.todos` | `Array<Hash>` | Todos os bancos do registro |
| `Bancos.find(codigo)` | `Hash, nil` | Banco por código (string `"756"`) |
| `Bancos.codigos` | `Array<String>` | Apenas os códigos |
| `Bancos.com_boleto` | `Array<Hash>` | Bancos com suporte a boleto |
| `Bancos.com_remessa(formato=nil)` | `Array<Hash>` | Bancos com remessa (opcional: `"240"`, `"400"`, `"444"`) |
| `Bancos.com_retorno(formato=nil)` | `Array<Hash>` | Bancos com retorno |
| `Bancos.com_pix` | `Array<Hash>` | 7 bancos com PIX em remessa |
| `Bancos.formatos_cnab` | `Array<String>` | Formatos CNAB disponíveis (`["240","400","444"]`) |
| `Bancos.classe_boleto(codigo)` | `Class, nil` | Classe de boleto resolvida (ex.: `Brcobranca::Boleto::Sicoob`) |
| `Bancos.classe_remessa(codigo, formato)` | `Class, nil` | Classe de remessa por formato |
| `Bancos.classe_retorno(codigo, formato)` | `Class, nil` | Classe de retorno por formato |
| `Bancos.classe_pix(codigo, formato)` | `Class, nil` | Classe de remessa PIX por formato |
| `Bancos.registrar(banco)` | `Hash` | Registra banco custom em runtime (requer `:codigo` e `:nome`) |
| `Bancos.remover(codigo)` | `Boolean` | Remove banco custom registrado |
| `Bancos.as_json` | `Hash` | Hash pronto para serialização JSON |
| `Bancos.to_json` | `String` | String JSON |

#### Resolução de classes e registro custom

```ruby
# Resolver a classe a partir do código (útil para factory dinâmico)
Brcobranca::Bancos.classe_boleto('756')          #=> Brcobranca::Boleto::Sicoob
Brcobranca::Bancos.classe_remessa('237', '400')  #=> Brcobranca::Remessa::Cnab400::Bradesco
Brcobranca::Bancos.classe_retorno('237', '400')  #=> Brcobranca::Retorno::Cnab400::Bradesco
Brcobranca::Bancos.classe_pix('756', '240')      #=> Brcobranca::Remessa::Cnab240::SicoobPix

# Registrar um banco custom (não altera os 18 built-in)
Brcobranca::Bancos.registrar(
  codigo: '999', nome: 'Banco Custom', boleto: 'BancoCustom',
  cnab: { '400' => { remessa: 'Cnab400::BancoCustom', retorno: nil } }
)
Brcobranca::Bancos.find('999')[:nome]  #=> "Banco Custom"
Brcobranca::Bancos.remover('999')      #=> true
```

### Estrutura de um banco

```ruby
Brcobranca::Bancos.find("756")
# =>
# {
#   codigo: "756",
#   nome: "Sicoob",
#   boleto: "Sicoob",                                     # nome da classe Boleto
#   cnab: {
#     "240" => { remessa: "Cnab240::Sicoob",
#                retorno: "Cnab240::Sicoob" },
#     "400" => { remessa: "Cnab400::Sicoob",
#                retorno: nil }                            # formato suportado apenas para envio
#   },
#   pix: { "240" => "Cnab240::SicoobPix" },                # classes PIX disponíveis
#   carteiras: ["1", "3", "9"],
#   extras: {                                              # notas específicas do banco
#     carteira_9: "Usa numero_contrato no codigo de barras",
#     layout_810: "Versao alternativa CNAB 240 (cliente calcula DV)"
#   }
# }
```

### Exemplos

#### Listar todos os bancos

```ruby
Brcobranca::Bancos.todos.each do |banco|
  puts "#{banco[:codigo]} - #{banco[:nome]}"
end
# 001 - Banco do Brasil
# 004 - Banco do Nordeste
# ... (18 bancos)
```

#### Filtrar por capacidade

```ruby
# Bancos com PIX (7)
Brcobranca::Bancos.com_pix.map { |b| b[:codigo] }
#=> ["001", "033", "104", "237", "336", "341", "756"]

# Bancos com CNAB 240 (remessa)
Brcobranca::Bancos.com_remessa("240").map { |b| b[:codigo] }
#=> ["001", "085", "104", "136", "756", "748"]

# Bancos com retorno CNAB 400
Brcobranca::Bancos.com_retorno("400").map { |b| b[:codigo] }
```

#### Serialização JSON (para API REST)

```ruby
Brcobranca::Bancos.as_json
# =>
# {
#   total_bancos: 18,
#   total_com_remessa: 14,
#   total_com_retorno: 12,
#   total_com_pix: 7,
#   formatos_cnab: ["240", "400", "444"],
#   bancos: [
#     {
#       codigo: "756",
#       nome: "Sicoob",
#       boleto: true,
#       cnab: [
#         { formato: "240", remessa: true, retorno: true },
#         { formato: "400", remessa: true, retorno: false }
#       ],
#       pix: [{ formato: "240" }],
#       carteiras: ["1", "3", "9"],
#       extras: { carteira_9: "...", layout_810: "..." }
#     },
#     ...
#   ]
# }

Brcobranca::Bancos.to_json
# => '{"total_bancos":18,"total_com_remessa":14,...}'
```

### Endpoints sugeridos (Rails)

```ruby
# config/routes.rb
namespace :api do
  resources :bancos, only: %i[index show] do
    collection do
      get :com_pix
      get :com_remessa
      get :formatos_cnab
    end
  end
end

# app/controllers/api/bancos_controller.rb
class Api::BancosController < ApplicationController
  def index
    render json: Brcobranca::Bancos.as_json
  end

  def show
    banco = Brcobranca::Bancos.find(params[:id])
    banco ? render(json: banco) : head(:not_found)
  end

  def com_pix
    render json: { bancos: Brcobranca::Bancos.com_pix }
  end

  def com_remessa
    render json: { bancos: Brcobranca::Bancos.com_remessa(params[:formato]) }
  end

  def formatos_cnab
    render json: { formatos: Brcobranca::Bancos.formatos_cnab }
  end
end
```

Respostas típicas:

```
GET /api/bancos            → { total_bancos: 18, bancos: [...] }
GET /api/bancos/756        → { codigo: "756", nome: "Sicoob", ... }
GET /api/bancos/com_pix    → { bancos: [7 bancos com PIX] }
GET /api/bancos/com_remessa?formato=240 → { bancos: [bancos com CNAB 240] }
```

---

## Tratamento de Erros

### Classe Errors

```ruby
boleto = Brcobranca::Boleto::Sicoob.new
boleto.valid? # false

# Hash de erros
boleto.errors.to_hash
#=> { cedente: ['não pode estar em branco'], agencia: ['não pode estar em branco'] }

# JSON
boleto.errors.as_json
#=> { 'cedente' => ['não pode estar em branco'], 'agencia' => ['não pode estar em branco'] }

# Verificar existência
boleto.errors.any?   #=> true
boleto.errors.empty? #=> false

# Primeiro erro de cada campo
boleto.errors.first_messages
#=> { cedente: 'não pode estar em branco', agencia: 'não pode estar em branco' }

# Limpar erros
boleto.errors.clear

# Combinar erros
boleto.errors.merge!(outro_boleto.errors)
```

---

## Integração REST

### Exemplo com Sinatra

```ruby
require 'sinatra'
require 'json'
require 'brcobranca'

# Gerar boleto
post '/api/boleto' do
  content_type :json

  boleto = Brcobranca::Boleto::Sicoob.new(
    cedente: params[:cedente],
    # ... outros campos
  )

  # Retorna com validação
  boleto.as_json_seguro.to_json
end

# Processar retorno
post '/api/retorno' do
  content_type :json

  arquivo = params[:file][:tempfile]
  resultado = Brcobranca::Retorno.parse(arquivo.path)

  resultado.to_json
end

# Criar remessa
post '/api/remessa' do
  content_type :json

  pagamentos = params[:pagamentos].map do |p|
    Brcobranca::Remessa::Pagamento.new(p)
  end

  remessa = Brcobranca::Remessa.criar(
    banco: params[:banco],
    formato: params[:formato].to_sym,
    pagamentos: pagamentos,
    # ... outros campos
  )

  remessa.as_json_seguro.to_json
end
```

### Exemplo com Rails

```ruby
# app/controllers/boletos_controller.rb
class BoletosController < ApplicationController
  def create
    boleto = Brcobranca::Boleto::Sicoob.new(boleto_params)

    if boleto.valido?
      render json: boleto.as_json
    else
      render json: boleto.as_json_seguro, status: :unprocessable_entity
    end
  end

  def dados
    boleto = Brcobranca::Boleto::Sicoob.new(boleto_params)
    render json: boleto.as_json(somente_calculados: true)
  end

  private

  def boleto_params
    params.require(:boleto).permit(:cedente, :sacado, :valor, ...)
  end
end

# app/controllers/retornos_controller.rb
class RetornosController < ApplicationController
  def create
    arquivo = params[:arquivo]
    resultado = Brcobranca::Retorno.parse(arquivo.tempfile.path)

    render json: resultado
  end
end
```

---

## Versões

| Versão | Recursos |
|--------|----------|
| 12.2.0 | Boleto API (to_hash, as_json, to_json, dados_entrada, dados_calculados) |
| 12.3.0 | Validação segura (valido?, to_hash_seguro), melhorias em Errors |
| 12.4.0 | Remessa API (Pagamento#to_hash, Remessa::Base#to_hash, Factory Remessa.criar) |
| 12.5.0 | Retorno API (Retorno::Base#to_hash, Factory Retorno.parse, auto-detecção) |
| 12.6.0 | API de Bancos (`Brcobranca::Bancos` — registro central, `todos/find/com_pix/as_json`) |
| 12.8.0 | Campos PIX no boleto (`chave_pix`, `tipo_chave_pix`, `txid`); `dados_pix` expandido |
| 12.10.x | `Bancos.classe_boleto/remessa/retorno/pix` + `Bancos.registrar/remover` |

---

## Links

- [GitHub](https://github.com/Maxwbh/brcobranca)
- [CHANGELOG](../CHANGELOG.md)
- [Guia de Início Rápido](guia_rapido.md)
- [Campos por Banco](campos_por_banco.md)

---

**Mantido por:** Maxwell Oliveira (@maxwbh) - M&S do Brasil LTDA
**Website:** [www.msbrasil.inf.br](https://www.msbrasil.inf.br)
