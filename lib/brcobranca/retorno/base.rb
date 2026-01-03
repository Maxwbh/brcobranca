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

      # ============================================================
      # Fase 4: API de Serialização para Retorno (v12.5.0)
      # ============================================================

      # Lista de atributos para serialização
      ATRIBUTOS = %i[
        codigo_registro sequencial
        agencia_com_dv agencia_sem_dv cedente_com_dv convenio
        nosso_numero documento_numero carteira carteira_variacao
        especie_documento valor_titulo
        tipo_cobranca tipo_cobranca_anterior natureza_recebimento
        comando codigo_ocorrencia motivo_ocorrencia
        data_liquidacao data_vencimento data_ocorrencia data_credito
        desconto iof valor_tarifa outras_despesas
        juros_desconto iof_desconto valor_abatimento desconto_concedito
        valor_recebido juros_mora outros_recebimento
        abatimento_nao_aproveitado valor_lancamento valor_ajuste
        banco_recebedor agencia_recebedora_com_dv
        indicativo_lancamento indicador_valor
        tipo_chave_dict codigo_chave_dict txid
      ].freeze

      # Retorna todos os dados do registro como Hash
      #
      # @param options [Hash] opções
      # @option options [Boolean] :compact remove valores nil (default: true)
      #
      # @return [Hash] dados do registro
      #
      # @example
      #   registro.to_hash
      #   #=> { nosso_numero: '12345', valor_titulo: '100.00', ... }
      def to_hash(options = {})
        compact = options.fetch(:compact, true)

        resultado = ATRIBUTOS.each_with_object({}) do |attr, hash|
          hash[attr] = send(attr) if respond_to?(attr)
        end

        compact ? resultado.compact : resultado
      end

      # Retorna dados com chaves string (para APIs REST)
      #
      # @param options [Hash] opções (mesmas de to_hash)
      # @return [Hash] dados com chaves string
      def as_json(options = {})
        to_hash(options).transform_keys(&:to_s)
      end

      # Retorna dados como JSON string
      #
      # @param options [Hash] opções (mesmas de to_hash)
      # @return [String] JSON string
      def to_json(*_args)
        require 'json'
        as_json.to_json
      end

      # Dados principais do título (campos mais utilizados)
      #
      # @return [Hash] dados principais
      def dados_titulo
        {
          nosso_numero: nosso_numero,
          documento_numero: documento_numero,
          valor_titulo: valor_titulo,
          data_vencimento: data_vencimento,
          carteira: carteira
        }.compact
      end

      # Dados de recebimento/pagamento
      #
      # @return [Hash] dados de recebimento
      def dados_recebimento
        {
          valor_recebido: valor_recebido,
          data_credito: data_credito,
          data_ocorrencia: data_ocorrencia,
          juros_mora: juros_mora,
          desconto: desconto,
          valor_abatimento: valor_abatimento,
          valor_tarifa: valor_tarifa
        }.compact
      end

      # Dados da ocorrência/movimento
      #
      # @return [Hash] dados da ocorrência
      def dados_ocorrencia
        {
          codigo_ocorrencia: codigo_ocorrencia,
          motivo_ocorrencia: motivo_ocorrencia,
          data_ocorrencia: data_ocorrencia,
          sequencial: sequencial
        }.compact
      end

      # Dados bancários
      #
      # @return [Hash] dados bancários
      def dados_bancarios
        {
          agencia_com_dv: agencia_com_dv,
          cedente_com_dv: cedente_com_dv,
          banco_recebedor: banco_recebedor,
          agencia_recebedora_com_dv: agencia_recebedora_com_dv,
          convenio: convenio
        }.compact
      end

      # Dados PIX (quando disponíveis)
      #
      # @return [Hash, nil] dados PIX ou nil
      def dados_pix
        return nil unless tipo_chave_dict || codigo_chave_dict || txid

        {
          tipo_chave_dict: tipo_chave_dict,
          codigo_chave_dict: codigo_chave_dict,
          txid: txid
        }.compact
      end
    end
  end
end
