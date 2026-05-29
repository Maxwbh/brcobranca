# Integração com Rails

Guia completo para integrar o BRCobranca em uma aplicação Rails.

---

## 1. Setup

### Gemfile

```ruby
gem 'brcobranca'

# Opcional: para template Prawn (sem GhostScript)
gem 'prawn', '~> 2.4'
gem 'prawn-table', '~> 0.2'
gem 'barby', '~> 0.6'
gem 'rqrcode', '~> 2.0'
gem 'chunky_png', '~> 1.4'
```

### Initializer

```ruby
# config/initializers/brcobranca.rb

Brcobranca.setup do |config|
  config.gerador = :rghost_bolepix   # ou :rghost para boleto sem PIX
  config.formato = :pdf
  config.resolucao = 150
end
```

---

## 2. Controller de Boletos

```ruby
# app/controllers/boletos_controller.rb

class BoletosController < ApplicationController
  def show
    cobranca = Cobranca.find(params[:id])
    boleto = montar_boleto(cobranca)

    respond_to do |format|
      format.html
      format.pdf do
        send_data boleto.to(:pdf),
          filename: "boleto_#{boleto.nosso_numero}.pdf",
          type: 'application/pdf',
          disposition: 'inline'
      end
      format.json do
        render json: boleto.as_json
      end
    end
  end

  def lote
    cobrancas = Cobranca.where(id: params[:ids])
    boletos = cobrancas.map { |c| montar_boleto(c) }

    pdf = Brcobranca::Boleto::Base.lote(boletos, formato: :pdf)

    send_data pdf,
      filename: "boletos_lote.pdf",
      type: 'application/pdf',
      disposition: 'inline'
  end

  private

  def montar_boleto(cobranca)
    empresa = cobranca.empresa

    Brcobranca::Boleto::Sicoob.new(
      agencia: empresa.agencia,
      convenio: empresa.convenio,
      conta_corrente: empresa.conta_corrente,
      carteira: empresa.carteira,
      nosso_numero: cobranca.nosso_numero,
      valor: cobranca.valor,
      data_vencimento: cobranca.vencimento,
      cedente: empresa.razao_social,
      documento_cedente: empresa.cnpj,
      sacado: cobranca.cliente.nome,
      sacado_documento: cobranca.cliente.documento,
      sacado_endereco: cobranca.cliente.endereco_completo,
      # PIX
      chave_pix: empresa.chave_pix,
      tipo_chave_pix: empresa.tipo_chave_pix,
      txid: "TXID#{cobranca.id.to_s.rjust(15, '0')}",
      emv: cobranca.emv_pix
    )
  end
end
```

---

## 3. Controller de Remessa

```ruby
# app/controllers/remessas_controller.rb

class RemessasController < ApplicationController
  def create
    cobrancas = Cobranca.where(id: params[:cobranca_ids])
    empresa = current_empresa

    pagamentos = cobrancas.map do |c|
      klass = c.pix? ? Brcobranca::Remessa::PagamentoPix : Brcobranca::Remessa::Pagamento

      attrs = {
        valor: c.valor,
        data_vencimento: c.vencimento,
        nosso_numero: c.nosso_numero,
        documento_sacado: c.cliente.documento,
        nome_sacado: c.cliente.nome,
        endereco_sacado: c.cliente.endereco,
        bairro_sacado: c.cliente.bairro,
        cep_sacado: c.cliente.cep,
        cidade_sacado: c.cliente.cidade,
        uf_sacado: c.cliente.uf
      }

      if c.pix?
        attrs.merge!(
          codigo_chave_dict: empresa.chave_pix,
          tipo_chave_dict: empresa.tipo_chave_pix,
          txid: "TXID#{c.id.to_s.rjust(15, '0')}",
          valor_maximo_pix: c.valor,
          valor_minimo_pix: c.valor
        )
      end

      klass.new(attrs)
    end

    remessa = montar_remessa(empresa, pagamentos, pix: cobrancas.any?(&:pix?))
    arquivo = remessa.gera_arquivo

    send_data arquivo,
      filename: "remessa_#{Date.current.strftime('%Y%m%d')}.rem",
      type: 'text/plain',
      disposition: 'attachment'
  end

  private

  def montar_remessa(empresa, pagamentos, pix: false)
    klass = pix ? Brcobranca::Remessa::Cnab240::SicoobPix : Brcobranca::Remessa::Cnab240::Sicoob

    klass.new(
      empresa_mae: empresa.razao_social,
      agencia: empresa.agencia,
      conta_corrente: empresa.conta_corrente,
      digito_conta: empresa.digito_conta,
      documento_cedente: empresa.cnpj,
      convenio: empresa.convenio,
      modalidade_carteira: '01',
      tipo_formulario: '4',
      parcela: '01',
      pagamentos: pagamentos
    )
  end
end
```

---

## 4. Controller de Retorno

```ruby
# app/controllers/retornos_controller.rb

class RetornosController < ApplicationController
  def create
    arquivo = params[:arquivo]

    unless arquivo
      render json: { error: 'Arquivo obrigatorio' }, status: :bad_request
      return
    end

    registros = Brcobranca::Retorno.parse(arquivo.tempfile.path)

    resultados = registros.map do |r|
      cobranca = Cobranca.find_by(nosso_numero: r.nosso_numero)
      next unless cobranca

      cobranca.update!(
        status: mapear_ocorrencia(r.codigo_ocorrencia),
        valor_pago: r.valor_recebido,
        data_pagamento: r.data_credito
      )

      { nosso_numero: r.nosso_numero, status: cobranca.status }
    end.compact

    render json: { processados: resultados.size, registros: resultados }
  end

  private

  def mapear_ocorrencia(codigo)
    case codigo.to_s
    when '06' then :liquidado
    when '09' then :baixado
    when '02' then :confirmado
    else :pendente
    end
  end
end
```

---

## 5. Endpoint de descoberta de bancos

```ruby
# app/controllers/api/bancos_controller.rb

module Api
  class BancosController < ApplicationController
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
  end
end
```

---

## 6. Routes

```ruby
# config/routes.rb

Rails.application.routes.draw do
  resources :boletos, only: [:show] do
    collection do
      post :lote
    end
  end

  resources :remessas, only: [:create]
  resources :retornos, only: [:create]

  namespace :api do
    resources :bancos, only: %i[index show] do
      collection do
        get :com_pix
        get :com_remessa
      end
    end
  end
end
```

---

## 7. Respostas típicas da API

```
GET /boletos/123.json
→ { "cedente": "...", "codigo_barras": "...", "pix": { "chave_pix": "...", ... } }

GET /api/bancos
→ { "total_bancos": 18, "total_com_pix": 7, "bancos": [...] }

GET /api/bancos/756
→ { "codigo": "756", "nome": "Sicoob", "carteiras": ["1","3","9"], ... }

GET /api/bancos/com_pix
→ { "bancos": [{ "codigo": "001", ... }, ...] }

POST /remessas
→ Download do arquivo .rem

POST /retornos (upload do .ret)
→ { "processados": 5, "registros": [...] }
```

---

## Próximos passos

- [[Integração com Gestão de Contratos]] — fluxo completo
- [[Configuração PIX]] — detalhes dos campos PIX
- [[FAQ e Troubleshooting]] — erros comuns
