# frozen_string_literal: true

module Brcobranca
  module Remessa
    module Cnab240
      # Remessa CNAB 240 do Sicoob com suporte a PIX (Boleto Híbrido).
      #
      # Estende a remessa Sicoob tradicional adicionando o Segmento Y-03
      # que é gerado automaticamente quando o pagamento é um `PagamentoPix`.
      class SicoobPix < Brcobranca::Remessa::Cnab240::Sicoob
        include Brcobranca::Remessa::Cnab240::PixMixin
      end
    end
  end
end
