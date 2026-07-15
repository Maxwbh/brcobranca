# frozen_string_literal: true

module Brcobranca
  module Remessa
    module Cnab400
      # Remessa CNAB 400 do Banco C6 (336) com suporte a PIX (Boleto Híbrido).
      #
      # ATENÇÃO — compatibilidade PIX no C6:
      #   O manual oficial de Cobrança CNAB 400 do C6 Bank NÃO define um
      #   "registro tipo 8" de PIX/DICT. O `PixMixin` incluído aqui gera esse
      #   registro no padrão FEBRABAN adotado por Santander/Bradesco/Itaú, útil
      #   como base comum, mas que o C6 não documenta.
      #
      #   No layout do C6 o pagamento com valor divergente/QR é tratado por
      #   campos opcionais estendidos do próprio registro detalhe (D086-D090),
      #   e o boleto híbrido com PIX (Bolepix) é oferecido pela API REST do C6,
      #   que aceita apenas chave aleatória (EVP).
      #
      #   Antes de enviar arquivos gerados por esta classe ao C6, confirme o
      #   suporte a este registro na versão vigente do manual (v2.7 ou superior).
      class BancoC6Pix < Brcobranca::Remessa::Cnab400::BancoC6
        include Brcobranca::Remessa::Cnab400::PixMixin
      end
    end
  end
end
