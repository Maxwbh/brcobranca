# frozen_string_literal: true

module Brcobranca
  module Retorno
    # Classe base para retornos bancários
    #
    # Esta classe define todos os atributos comuns aos arquivos de retorno
    # bancário nos formatos CNAB 240 e CNAB 400.
    class Base
      # Identificação do registro e sequencial
      attr_accessor :codigo_registro, :sequencial, :arquivo

      # Dados da agência e conta
      attr_accessor :agencia_com_dv, :agencia_sem_dv, :cedente_com_dv, :convenio

      # Dados do título
      attr_accessor :nosso_numero, :documento_numero, :carteira, :carteira_variacao
      attr_accessor :especie_documento, :valor_titulo

      # Dados de cobrança
      attr_accessor :tipo_cobranca, :tipo_cobranca_anterior, :natureza_recebimento
      attr_accessor :comando, :codigo_ocorrencia, :motivo_ocorrencia

      # Datas importantes
      attr_accessor :data_liquidacao, :data_vencimento, :data_ocorrencia, :data_credito

      # Valores financeiros
      attr_accessor :desconto, :iof, :valor_tarifa, :outras_despesas
      attr_accessor :juros_desconto, :iof_desconto, :valor_abatimento, :desconto_concedito
      attr_accessor :valor_recebido, :juros_mora, :outros_recebimento
      attr_accessor :abatimento_nao_aproveitado, :valor_lancamento, :valor_ajuste

      # Dados do banco recebedor
      attr_accessor :banco_recebedor, :agencia_recebedora_com_dv

      # Indicadores
      attr_accessor :indicativo_lancamento, :indicador_valor

      # Campos específicos para cobrança híbrida (PIX)
      attr_accessor :tipo_chave_dict, :codigo_chave_dict, :txid
    end
  end
end
