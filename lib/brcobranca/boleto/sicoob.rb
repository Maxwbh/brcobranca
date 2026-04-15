# frozen_string_literal: true

module Brcobranca
  module Boleto
    # Sicoob (BANCOOB / Sicoob)
    #
    # Suporta as seguintes carteiras:
    #  - '1' / '01': Cobrança Simples Com Registro (modalidade tradicional)
    #  - '3' / '03': Cobrança Garantida Caucionada
    #  - '9' / '09': Nova carteira (2024/2025) - usa Número do Contrato no
    #                lugar do Código do Cedente na composição do código de
    #                barras/linha digitável.
    class Sicoob < Base
      # <b>OPCIONAL</b>: Número do Contrato fornecido pelo Sicoob, utilizado
      # na composição do código de barras para a Carteira 9 em vez do código
      # do cedente. Fornecido pelo banco na abertura do convênio.
      attr_accessor :numero_contrato

      # Carteiras que utilizam a nova composição de código de barras
      # baseada em Número do Contrato (ex.: Carteira 9).
      CARTEIRAS_CONTRATO = %w[9 09].freeze

      validates_length_of :agencia, maximum: 4, message: 'deve ser menor ou igual a 4 dígitos.'
      validates_length_of :conta_corrente, maximum: 8, message: 'deve ser menor ou igual a 8 dígitos.'
      validates_length_of :nosso_numero, maximum: 7, message: 'deve ser menor ou igual a 7 dígitos.'
      validates_length_of :convenio, maximum: 7, message: 'deve ser menor ou igual a 7 dígitos.'
      validates_length_of :variacao, maximum: 2, message: 'deve ser menor ou igual a 2 dígitos.'
      validates_length_of :quantidade, maximum: 3, message: 'deve ser menor ou igual a 3 dígitos.'
      validates_length_of :numero_contrato, maximum: 7,
                                            message: 'deve ser menor ou igual a 7 dígitos.',
                                            allow_blank: true

      def initialize(campos = {})
        campos = { carteira: '1', variacao: '01', quantidade: '001' }.merge!(campos)
        super(campos)
      end

      # Codigo do banco emissor (3 dígitos sempre)
      #
      # @return [String] 3 caracteres numéricos.
      def banco
        '756'
      end

      # Dígito verificador do banco
      #
      # @return [String] 1 caractere.
      def banco_dv
        '0'
      end

      # Agência
      #
      # @return [String] 4 caracteres numéricos.
      def agencia=(valor)
        @agencia = valor.to_s.rjust(4, '0') if valor
      end

      # Convênio
      #
      # @return [String] 7 caracteres numéricos.
      def convenio=(valor)
        @convenio = valor.to_s.rjust(7, '0') if valor
      end

      # Número do Contrato (utilizado na Carteira 9)
      #
      # @return [String] 7 caracteres numéricos.
      def numero_contrato=(valor)
        @numero_contrato = valor.to_s.rjust(7, '0') if valor
      end

      # Número documento
      #
      # @return [String] 7 caracteres numéricos.
      def nosso_numero=(valor)
        @nosso_numero = valor.to_s.rjust(7, '0') if valor
      end

      # Quantidade
      #
      # @return [String] 3 caracteres numéricos.
      def quantidade=(valor)
        @quantidade = valor.to_s.rjust(3, '0') if valor
      end

      # Nosso número para exibição no boleto.
      #
      # @return [String] 8 caracteres numéricos.
      def nosso_numero_boleto
        "#{nosso_numero}#{nosso_numero_dv}"
      end

      # Verifica se a carteira é a nova carteira baseada em Número do Contrato.
      #
      # @return [Boolean]
      def carteira_contrato?
        CARTEIRAS_CONTRATO.include?(carteira.to_s)
      end

      # 3.13. Nosso número: Código de controle que permite ao Sicoob e à empresa identificar os dados da cobrança que deu origem ao boleto.
      #
      # Para o cálculo do dígito verificador do nosso número, deverá ser utilizada a fórmula abaixo:
      # Número da Cooperativa    9(4) – vide planilha "Capa" deste arquivo
      # Código do Cliente   9(10) – vide planilha "Capa" deste arquivo
      # Nosso Número   9(7) – Iniciado em 1
      #
      # Constante para cálculo  = 3197
      #
      # a) Concatenar na seqüência completando com zero à esquerda.
      #     Ex.:Número da Cooperativa  = 0001
      #           Número do Cliente  = 1-9
      #           Nosso Número  = 21
      #           000100000000190000021
      #
      # b) Alinhar a constante com a seqüência repetindo de traz para frente.
      #     Ex.: 000100000000190000021
      #          319731973197319731973
      #
      # c) Multiplicar cada componente da seqüência com o seu correspondente da constante e somar os resultados.
      #     Ex.: 1*7 + 1*3 + 9*1 + 2*7 + 1*3 = 36
      #
      # d) Calcular o Resto através do Módulo 11.
      #     Ex.: 36/11 = 3, resto = 3
      #
      # e) O resto da divisão deverá ser subtraído de 11 achando assim o DV (Se o Resto for igual a 0 ou 1 então o DV é igual a 0).
      #     Ex.: 11 – 3 = 8, então Nosso Número + DV = 21-8
      #
      # Para a Carteira 9, usa o Número do Contrato em vez do Código do Cedente.
      #
      def nosso_numero_dv
        identificador = carteira_contrato? && numero_contrato ? numero_contrato : convenio
        "#{agencia}#{identificador.rjust(10, '0')}#{nosso_numero}".modulo11(
          reverse: false,
          multiplicador: [3, 1, 9, 7],
          mapeamento: { 10 => 0, 11 => 0 }
        ) { |t| 11 - (t % 11) }
      end

      def agencia_conta_boleto
        identificador = carteira_contrato? && numero_contrato ? numero_contrato : convenio
        "#{agencia} / #{identificador}"
      end

      # Segunda parte do código de barras (25 posições).
      #
      # Carteiras tradicionais (1 e 3):
      # Posição     Tamanho     Conteúdo
      #    20 a 20      01                 Código da carteira de cobrança
      #    21 a 24      04                 Código da agência/cooperativa
      #    25 a 26      02                 Código da modalidade
      #    27 a 33      07                 Código do cedente/cliente
      #    34 a 41      08                 Nosso número do boleto + DV
      #    42 a 44      03                 Número da parcela ("001" se única)
      #
      # Carteira 9 (nova modalidade 2024/2025):
      # O Código do Cedente é substituído pelo Número do Contrato fornecido
      # pelo Sicoob, mantendo o restante da estrutura inalterada.
      #
      # @return [String]
      def codigo_barras_segunda_parte
        identificador = carteira_contrato? && numero_contrato ? numero_contrato : convenio
        "#{carteira}#{agencia}#{variacao}#{identificador}#{nosso_numero_boleto}#{quantidade}"
      end
    end
  end
end
