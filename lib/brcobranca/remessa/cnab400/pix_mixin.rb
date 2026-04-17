# frozen_string_literal: true

module Brcobranca
  module Remessa
    module Cnab400
      # Mixin que adiciona suporte a registro PIX em arquivos de remessa CNAB 400.
      #
      # Os registros PIX são gerados a partir de objetos `PagamentoPix` e seguem
      # o layout padrão FEBRABAN para PIX em boletos híbridos:
      #
      # - Registro tipo 8: Detalhe PIX com tipo de chave DICT, chave e TXID
      #
      # Este mixin é incluído nas classes de remessa que suportam PIX
      # (ex: `SantanderPix`, `BradescoPix`, `ItauPix`, `BancoC6Pix`).
      #
      # @example Inclusão em uma classe
      #   class BradescoPix < Bradesco
      #     include Brcobranca::Remessa::Cnab400::PixMixin
      #   end
      module PixMixin
        # Mapeamento do tipo de chave DICT para código numérico do layout FEBRABAN.
        DICT_MAPPING = {
          cpf: '1',
          cnpj: '2',
          telefone: '3',
          email: '4',
          chave_aleatoria: '5'
        }.freeze

        # Monta registro detalhe PIX (tipo 8) conforme padrão FEBRABAN CNAB 400.
        #
        # Estrutura do registro (400 posições):
        #
        #   Pos | Tam | Conteúdo
        #     1 |  1  | "8" (Código do Registro - fixo)
        #    2-3|  2  | Tipo de Pagamento (00, 01, 02, 03)
        #    4-5|  2  | Quantidade de Pagamentos Possíveis
        #     6 |  1  | Tipo do Valor Informado
        #   7-19| 13  | Valor Máximo (99V99)
        #  20-24|  5  | Percentual Máximo (999V99)
        #  25-37| 13  | Valor Mínimo (99V99)
        #  38-42|  5  | Percentual Mínimo (999V99)
        #    43 |  1  | Tipo de Chave DICT (1=CPF, 2=CNPJ, 3=Tel, 4=Email, 5=Aleatória)
        #  44-120| 77 | Código da Chave DICT
        # 121-155| 35 | TXID (Código de Identificação do QR Code)
        # 156-394|239 | Reservado (brancos)
        # 395-400|  6 | Número Sequencial do Registro
        #
        # @param pagamento [Brcobranca::Remessa::PagamentoPix]
        # @param sequencial [Integer] número sequencial do registro no arquivo
        # @return [String] registro de 400 posições
        def monta_detalhe_pix(pagamento, sequencial)
          raise Brcobranca::RemessaInvalida, pagamento if pagamento.invalid?

          detalhe = '8'                                                     # Código do Registro                   9[001]
          detalhe += formata_tipo_pagamento_pix(pagamento.tipo_pagamento_pix) # Tipo de Pagamento                 9[002]
          detalhe << pagamento.quantidade_pagamentos_pix.to_s.rjust(2, '0') # Quantidade de Pagamentos             9[002]
          detalhe << pagamento.tipo_valor_pix.to_s.rjust(1, '0')            # Tipo do Valor Informado              9[001]
          detalhe << pagamento.formata_valor_maximo_pix                     # Valor Máximo                         9[013]
          detalhe << pagamento.formata_percentual_maximo_pix                # Percentual Máximo                    9[005]
          detalhe << pagamento.formata_valor_minimo_pix                     # Valor Mínimo                         9[013]
          detalhe << pagamento.formata_percentual_minimo_pix                # Percentual Mínimo                    9[005]
          detalhe << formata_tipo_chave_dict(pagamento.tipo_chave_dict)     # Tipo de Chave DICT                   X[001]
          detalhe << pagamento.codigo_chave_dict.to_s.ljust(77, ' ')        # Código Chave DICT                    X[077]
          detalhe << pagamento.txid.to_s.ljust(35, ' ')                     # Código de Identificação do Qr Code   X[035]
          detalhe << ''.rjust(239, ' ')                                     # Reservado                            X[239]
          detalhe << sequencial.to_s.rjust(6, '0')                          # Número do registro                   9[006]
          detalhe
        end

        private

        # Formata o tipo de pagamento PIX (2 posições).
        # 00 = Conforme perfil do Beneficiário
        # 01 = Aceita qualquer valor
        # 02 = Entre o mínimo e o máximo
        # 03 = Não aceita pagamento com valor divergente
        def formata_tipo_pagamento_pix(tipo)
          tipo.to_i.to_s.rjust(2, '0')
        end

        # Converte o tipo de chave DICT em código numérico (1 posição).
        def formata_tipo_chave_dict(tipo)
          DICT_MAPPING[tipo.to_sym] || '0'
        end
      end
    end
  end
end
