# frozen_string_literal: true

module Brcobranca
  module Remessa
    module Cnab400
      # Remessa CNAB 400 do Bradesco com suporte a PIX (Boleto Híbrido).
      #
      # Estende a remessa Bradesco tradicional adicionando o registro tipo 8
      # (detalhe PIX) que é gerado automaticamente pela classe base quando o
      # pagamento é um `PagamentoPix`.
      #
      # @example
      #   remessa = Brcobranca::Remessa::Cnab400::BradescoPix.new(
      #     agencia: '1234', conta_corrente: '12345',
      #     digito_conta: '6', empresa_mae: 'Empresa LTDA',
      #     documento_cedente: '12345678000100', carteira: '09',
      #     codigo_empresa: '12345',
      #     pagamentos: [pagamento_pix]
      #   )
      class BradescoPix < Brcobranca::Remessa::Cnab400::Bradesco
        include Brcobranca::Remessa::Cnab400::PixMixin
      end
    end
  end
end
