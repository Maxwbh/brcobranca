# frozen_string_literal: true

module Brcobranca
  module Boleto
    # Banco C6 (código 336)
    #
    # Layout baseado no manual oficial "Layout de Arquivos Cobrança Bancária
    # Padrão CNAB 400 Posições - Versão 2.7 Julho 2025" do C6 Bank.
    class BancoC6 < Base
      # Códigos de carteira aceitos pelo C6:
      # - 10: Cobrança Simples Emissão Banco
      # - 20: Cobrança Simples Emissão Cliente
      CARTEIRAS = %w[10 20].freeze

      # Indicador de Layout do código de barras:
      # - 3: Cobrança Registrada Emissão do Boleto pelo Banco
      # - 4: Cobrança Registrada Emissão do Boleto pelo Beneficiário
      INDICADORES_LAYOUT = %w[3 4].freeze

      validates_length_of :convenio, is: 12, message: 'deve possuir 12 dígitos.' # Código do Cedente
      validates_length_of :nosso_numero, is: 10, message: 'deve possuir 10 dígitos.'
      validates_inclusion_of :carteira, in: CARTEIRAS, message: "não é uma carteira válida. Utilize: #{CARTEIRAS.join(', ')}."

      # @param (see Brcobranca::Boleto::Base#initialize)
      def initialize(campos = {})
        campos = {
          carteira: '10',
          especie_documento: 'DM'
        }.merge!(campos)
        super(campos)
      end

      # Código do banco emissor (C6Bank)
      # @return [String]
      def banco
        '336'
      end

      # Dígito verificador do banco.
      # @return [String]
      def banco_dv
        '7'
      end

      # Número do convênio/código do cedente junto ao C6.
      # @return [String] 12 caracteres numéricos.
      def convenio=(valor)
        @convenio = valor.to_s.rjust(12, '0') if valor
      end

      # Número sequencial utilizado para identificar o boleto.
      # @return [String] 10 caracteres numéricos.
      def nosso_numero=(valor)
        @nosso_numero = valor.to_s.rjust(10, '0') if valor
      end

      # Nosso número formatado para exibição (10 dígitos + DV).
      # @return [String]
      def nosso_numero_boleto
        "#{nosso_numero}-#{nosso_numero_dv}"
      end

      # Dígito verificador do Nosso Número.
      # Calculado via Módulo 11 conforme manual C6.
      # Resto 0, 10 ou 1 => DV = 0 (conforme prática usual para o cálculo de DV do nosso número).
      #
      # @return [String]
      def nosso_numero_dv
        nosso_numero.to_s.modulo11(
          multiplicador: (2..9).to_a,
          mapeamento: { 10 => 0, 11 => 0 }
        ) { |total| 11 - (total % 11) }.to_s
      end

      # Agência / Código Cedente do cliente para exibição no boleto.
      # @return [String]
      # @example
      #   boleto.agencia_conta_boleto #=> "1234 / 000000123456"
      def agencia_conta_boleto
        "#{agencia} / #{convenio}"
      end

      # Monta a segunda parte do código de barras (Campo Livre - 25 posições).
      #
      # Layout oficial do C6 Bank (manual CNAB 400, v2.7):
      # Posição | Tamanho | Conteúdo
      # 20 a 31 |   12    | Código do Cedente
      # 32 a 41 |   10    | Nosso Número (sem o dígito)
      # 42 a 43 |    2    | Código da Carteira
      # 44      |    1    | Indicador de Layout (3 = Emissão Banco, 4 = Emissão Beneficiário)
      #
      # O indicador de layout é derivado da carteira:
      # - Carteira 10 (Emissão Banco)        => Indicador 3
      # - Carteira 20 (Emissão Beneficiário) => Indicador 4
      #
      # @return [String]
      def codigo_barras_segunda_parte
        "#{convenio}#{nosso_numero}#{carteira}#{indicador_layout}"
      end

      # Indicador de Layout do boleto, derivado do código da carteira.
      #
      # @return [String]
      def indicador_layout
        carteira.to_s == '20' ? '4' : '3'
      end
    end
  end
end
