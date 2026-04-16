# frozen_string_literal: true

module Brcobranca
  module Remessa
    module Cnab240
      # Remessa CNAB 240 do Banco do Brasil com suporte a PIX (Boleto Híbrido).
      class BancoBrasilPix < Brcobranca::Remessa::Cnab240::BancoBrasil
        include Brcobranca::Remessa::Cnab240::PixMixin
      end
    end
  end
end
