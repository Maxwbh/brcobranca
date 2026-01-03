# API de Serialização - Referência Completa

> **Versão:** 12.5.0
> **Autor:** Maxwell Oliveira (@maxwbh) - M&S do Brasil LTDA

Este documento descreve a API de serialização do BRCobranca, que permite extrair dados de boletos, remessas e retornos em formatos estruturados (Hash, JSON).

---

## Índice

1. [Boleto API](#boleto-api)
2. [Remessa API](#remessa-api)
3. [Retorno API](#retorno-api)
4. [Tratamento de Erros](#tratamento-de-erros)
5. [Integração REST](#integração-rest)

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
| `dados_pix` | Dados PIX/EMV | 12.2.0 |
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

#### Dados PIX

```ruby
boleto = Brcobranca::Boleto::Sicoob.new(
  # ... outros campos ...
  emv: '00020126580014br.gov.bcb.pix...'
)

boleto.dados_pix
#=> {
#     emv: '00020126580014br.gov.bcb.pix...',
#     qrcode_pix: 'data:image/png;base64,...'
#   }
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

---

## Links

- [GitHub](https://github.com/Maxwbh/brcobranca)
- [CHANGELOG](../CHANGELOG.md)
- [Guia de Início Rápido](getting-started/quick-start.md)
- [Campos por Banco](banks/fields-reference.md)

---

**Mantido por:** Maxwell Oliveira (@maxwbh) - M&S do Brasil LTDA
**Website:** [www.msbrasil.inf.br](https://www.msbrasil.inf.br)
