# frozen_string_literal: true

module Brcobranca
  module Remessa
    class Base
      # pagamentos da remessa (cada pagamento representa um registro detalhe no arquivo)
      attr_accessor :pagamentos
      # empresa mae (razao social)
      attr_accessor :empresa_mae
      # agencia (sem digito verificador)
      attr_accessor :agencia
      # numero da conta corrente
      attr_accessor :conta_corrente
      # digito verificador da conta corrente
      attr_accessor :digito_conta
      # carteira do cedente
      attr_accessor :carteira
      # sequencial remessa (num. sequencial que nao pode ser repetido nem zerado)
      attr_accessor :sequencial_remessa
      # aceite (A = ACEITO/N = NAO ACEITO)
      attr_accessor :aceite
      # documento do cedente (CPF/CNPJ)
      attr_accessor :documento_cedente

      # Validações
      include Brcobranca::Validations

      PAYMENT_CLASSES = [
        Brcobranca::Remessa::Pagamento,
        Brcobranca::Remessa::PagamentoPix
      ].freeze

      validates_presence_of :pagamentos, :empresa_mae, message: 'não pode estar em branco.'

      validates_each :pagamentos do |record, attr, value|
        if value.is_a? Array
          record.errors.add(attr, 'não pode estar vazio.') if value.empty?
          value.each do |pagamento|
            if PAYMENT_CLASSES.include?(pagamento.class)
              pagamento.errors.full_messages.each { |msg| record.errors.add(attr, msg) } if pagamento.invalid?
            else
              record.errors.add(attr, 'cada item deve ser um objeto Pagamento.')
            end
          end
        else
          record.errors.add(attr, 'deve ser uma coleção (Array).')
        end
      end

      # Nova instancia da classe
      #
      # @param campos [Hash]
      #
      def initialize(campos = {})
        campos = { aceite: 'N' }.merge!(campos)
        campos.each do |campo, valor|
          send :"#{campo}=", valor
        end

        yield self if block_given?
      end

      def quantidade_titulos_cobranca
        pagamentos.length.to_s.rjust(6, '0')
      end

      def totaliza_valor_titulos
        pagamentos.inject(0.0) { |sum, pagamento| sum + pagamento.valor.to_f }
      end

      def valor_titulos_carteira(tamanho = 17)
        total = format '%.2f', totaliza_valor_titulos
        total.somente_numeros.rjust(tamanho, '0')
      end

      # ============================================================
      # Fase 3: API de Serialização para Remessa (v12.4.0)
      # ============================================================

      # Lista de atributos base da remessa
      ATRIBUTOS_BASE = %i[
        empresa_mae agencia conta_corrente digito_conta
        carteira sequencial_remessa aceite documento_cedente
      ].freeze

      # Verifica se a remessa é válida sem levantar exceção
      #
      # @return [Boolean] true se válida
      def valido?
        valid?
      rescue StandardError
        false
      end

      # Retorna dados de entrada da remessa (sem pagamentos serializados)
      #
      # @return [Hash] dados de entrada
      def dados_entrada
        ATRIBUTOS_BASE.each_with_object({}) do |attr, hash|
          hash[attr] = send(attr) if respond_to?(attr)
        end
      end

      # Retorna dados calculados da remessa
      #
      # @return [Hash] dados calculados
      def dados_calculados
        {
          quantidade_titulos: pagamentos&.length || 0,
          valor_total: totaliza_valor_titulos,
          valor_total_formatado: valor_titulos_carteira
        }
      end

      # Retorna todos os dados da remessa como Hash
      #
      # @param options [Hash] opções
      # @option options [Boolean] :somente_calculados retorna apenas dados calculados
      # @option options [Boolean] :incluir_pagamentos inclui array de pagamentos (default: true)
      #
      # @return [Hash] dados da remessa
      #
      # @example
      #   remessa.to_hash
      #   #=> { empresa_mae: 'Empresa', pagamentos: [...], quantidade_titulos: 2, ... }
      def to_hash(options = {})
        return dados_calculados if options[:somente_calculados]

        resultado = dados_entrada.merge(dados_calculados)

        if options.fetch(:incluir_pagamentos, true) && pagamentos
          resultado[:pagamentos] = pagamentos.map(&:to_hash)
        end

        resultado
      end

      # Retorna dados da remessa com chaves string (para APIs REST)
      #
      # @param options [Hash] opções (mesmas de to_hash)
      # @return [Hash] dados com chaves string
      def as_json(options = {})
        hash = to_hash(options)
        resultado = hash.transform_keys(&:to_s)

        if resultado['pagamentos']
          resultado['pagamentos'] = resultado['pagamentos'].map do |p|
            p.transform_keys(&:to_s)
          end
        end

        resultado
      end

      # Retorna dados da remessa como JSON string
      #
      # @param options [Hash] opções (mesmas de to_hash)
      # @return [String] JSON string
      def to_json(options = {})
        require 'json'
        as_json(options).to_json
      end

      # Retorna hash seguro com status de validação
      #
      # @param options [Hash] opções (mesmas de to_hash)
      # @return [Hash] dados com valid e errors
      #
      # @example Remessa válida
      #   remessa.to_hash_seguro
      #   #=> { valid: true, errors: [], empresa_mae: 'Empresa', ... }
      #
      # @example Remessa inválida
      #   remessa.to_hash_seguro
      #   #=> { valid: false, errors: ['Empresa mae não pode estar em branco.'], ... }
      def to_hash_seguro(options = {})
        resultado = dados_entrada.merge(dados_calculados)

        if options.fetch(:incluir_pagamentos, true) && pagamentos
          resultado[:pagamentos] = pagamentos.map(&:to_hash_seguro)
        end

        resultado.merge(
          valid: valido?,
          errors: valido? ? [] : errors.full_messages
        )
      end

      # Retorna hash seguro com chaves string
      #
      # @param options [Hash] opções
      # @return [Hash] dados com chaves string
      def as_json_seguro(options = {})
        hash = to_hash_seguro(options)
        resultado = hash.transform_keys(&:to_s)

        if resultado['pagamentos']
          resultado['pagamentos'] = resultado['pagamentos'].map do |p|
            p.transform_keys(&:to_s)
          end
        end

        resultado
      end

      # Retorna JSON seguro com status de validação
      #
      # @param options [Hash] opções
      # @return [String] JSON string
      def to_json_seguro(options = {})
        require 'json'
        as_json_seguro(options).to_json
      end
    end
  end
end
