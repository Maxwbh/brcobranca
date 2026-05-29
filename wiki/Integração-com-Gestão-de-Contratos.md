# Integração com Gestão de Contratos

Este guia mostra como integrar o BRCobranca com um sistema de gestão de contratos,
onde cada contrato gera cobranças (boletos) com suporte a PIX.

---

## Fluxo geral

```
Empresa (cadastro)
  ├── dados bancários (agência, conta, convênio)
  ├── chave PIX (chave_pix, tipo_chave_pix)
  │
  └── Contrato
        ├── dados do cliente (sacado)
        ├── valor, vencimento, parcelas
        │
        └── Cobrança (por parcela)
              ├── nosso_numero (gerado)
              ├── txid (gerado)
              │
              ├── Boleto (PDF)  ←── BRCobranca
              │     └── chave_pix + emv → QR Code
              │
              ├── Remessa (CNAB) ←── BRCobranca
              │     └── PagamentoPix com chave DICT
              │
              └── Retorno (CNAB) ←── BRCobranca
                    └── Atualiza status da cobrança
```

---

## 1. Modelo de dados sugerido

```ruby
# == Empresa ==
# agencia, conta_corrente, digito_conta, convenio, carteira
# chave_pix, tipo_chave_pix, banco_codigo
# razao_social, cnpj

# == Contrato ==
# empresa_id, cliente_id
# valor_total, quantidade_parcelas, dia_vencimento

# == Cobrança (parcela) ==
# contrato_id, parcela_numero
# nosso_numero, valor, vencimento, status
# txid, emv_pix (gerado)

# == Cliente (sacado) ==
# nome, documento (CPF/CNPJ), endereco, bairro, cep, cidade, uf
```

---

## 2. Gerar cobrança a partir do contrato

```ruby
# app/services/gerar_cobrancas_service.rb

class GerarCobrancasService
  def initialize(contrato)
    @contrato = contrato
    @empresa = contrato.empresa
  end

  def call
    (1..@contrato.quantidade_parcelas).map do |parcela|
      vencimento = calcular_vencimento(parcela)
      nosso_numero = gerar_nosso_numero(parcela)

      @contrato.cobrancas.create!(
        parcela_numero: parcela,
        nosso_numero: nosso_numero,
        valor: @contrato.valor_parcela,
        vencimento: vencimento,
        txid: gerar_txid(nosso_numero),
        status: :pendente
      )
    end
  end

  private

  def calcular_vencimento(parcela)
    Date.new(
      Date.current.year,
      Date.current.month,
      @contrato.dia_vencimento
    ) + parcela.months
  end

  def gerar_nosso_numero(parcela)
    "#{@contrato.id}#{parcela}".rjust(7, '0')
  end

  def gerar_txid(nosso_numero)
    "TXID#{@empresa.id}#{nosso_numero}".ljust(25, '0')
  end
end
```

---

## 3. Montar boleto a partir da cobrança

```ruby
# app/services/montar_boleto_service.rb

class MontarBoletoService
  CLASSE_BOLETO = {
    '756' => Brcobranca::Boleto::Sicoob,
    '237' => Brcobranca::Boleto::Bradesco,
    '341' => Brcobranca::Boleto::Itau,
    '033' => Brcobranca::Boleto::Santander,
    '336' => Brcobranca::Boleto::BancoC6,
    '001' => Brcobranca::Boleto::BancoBrasil,
    '104' => Brcobranca::Boleto::Caixa
  }.freeze

  def initialize(cobranca)
    @cobranca = cobranca
    @empresa = cobranca.contrato.empresa
    @cliente = cobranca.contrato.cliente
  end

  def call
    klass = CLASSE_BOLETO[@empresa.banco_codigo]
    raise "Banco #{@empresa.banco_codigo} nao suportado" unless klass

    klass.new(
      # Dados do banco
      agencia: @empresa.agencia,
      conta_corrente: @empresa.conta_corrente,
      convenio: @empresa.convenio,
      carteira: @empresa.carteira,

      # Dados do título
      nosso_numero: @cobranca.nosso_numero,
      valor: @cobranca.valor,
      data_vencimento: @cobranca.vencimento,
      data_documento: Date.current,

      # Beneficiário
      cedente: @empresa.razao_social,
      documento_cedente: @empresa.cnpj,

      # Pagador
      sacado: @cliente.nome,
      sacado_documento: @cliente.documento,
      sacado_endereco: @cliente.endereco_completo,

      # PIX (mesma fonte para boleto e remessa)
      chave_pix: @empresa.chave_pix,
      tipo_chave_pix: @empresa.tipo_chave_pix,
      txid: @cobranca.txid,
      emv: @cobranca.emv_pix
    )
  end
end
```

### Uso no controller

```ruby
boleto = MontarBoletoService.new(cobranca).call

# PDF
send_data boleto.to(:pdf), filename: "boleto_#{cobranca.nosso_numero}.pdf"

# JSON para API
render json: boleto.as_json

# Dados PIX para exibir na tela
boleto.dados_pix
# => { chave_pix: '...', tipo_chave_pix: 'cnpj', txid: '...', qrcode_disponivel: true }
```

---

## 4. Gerar remessa do lote de cobranças

