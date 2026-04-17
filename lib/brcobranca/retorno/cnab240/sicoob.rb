# frozen_string_literal: true

require 'parseline'

module Brcobranca
  module Retorno
    module Cnab240
      class Sicoob < Brcobranca::Retorno::Cnab240::Base
        # Regex para remoção de headers e trailers além de registros diferentes de T ou U
        REGEX_DE_EXCLUSAO_DE_REGISTROS_NAO_T_OU_U = /^((?!^.{7}3.{5}[T|U].*$).)*$/.freeze

        def self.load_lines(file, options = {})
          default_options = { except: REGEX_DE_EXCLUSAO_DE_REGISTROS_NAO_T_OU_U }
          options = default_options.merge!(options)

          Line.load_lines(file, options).each_slice(2).reduce([]) do |retornos, cnab_lines|
            retornos << generate_retorno_based_on_cnab_lines(cnab_lines)
          end
        end

        def self.generate_retorno_based_on_cnab_lines(cnab_lines)
          retorno = new
          cnab_lines.each do |line|
            if line.tipo_registro == 'T'
              Line::REGISTRO_T_FIELDS.each do |attr|
                retorno.send(:"#{attr}=", line.send(attr))
              end
            else
              Line::REGISTRO_U_FIELDS.each do |attr|
                retorno.send(:"#{attr}=", line.send(attr))
              end
            end
          end
          retorno
        end

        # Linha de mapeamento do retorno do arquivo CNAB 240
        # O registro CNAB 240 possui 2 tipos de registros que juntos geram um registro de retorno bancário
        # O primeiro é do tipo T que retorna dados gerais sobre a transação (segmento T)
        # O segundo é do tipo U que retorna os valores da transação (segmento U)
        #
        # Posições conforme manual oficial Sicoob CNAB 240 (v.26/06/2019, atualização 23/02/2021)
        class Line < Base
          extend ParseLine::FixedWidth # Extendendo parseline

          REGISTRO_T_FIELDS = %w[codigo_registro codigo_ocorrencia agencia_com_dv cedente_com_dv
                                 nosso_numero carteira documento_numero data_vencimento valor_titulo
                                 banco_recebedor agencia_recebedora_com_dv especie_documento
                                 sequencial valor_tarifa motivo_ocorrencia].freeze
          REGISTRO_U_FIELDS = %w[juros_mora desconto_concedito valor_abatimento iof_desconto
                                 valor_recebido outras_despesas outros_recebimento
                                 data_credito data_ocorrencia].freeze

          attr_accessor :tipo_registro

          # Layout do Segmento T/U no CNAB 240 Sicoob:
          # Posições (1-based no manual convertidas para 0-based do Ruby).
          #
          # Nota: o `nosso_numero` é mapeado como 10 posições (37..46) para
          # manter compatibilidade com layouts tradicionais. Layouts mais
          # recentes usam até 20 posições (37..56) — os 10 dígitos seguintes
          # são complementares e podem conter zeros, carteira e outros.
          fixed_width_layout do |parse|
            parse.field :codigo_registro, 7..7
            parse.field :tipo_registro, 13..13
            parse.field :sequencial, 8..12
            parse.field :codigo_ocorrencia, 15..16

            # Segmento T
            parse.field :agencia_com_dv, 17..22
            parse.field :cedente_com_dv, 23..35
            parse.field :nosso_numero, 37..46
            parse.field :carteira, 57..57
            parse.field :documento_numero, 58..72
            parse.field :data_vencimento, 73..80
            parse.field :valor_titulo, 81..95
            parse.field :banco_recebedor, 96..98
            parse.field :agencia_recebedora_com_dv, 99..104
            parse.field :especie_documento, 111..113
            parse.field :valor_tarifa, 198..212
            parse.field :motivo_ocorrencia, 213..222, lambda { |motivos|
              motivos.scan(/.{2}/).reject(&:blank?).reject { |motivo| motivo == '00' }
            }

            # Segmento U — posições sobrepõem as do T por terem segmentos diferentes.
            # O parseline usa o mesmo mapa para os dois; como diferenciamos via
            # `tipo_registro`, apenas os atributos do segmento correto são gravados.
            parse.field :juros_mora, 17..31
            parse.field :desconto_concedito, 32..46
            parse.field :valor_abatimento, 47..61
            parse.field :iof_desconto, 62..76
            parse.field :valor_recebido, 77..91
            parse.field :outras_despesas, 107..121
            parse.field :outros_recebimento, 122..136
            parse.field :data_ocorrencia, 137..144
            parse.field :data_credito, 145..152
          end
        end
      end
    end
  end
end
