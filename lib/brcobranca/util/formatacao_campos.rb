# frozen_string_literal: true

module Brcobranca
  module Util
    # Módulo para formatação de campos bancários
    #
    # Fornece métodos de classe para gerar setters que formatam
    # automaticamente campos numéricos com padding de zeros à esquerda.
    #
    # @example Uso em uma classe de boleto
    #   class MeuBanco < Brcobranca::Boleto::Base
    #     extend Brcobranca::Util::FormatacaoCampos
    #
    #     formata_campo :agencia, tamanho: 4
    #     formata_campo :conta_corrente, tamanho: 7
    #     formata_campo :nosso_numero, tamanho: 11
    #   end
    module FormatacaoCampos
      # Define um setter que formata o valor com zeros à esquerda
      #
      # @param campo [Symbol] nome do campo/atributo
      # @param tamanho [Integer] tamanho final do campo (com padding)
      # @param caractere [String] caractere para padding (padrão: '0')
      #
      # @example
      #   formata_campo :agencia, tamanho: 4
      #   # Gera:
      #   # def agencia=(valor)
      #   #   @agencia = valor.to_s.rjust(4, '0') if valor
      #   # end
      def formata_campo(campo, tamanho:, caractere: '0')
        define_method(:"#{campo}=") do |valor|
          instance_variable_set(:"@#{campo}", valor.to_s.rjust(tamanho, caractere)) if valor
        end
      end

      # Define múltiplos campos formatados de uma vez
      #
      # @param campos [Hash] hash com nome do campo e tamanho
      #
      # @example
      #   formata_campos agencia: 4, conta_corrente: 7, nosso_numero: 11
      def formata_campos(**campos)
        campos.each do |campo, tamanho|
          formata_campo(campo, tamanho: tamanho)
        end
      end
    end
  end
end