```ruby
# app/services/gerar_remessa_service.rb

class GerarRemessaService
  CLASSE_REMESSA = {
    '756' => { padrao: Brcobranca::Remessa::Cnab240::Sicoob,
               pix: Brcobranca::Remessa::Cnab240::SicoobPix },
    '237' => { padrao: Brcobranca::Remessa::Cnab400::Bradesco,
               pix: Brcobranca::Remessa::Cnab400::BradescoPix },
    '341' => { padrao: Brcobranca::Remessa::Cnab400::Itau,
               pix: Brcobranca::Remessa::Cnab400::ItauPix },
    '336' => { padrao: Brcobranca::Remessa::Cnab400::BancoC6,
               pix: Brcobranca::Remessa::Cnab400::BancoC6Pix }
  }.freeze

  def initialize(cobrancas, com_pix: false)
    @cobrancas = cobrancas
    @empresa = cobrancas.first.contrato.empresa
    @com_pix = com_pix
  end

  def call
    pagamentos = @cobrancas.map { |c| montar_pagamento(c) }
    remessa = montar_remessa(pagamentos)
    remessa.gera_arquivo
  end

  private

  def montar_pagamento(cobranca)
    cliente = cobranca.contrato.cliente

    attrs = {
      valor: cobranca.valor,
      data_vencimento: cobranca.vencimento,
      nosso_numero: cobranca.nosso_numero,
      documento_sacado: cliente.documento,
      nome_sacado: cliente.nome,
      endereco_sacado: cliente.endereco,
      bairro_sacado: cliente.bairro,
      cep_sacado: cliente.cep,
      cidade_sacado: cliente.cidade,
      uf_sacado: cliente.uf
    }

    if @com_pix
      attrs.merge!(
        codigo_chave_dict: @empresa.chave_pix,
        tipo_chave_dict: @empresa.tipo_chave_pix,
        txid: cobranca.txid,
        valor_maximo_pix: cobranca.valor,
        valor_minimo_pix: cobranca.valor
      )
      Brcobranca::Remessa::PagamentoPix.new(attrs)
    else
      Brcobranca::Remessa::Pagamento.new(attrs)
    end
  end

  def montar_remessa(pagamentos)
    config = CLASSE_REMESSA[@empresa.banco_codigo]
    klass = @com_pix ? config[:pix] : config[:padrao]

    klass.new(
      empresa_mae: @empresa.razao_social,
      agencia: @empresa.agencia,
      conta_corrente: @empresa.conta_corrente,
      digito_conta: @empresa.digito_conta,
      documento_cedente: @empresa.cnpj,
      convenio: @empresa.convenio,
      pagamentos: pagamentos
    )
  end
end
```

### Uso

```ruby
# Cobranças pendentes do mês
cobrancas = Cobranca.pendentes.do_mes(Date.current)

# Gerar remessa com PIX
arquivo = GerarRemessaService.new(cobrancas, com_pix: true).call

# Salvar / enviar ao banco
File.write("remessa_#{Date.current.strftime('%Y%m%d')}.rem", arquivo)

# Atualizar status
cobrancas.update_all(status: :enviado_banco)
```

---

## 5. Processar retorno do banco

```ruby
# app/services/processar_retorno_service.rb

class ProcessarRetornoService
  MAPA_OCORRENCIA = {
    '02' => :confirmado,
    '06' => :liquidado,
    '09' => :baixado,
    '10' => :baixado_banco
  }.freeze

  def initialize(arquivo_path)
    @registros = Brcobranca::Retorno.parse(arquivo_path)
  end

  def call
    resultados = { processados: 0, erros: [] }

    @registros.each do |registro|
      cobranca = Cobranca.find_by(nosso_numero: registro.nosso_numero)

      unless cobranca
        resultados[:erros] << "Nosso numero #{registro.nosso_numero} nao encontrado"
        next
      end

      novo_status = MAPA_OCORRENCIA[registro.codigo_ocorrencia.to_s] || :pendente

      cobranca.update!(
        status: novo_status,
        valor_pago: registro.valor_recebido,
        data_pagamento: registro.data_credito,
        data_processamento_retorno: Date.current
      )

      resultados[:processados] += 1
    end

    resultados
  end
end
```

---

## 6. Fluxo completo (resumo)

```ruby
# 1. Criar contrato → gera cobranças
contrato = Contrato.create!(empresa: empresa, cliente: cliente, ...)
GerarCobrancasService.new(contrato).call

# 2. Gerar boletos (PDF ou JSON)
cobranca = contrato.cobrancas.first
boleto = MontarBoletoService.new(cobranca).call
boleto.to(:pdf)   # PDF com QR Code PIX
boleto.to_json    # JSON para API / tela

# 3. Gerar remessa (enviar ao banco)
cobrancas_do_dia = Cobranca.pendentes.vencendo_em(30.days)
arquivo = GerarRemessaService.new(cobrancas_do_dia, com_pix: true).call

# 4. Processar retorno (receber do banco)
resultado = ProcessarRetornoService.new('retorno.ret').call
puts "#{resultado[:processados]} cobranças atualizadas"
```

---

## Dados PIX — fonte única

O ponto central é que **a chave PIX vem do cadastro da empresa** e flui para ambos os lados:

```
Empresa.chave_pix ──┬── Boleto.chave_pix (dados_pix / to_hash)
                    └── PagamentoPix.codigo_chave_dict (remessa CNAB)
```

Isso garante consistência: o mesmo CNPJ/CPF/email aparece no boleto (para o cliente) e na remessa (para o banco).

---

## Próximos passos

- [[Configuração PIX]] — detalhes de cada campo PIX
- [[Bancos Suportados]] — verificar suporte do seu banco
- [[Integração com Rails]] — controllers e rotas
