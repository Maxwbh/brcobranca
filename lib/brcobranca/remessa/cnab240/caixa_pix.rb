# frozen_string_literal: true

module Brcobranca
  module Remessa
    module Cnab240
      # Remessa CNAB 240 da Caixa com suporte a PIX (Boleto Híbrido).
      class CaixaPix < Brcobranca::Remessa::Cnab240::Caixa
        include Brcobranca::Remessa::Cnab240::PixMixin
      end
    end
  end
end
