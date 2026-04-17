# frozen_string_literal: true

module Brcobranca
  module Retorno
    module Cnab400
      # Retorno CNAB 400 do Banco C6 (código 336).
      #
      # Baseado no manual oficial "Layout de Arquivos Cobrança Bancária Padrão
      # CNAB 400 Posições - Versão 2.7 Julho 2025" do C6 Bank.
      class BancoC6 < Brcobranca::Retorno::Cnab400::Base
        extend ParseLine::FixedWidth

        # Load lines
        def self.load_lines(file, options = {})
          default_options = { except: [1] } # por padrão ignora o header
          options = default_options.merge!(options)
          super(file, options)
        end

        # Layout de largura fixa do registro detalhe de retorno do C6.
        # Posições são 0-based (zero-indexed) conforme padrão Ruby Range.
        fixed_width_layout do |parse|
          # Pos 1      | Tipo de Registro (1)
          parse.field :codigo_registro, 0..0

          # Pos 4-17   | CNPJ do Beneficiário (14)
          # Pos 18-29  | Código do Beneficiário (12)
          parse.field :cedente_com_dv, 17..28

          # Pos 30-37  | Brancos (8)
          # Pos 38-62  | Uso Exclusivo do Beneficiário (25)
          parse.field :documento_numero, 37..61

          # Pos 63-73  | Nosso Número (11)
          parse.field :nosso_numero, 62..72

          # Pos 74     | Dígito do Nosso Número (1)
          # Pos 75-86  | Nosso Número Complementar (12)
          # Pos 87-106 | Brancos (20)
          # Pos 107-108| Código da Carteira (2)
          parse.field :carteira, 106..107

          # Pos 109-110| Código de Ocorrência Retorno (2)
          parse.field :codigo_ocorrencia, 108..109

          # Pos 111-116| Data da Ocorrência (6) - DDMMAA
          parse.field :data_ocorrencia, 110..115

          # Pos 117-126| Seu Número do Título (10)
          # Pos 127-146| Brancos (20)
          # Pos 147-152| Data de Vencimento (6) - DDMMAA
          parse.field :data_vencimento, 146..151

          # Pos 153-165| Valor do Título (13) - 99v99
          parse.field :valor_titulo, 152..164

          # Pos 166-168| Banco Cobrador (3)
          parse.field :banco_recebedor, 165..167

          # Pos 169-173| Agência Cobradora (5)
          parse.field :agencia_recebedora_com_dv, 168..172

          # Pos 174-175| Brancos (2)
          # Pos 176-188| Valor da Tarifa/Custas de Cobrança (13) - 99v99
          parse.field :valor_tarifa, 175..187

          # Pos 189-227| Brancos (39)
          # Pos 228-240| Valor do Abatimento (13) - 99v99
          parse.field :valor_abatimento, 227..239

          # Pos 241-253| Valor do Desconto (13) - 99v99
          parse.field :desconto, 240..252

          # Pos 254-266| Valor Principal (13) - 99v99
          parse.field :valor_recebido, 253..265

          # Pos 267-279| Valor dos Juros (13) - 99v99
          parse.field :juros_mora, 266..278

          # Pos 280-292| Valor de Outros Acréscimos (13) - 99v99
          parse.field :outros_recebimento, 279..291

          # Pos 293-295| Brancos (3)
          # Pos 296-301| Data do Crédito (6) - DDMMAA
          parse.field :data_credito, 295..300

          # Pos 302-365| Brancos (64)
          # Pos 366-377| Campos Inválidos (12)
          # Pos 378-393| Código da Recusa (16)
          parse.field :motivo_ocorrencia, 377..392, lambda { |motivos|
            motivos.scan(/.{4}/).reject(&:blank?).reject { |motivo| motivo == '0000' }
          }

          # Pos 394    | Brancos (1)
          # Pos 395-400| Número Sequencial do Registro (6)
          parse.field :sequencial, 394..399
        end
      end
    end
  end
end
