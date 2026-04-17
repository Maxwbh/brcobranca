# frozen_string_literal: true

module Brcobranca
  module Remessa
    module Cnab240
      # Mixin que adiciona suporte ao Segmento Y-03 (PIX) em remessas CNAB 240.
      #
      # O Segmento Y-03 é opcional e deve ser adicionado após os segmentos P/Q/R
      # do título, contendo os dados da chave PIX DICT e TXID.
      #
      # Layout do Segmento Y-03 (240 posições):
      #
      #   Pos  | Tam | Conteúdo
      #   1-3  |  3  | Código do Banco
      #   4-7  |  4  | Código do Lote
      #     8  |  1  | Tipo de Registro ("3")
      #   9-13 |  5  | Número Sequencial do Registro no Lote
      #    14  |  1  | Segmento ("Y")
      #  15-16 |  2  | Uso exclusivo FEBRABAN (brancos)
      #  17-18 |  2  | Identificação do registro opcional ("03")
      #  19-23 |  5  | Código do movimento remessa
      #  24-27 |  4  | Código da instrução para cobrança
      #  28-28 |  1  | Tipo de Chave DICT (1-5)
      #  29-105| 77  | Chave DICT
      # 106-140| 35  | TXID
      # 141-240|100  | Uso FEBRABAN (brancos)
      module PixMixin
        DICT_MAPPING = {
          cpf: '1',
          cnpj: '2',
          telefone: '3',
          email: '4',
          chave_aleatoria: '5'
        }.freeze

        # Monta segmento Y-03 (PIX) do CNAB 240.
        #
        # @param pagamento [Brcobranca::Remessa::PagamentoPix]
        # @param nro_lote [Integer] número do lote
        # @param sequencial [Integer] número sequencial do registro no lote
        # @return [String] segmento Y de 240 posições
        def monta_segmento_y(pagamento, nro_lote, sequencial)
          raise Brcobranca::RemessaInvalida, pagamento if pagamento.invalid?

          segmento_y = ''                                                 # CAMPO                        TAMANHO
          segmento_y += cod_banco                                         # Código do banco              3
          segmento_y << nro_lote.to_s.rjust(4, '0')                       # Lote                         4
          segmento_y << '3'                                               # Tipo de Registro             1
          segmento_y << sequencial.to_s.rjust(5, '0')                     # Sequencial no Lote           5
          segmento_y << 'Y'                                               # Código do segmento           1
          segmento_y << ''.rjust(2, ' ')                                  # Uso exclusivo                2
          segmento_y << '03'                                              # Identificação registro opc.  2
          segmento_y << '00000'                                           # Código do movimento          5 (zeros = registro)
          segmento_y << ''.rjust(4, ' ')                                  # Instrução de cobrança        4
          segmento_y << formata_tipo_chave_dict(pagamento.tipo_chave_dict) # Tipo Chave DICT             1
          segmento_y << pagamento.codigo_chave_dict.to_s.ljust(77, ' ')   # Chave DICT                   77
          segmento_y << pagamento.txid.to_s.ljust(35, ' ')                # TXID                         35
          segmento_y << ''.rjust(100, ' ')                                # Uso FEBRABAN                 100
          segmento_y
        end

        private

        def formata_tipo_chave_dict(tipo)
          DICT_MAPPING[tipo.to_sym] || '0'
        end
      end
    end
  end
end
