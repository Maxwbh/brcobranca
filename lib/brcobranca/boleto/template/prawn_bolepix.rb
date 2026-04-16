# frozen_string_literal: true

# Template alternativo para geração de boletos híbridos (com PIX) usando Prawn.
#
# Ao contrário do `RghostBolepix`, este template NÃO depende do Ghostscript
# instalado no sistema — usa apenas gems Ruby puras (prawn + prawn-table + barby
# + rqrcode + chunky_png).
#
# O layout segue fielmente o padrão FEBRABAN, com duas seções:
#   1. Recibo do Pagador (superior)
#   2. Ficha de Compensação (inferior)
#
# Quando `boleto.emv` está presente, um QR Code PIX é adicionado ao lado do
# código de barras na Ficha de Compensação, criando o "Boleto Híbrido" ou
# "Bolepix".
#
# Para ativar globalmente:
#   Brcobranca.setup { |c| c.gerador = :prawn_bolepix }
#
# Ou individualmente:
#   boleto.extend(Brcobranca::Boleto::Template::PrawnBolepix)
#   boleto.to(:pdf)
module Brcobranca
  module Boleto
    module Template
      # Indica se as gems necessárias para este template estão disponíveis.
      begin
        require 'prawn'
        require 'prawn/measurement_extensions'
        require 'prawn/table'
        require 'barby'
        require 'barby/barcode/code_25_interleaved'
        require 'barby/outputter/prawn_outputter'
        require 'rqrcode'
        require 'chunky_png'
        PRAWN_AVAILABLE = true
      rescue LoadError
        PRAWN_AVAILABLE = false
      end

      # Template Prawn para boletos híbridos com PIX — layout FEBRABAN.
      module PrawnBolepix
        extend self

        # Constantes de layout
        PAGE_MARGIN = 20
        LABEL_SIZE = 6
        VALUE_SIZE = 9
        LINHA_DIG_SIZE = 12
        CODIGO_BANCO_SIZE = 15
        HEADER_HEIGHT = 22
        ROW_HEIGHT = 17
        BORDER_WIDTH = 0.5

        # Gera o boleto em PDF usando Prawn.
        #
        # @return [String] bytes do PDF
        def to(formato, _options = {})
          raise 'Prawn não está disponível. Instale: gem install prawn prawn-table barby rqrcode chunky_png' unless PRAWN_AVAILABLE
          raise ArgumentError, "Formato #{formato} não suportado pelo PrawnBolepix (apenas :pdf)" unless formato.to_sym == :pdf

          render_boleto(self)
        end

        # Gera um PDF com múltiplos boletos.
        def lote(boletos, _options = {})
          raise 'Prawn não está disponível.' unless PRAWN_AVAILABLE

          render_boletos(boletos)
        end

        def method_missing(m, *args)
          method = m.to_s
          return to(:pdf, args.first || {}) if method == 'to_pdf'

          super
        end

        def respond_to_missing?(method_name, include_private = false)
          method_name.to_s == 'to_pdf' || super
        end

        private

        # Renderiza um único boleto em PDF.
        def render_boleto(boleto)
          pdf = new_document
          draw_boleto(pdf, boleto)
          pdf.render
        end

        # Renderiza múltiplos boletos em um único PDF.
        def render_boletos(boletos)
          pdf = new_document
          boletos.each_with_index do |boleto, index|
            draw_boleto(pdf, boleto)
            pdf.start_new_page unless index == boletos.length - 1
          end
          pdf.render
        end

        # Cria novo documento Prawn com margens padrão.
        def new_document
          Prawn::Document.new(
            page_size: 'A4',
            margin: [PAGE_MARGIN, PAGE_MARGIN, PAGE_MARGIN, PAGE_MARGIN],
            info: {
              Title: 'Boleto Bancário (Bolepix)',
              Creator: 'brcobranca',
              Producer: 'Prawn + RQRCode + Barby'
            }
          )
        end

        # Desenha um boleto completo: recibo do pagador + corte + ficha de
        # compensação + código de barras + QR Code PIX (se aplicável).
        def draw_boleto(pdf, boleto)
          # Recibo do Pagador
          draw_recibo_pagador(pdf, boleto)

          # Linha de corte pontilhada
          pdf.move_down 8
          draw_linha_corte(pdf)
          pdf.move_down 8

          # Ficha de Compensação
          draw_ficha_compensacao(pdf, boleto)

          # Código de barras Interleaved 2 of 5 + QR Code PIX
          pdf.move_down 10
          draw_codigo_barras_e_pix(pdf, boleto)
        end

        # =================================================================
        # RECIBO DO PAGADOR
        # =================================================================
        def draw_recibo_pagador(pdf, boleto)
          # Linha superior: Logo | Código | Linha digitável
          draw_linha_topo(pdf, boleto, 'Recibo do Pagador')

          # Beneficiário | Agência/Código do Beneficiário
          draw_row(pdf, [
                     { label: 'Beneficiário', value: boleto.cedente.to_s, width_ratio: 0.70 },
                     { label: 'Agência / Código do Beneficiário', value: boleto.agencia_conta_boleto.to_s, width_ratio: 0.30 }
                   ])

          # Endereço Beneficiário | Nosso Número
          draw_row(pdf, [
                     { label: 'Endereço do Beneficiário', value: boleto.cedente_endereco.to_s, width_ratio: 0.70 },
                     { label: 'Nosso Número', value: boleto.nosso_numero_boleto.to_s, width_ratio: 0.30 }
                   ])

          # Nº Documento | CPF/CNPJ | Data Vencimento | Valor Documento
          draw_row(pdf, [
                     { label: 'Nº do Documento', value: boleto.documento_numero.to_s, width_ratio: 0.30 },
                     { label: 'CPF/CNPJ', value: boleto.documento_cedente.to_s.formata_documento, width_ratio: 0.25 },
                     { label: 'Vencimento', value: boleto.data_vencimento.to_s_br, width_ratio: 0.20 },
                     { label: 'Valor do Documento', value: boleto.valor_documento.to_currency, width_ratio: 0.25 }
                   ])

          # Descontos | Outras Deduções | Mora/Multa | Outros Acréscimos | Valor Cobrado
          draw_row(pdf, [
                     { label: '(-) Desconto/Abatimentos', value: boleto.descontos_e_abatimentos&.to_currency || '', width_ratio: 0.20 },
                     { label: '(-) Outras Deduções', value: '', width_ratio: 0.20 },
                     { label: '(+) Mora/Multa', value: '', width_ratio: 0.20 },
                     { label: '(+) Outros Acréscimos', value: '', width_ratio: 0.20 },
                     { label: '(=) Valor Cobrado', value: boleto.valor_documento.to_currency, width_ratio: 0.20 }
                   ])

          # Pagador
          pagador_texto = "#{boleto.sacado} - CPF/CNPJ: #{boleto.sacado_documento.to_s.formata_documento}"
          pagador_texto += "\n#{boleto.sacado_endereco}" if boleto.sacado_endereco
          draw_row(pdf, [
                     { label: 'Pagador', value: pagador_texto, width_ratio: 1.0 }
                   ], height: ROW_HEIGHT * 1.4)

          # Autenticação mecânica
          draw_row(pdf, [
                     { label: 'Autenticação mecânica', value: '', width_ratio: 1.0, align: :right }
                   ], height: ROW_HEIGHT * 0.7)
        end

        # =================================================================
        # FICHA DE COMPENSAÇÃO
        # =================================================================
        def draw_ficha_compensacao(pdf, boleto)
          draw_linha_topo(pdf, boleto, 'Ficha de Compensação')

          # Local de pagamento | Vencimento
          draw_row(pdf, [
                     { label: 'Local de Pagamento', value: boleto.local_pagamento.to_s, width_ratio: 0.75 },
                     { label: 'Vencimento', value: boleto.data_vencimento.to_s_br, width_ratio: 0.25 }
                   ])

          # Beneficiário | Agência/Código
          draw_row(pdf, [
                     { label: 'Beneficiário', value: "#{boleto.cedente} - #{boleto.documento_cedente.to_s.formata_documento}", width_ratio: 0.75 },
                     { label: 'Agência/Código do Beneficiário', value: boleto.agencia_conta_boleto.to_s, width_ratio: 0.25 }
                   ])

          # Data Documento | Nº Documento | Espécie Doc | Aceite | Data Processamento | Nosso Número
          draw_row(pdf, [
                     { label: 'Data do Documento', value: boleto.data_documento&.to_s_br || '', width_ratio: 0.18 },
                     { label: 'Nº do Documento', value: boleto.documento_numero.to_s, width_ratio: 0.22 },
                     { label: 'Espécie Doc.', value: boleto.especie_documento.to_s, width_ratio: 0.12 },
                     { label: 'Aceite', value: boleto.aceite.to_s, width_ratio: 0.08 },
                     { label: 'Data do Processamento', value: boleto.data_processamento&.to_s_br || '', width_ratio: 0.15 },
                     { label: 'Nosso Número', value: boleto.nosso_numero_boleto.to_s, width_ratio: 0.25 }
                   ])

          # Uso do Banco | Carteira | Espécie | Quantidade | Valor | Valor Documento
          carteira_txt = boleto.variacao ? "#{boleto.carteira}/#{boleto.variacao}" : boleto.carteira.to_s
          draw_row(pdf, [
                     { label: 'Uso do Banco', value: '', width_ratio: 0.18 },
                     { label: 'Carteira', value: carteira_txt, width_ratio: 0.22 },
                     { label: 'Espécie', value: boleto.especie.to_s, width_ratio: 0.12 },
                     { label: 'Quantidade', value: boleto.quantidade.to_s, width_ratio: 0.08 },
                     { label: 'Valor', value: boleto.valor.to_f.to_currency, width_ratio: 0.15 },
                     { label: '(=) Valor do Documento', value: boleto.valor_documento.to_currency, width_ratio: 0.25 }
                   ])

          # Descontos | Outras Deduções | Mora/Multa | Outros Acréscimos | Valor Cobrado
          draw_row(pdf, [
                     { label: '(-) Desconto/Abatimentos', value: boleto.descontos_e_abatimentos&.to_currency || '', width_ratio: 0.20 },
                     { label: '(-) Outras Deduções', value: '', width_ratio: 0.20 },
                     { label: '(+) Mora/Multa', value: '', width_ratio: 0.20 },
                     { label: '(+) Outros Acréscimos', value: '', width_ratio: 0.20 },
                     { label: '(=) Valor Cobrado', value: '', width_ratio: 0.20 }
                   ])

          # Instruções
          instrucoes = montar_instrucoes(boleto)
          draw_row(pdf, [
                     { label: 'Instruções (Texto de responsabilidade do Beneficiário)', value: instrucoes, width_ratio: 1.0 }
                   ], height: ROW_HEIGHT * 2.2)

          # Pagador
          pagador_texto = "#{boleto.sacado} - CPF/CNPJ: #{boleto.sacado_documento.to_s.formata_documento}"
          pagador_texto += "\n#{boleto.sacado_endereco}" if boleto.sacado_endereco
          draw_row(pdf, [
                     { label: 'Pagador', value: pagador_texto, width_ratio: 1.0 }
                   ], height: ROW_HEIGHT * 1.4)

          # Sacador/Avalista | Cód. de Baixa
          avalista = boleto.avalista && boleto.avalista_documento ? "#{boleto.avalista} - #{boleto.avalista_documento}" : ''
          draw_row(pdf, [
                     { label: 'Sacador/Avalista', value: avalista, width_ratio: 0.80 },
                     { label: 'Cód. de Baixa', value: '', width_ratio: 0.20 }
                   ])
        end

        # =================================================================
        # LINHA TOPO: Logo | Código | Linha Digitável
        # =================================================================
        def draw_linha_topo(pdf, boleto, titulo)
          width = pdf.bounds.width
          y_top = pdf.cursor
          banco_width = 90
          codigo_width = 55

          # Título acima (pequeno)
          pdf.text titulo, size: 6, color: '666666'
          pdf.move_down 2

          y = pdf.cursor

          pdf.stroke_rectangle([0, y], width, HEADER_HEIGHT)

          # Célula 1: Logo do banco (texto se não houver imagem)
          pdf.bounding_box([0, y], width: banco_width, height: HEADER_HEIGHT) do
            desenha_logo_banco(pdf, boleto)
          end
          pdf.stroke_vertical_line y, y - HEADER_HEIGHT, at: banco_width

          # Célula 2: Código do banco - DV
          pdf.bounding_box([banco_width, y], width: codigo_width, height: HEADER_HEIGHT) do
            pdf.text_box "#{boleto.banco}-#{boleto.banco_dv}",
                         at: [0, HEADER_HEIGHT - 6],
                         width: codigo_width,
                         height: HEADER_HEIGHT,
                         size: CODIGO_BANCO_SIZE,
                         align: :center,
                         valign: :center,
                         style: :bold
          end
          pdf.stroke_vertical_line y, y - HEADER_HEIGHT, at: banco_width + codigo_width

          # Célula 3: Linha digitável
          pdf.bounding_box([banco_width + codigo_width, y], width: width - banco_width - codigo_width, height: HEADER_HEIGHT) do
            pdf.text_box boleto.codigo_barras.linha_digitavel,
                         at: [5, HEADER_HEIGHT - 6],
                         width: width - banco_width - codigo_width - 10,
                         height: HEADER_HEIGHT,
                         size: LINHA_DIG_SIZE,
                         align: :right,
                         valign: :center,
                         style: :bold
          end

          pdf.move_down HEADER_HEIGHT
        end

        # Desenha logotipo do banco. Se o arquivo EPS existir, usa texto como fallback
        # (Prawn não renderiza EPS nativo — precisaria de PNG).
        def desenha_logo_banco(pdf, boleto)
          png_path = boleto.logotipo.sub(/\.eps\z/, '.png')
          if File.exist?(png_path)
            pdf.image png_path, height: HEADER_HEIGHT - 4, position: :center, vposition: :center
          else
            # Fallback: nome do banco em texto
            pdf.text_box boleto.banco_nome.upcase,
                         at: [0, HEADER_HEIGHT - 6],
                         width: 90,
                         height: HEADER_HEIGHT,
                         size: 9,
                         align: :center,
                         valign: :center,
                         style: :bold
          end
        rescue StandardError
          # Se renderização de imagem falhar, usa texto
          pdf.text_box boleto.banco_nome.upcase,
                       at: [0, HEADER_HEIGHT - 6],
                       width: 90,
                       height: HEADER_HEIGHT,
                       size: 9,
                       align: :center,
                       valign: :center,
                       style: :bold
        end

        # =================================================================
        # LINHA DE CORTE PONTILHADA
        # =================================================================
        def draw_linha_corte(pdf)
          pdf.stroke do
            pdf.dash(2, space: 2)
            pdf.horizontal_line 0, pdf.bounds.width, at: pdf.cursor
            pdf.undash
          end
        end

        # =================================================================
        # LINHA DE CAMPOS COM LABEL (6pt) + VALOR (9pt)
        # =================================================================
        def draw_row(pdf, columns, height: ROW_HEIGHT)
          width = pdf.bounds.width
          y = pdf.cursor
          x_cursor = 0

          pdf.stroke_rectangle([0, y], width, height)

          columns.each_with_index do |col, index|
            col_width = (width * col[:width_ratio]).round(2)

            pdf.bounding_box([x_cursor, y], width: col_width, height: height) do
              # Label (no topo, pequeno)
              pdf.text_box col[:label].to_s,
                           at: [3, height - 3],
                           width: col_width - 6,
                           height: 8,
                           size: LABEL_SIZE,
                           overflow: :shrink_to_fit

              # Valor (centralizado/esquerda)
              align = col[:align] || :left
              pdf.text_box col[:value].to_s,
                           at: [3, height - 10],
                           width: col_width - 6,
                           height: height - 10,
                           size: VALUE_SIZE,
                           align: align,
                           overflow: :shrink_to_fit
            end

            # Separador vertical (exceto última coluna)
            pdf.stroke_vertical_line y, y - height, at: x_cursor + col_width unless index == columns.length - 1

            x_cursor += col_width
          end

          pdf.move_down height
        end

        # Monta as instruções do boleto concatenando instrucao1..instrucao6 ou usando
        # o campo `instrucoes` livre se presente.
        def montar_instrucoes(boleto)
          return boleto.instrucoes.to_s if boleto.instrucoes && !boleto.instrucoes.to_s.empty?

          [boleto.instrucao1, boleto.instrucao2, boleto.instrucao3,
           boleto.instrucao4, boleto.instrucao5, boleto.instrucao6].compact.reject(&:empty?).join("\n")
        end

        # =================================================================
        # CÓDIGO DE BARRAS + QR CODE PIX
        # =================================================================
        def draw_codigo_barras_e_pix(pdf, boleto)
          return unless boleto.codigo_barras

          y_start = pdf.cursor
          # Caixa do código de barras à esquerda
          barras_width = pdf.bounds.width - (boleto.emv ? 110 : 0)

          # Desenha código de barras Interleaved 2 of 5
          pdf.bounding_box([0, y_start], width: barras_width, height: 40) do
            barcode = Barby::Code25Interleaved.new(boleto.codigo_barras.to_s)
            barcode.annotate_pdf(pdf, height: 35, xdim: 0.9)
          end

          # QR Code PIX à direita (se disponível)
          return unless boleto.emv && emv_valido?(boleto.emv)

          pdf.bounding_box([barras_width + 10, y_start + 5], width: 100, height: 100) do
            qr_size = 85
            qrcode = RQRCode::QRCode.new(boleto.emv.to_s, level: :h)
            png = qrcode.as_png(size: 300, module_size: 6, border_modules: 1)

            pdf.image StringIO.new(png.to_s), width: qr_size, position: :center

            pdf.move_down 2
            pdf.text_box pix_label(boleto),
                         at: [0, -2],
                         width: 100,
                         height: 10,
                         size: 7,
                         align: :center,
                         style: :bold
          end
          pdf.move_down 50
        end

        def pix_label(boleto)
          return boleto.pix_label if boleto.respond_to?(:pix_label) && boleto.pix_label

          config_label = Brcobranca.configuration.respond_to?(:pix_label) ? Brcobranca.configuration.pix_label : nil
          config_label || 'Pague com PIX'
        end

        def emv_valido?(emv)
          return false if emv.nil? || emv.to_s.strip.empty?

          emv.to_s.start_with?('0002')
        end
      end
    end
  end
end
