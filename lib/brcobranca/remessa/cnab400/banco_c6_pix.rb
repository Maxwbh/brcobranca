# frozen_string_literal: true

module Brcobranca
  module Remessa
    module Cnab400
      # Remessa CNAB 400 do Banco C6 (336) com suporte a PIX (Boleto Híbrido).
      class BancoC6Pix < Brcobranca::Remessa::Cnab400::BancoC6
        include Brcobranca::Remessa::Cnab400::PixMixin
      end
    end
  end
end
