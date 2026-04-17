# frozen_string_literal: true

module Brcobranca
  module Remessa
    module Cnab400
      # Remessa CNAB 400 do Itaú com suporte a PIX (Boleto Híbrido).
      class ItauPix < Brcobranca::Remessa::Cnab400::Itau
        include Brcobranca::Remessa::Cnab400::PixMixin
      end
    end
  end
end
