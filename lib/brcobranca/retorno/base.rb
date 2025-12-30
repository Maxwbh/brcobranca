# frozen_string_literal: true

module Brcobranca
  module Retorno
    # Classe base para retornos bancários
    #
    # Esta classe define todos os atributos comuns aos arquivos de retorno
    # bancário nos formatos CNAB 240 e CNAB 400.
    class Base
      attr_accessor :codigo_registro, :sequencial, :arquivo,
                    :agencia_com_dv, :agencia_sem_dv, :cedente_com_dv, :convenio,
                    :nosso_numero, :documento_numero, :carteira, :carteira_variacao,
                    :especie_documento, :valor_titulo,
                    :tipo_cobranca, :tipo_cobranca_anterior, :natureza_recebimento,
                    :comando, :codigo_ocorrencia, :motivo_ocorrencia,
                    :data_liquidacao, :data_vencimento, :data_ocorrencia, :data_credito,
                    :desconto, :iof, :valor_tarifa, :outras_despesas,
                    :juros_desconto, :iof_desconto, :valor_abatimento, :desconto_concedito,
                    :valor_recebido, :juros_mora, :outros_recebimento,
                    :abatimento_nao_aproveitado, :valor_lancamento, :valor_ajuste,
                    :banco_recebedor, :agencia_recebedora_com_dv,
                    :indicativo_lancamento, :indicador_valor,
                    :tipo_chave_dict, :codigo_chave_dict, :txid
    end
  end
end
