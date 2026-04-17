# frozen_string_literal: true

# Template alternativo para geração de boletos híbridos (com PIX) usando Prawn.
#
# Layout espelhado do padrão FEBRABAN observado em boletos SICOOB e demais bancos,
# com:
#   - Topo: Logo | Código do banco | Linha digitável
#   - Local de pagamento | Vencimento
#   - Beneficiário (com endereço) | Valor do Documento
#   - Data Doc | Nº Doc | Espécie | Aceite | Data Processamento | Cooperativa/Cód. Beneficiário
#   - Uso do banco | Carteira | Espécie | Quantidade | Valor | Nosso Número
#   - Instruções (coluna esquerda) + Totalizadores empilhados (coluna direita)
#   - Sacado (nome + endereço)
#   - Sacador/Avalista | Cód. Baixa
#   - Código de barras + [QR Code PIX se aplicável] + Autenticação mecânica
#
# Requer as gems: prawn, prawn-table, barby, rqrcode, chunky_png.
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

      # Template Prawn para boletos híbridos com PIX - layout FEBRABAN.
      module PrawnBolepix
        extend self

        PAGE_MARGIN = 25
        LABEL_SIZE = 6
        VALUE_SIZE = 9
        LINHA_DIG_SIZE = 13
        CODIGO_BANCO_SIZE = 15
        HEADER_HEIGHT = 28
        ROW_HEIGHT = 22
        ROW_BENEF_HEIGHT = 34
        TOTALIZADORES_HEIGHT = 16
        # Altura do bloco suporta 7 linhas de 11pt = 77pt, + margem = ~80pt
        # Isso é igual a 5 totalizadores de 16pt = 80pt (permite alinhamento perfeito)
        BLOCO_INSTRUCOES_ALTURA = TOTALIZADORES_HEIGHT * 5
        INSTRUCOES_LINHA_ALTURA = 10
        INSTRUCOES_LINHAS_MAX = 7
        BARCODE_HEIGHT = 48
        QRCODE_SIZE = 85

        # ==================== CORES ====================
        # Cinza muito claro para fundos de cabeçalhos/labels
        COR_FUNDO_LABEL = 'F5F5F5'
        # Cinza claro para cabeçalho principal (barra de topo)
        COR_FUNDO_CABECALHO = 'EEEEEE'
        # Cinza para texto de labels
        COR_TEXTO_LABEL = '555555'
        # Preto para valores
        COR_TEXTO_VALOR = '000000'
        # Cinza para bordas
        COR_BORDA = '333333'
        # Verde escuro (tipo Sicoob) para destaque do PIX
        COR_PIX = '006B3F'

        def to(formato, _options = {})
          raise 'Prawn não está disponível. Instale: gem install prawn prawn-table barby rqrcode chunky_png' unless PRAWN_AVAILABLE
          raise ArgumentError, "Formato #{formato} não suportado pelo PrawnBolepix (apenas :pdf)" unless formato.to_sym == :pdf

          render_boleto(self)
        end

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

        def render_boleto(boleto)
          pdf = new_document
          draw_boleto(pdf, boleto)
          pdf.render
        end

        def render_boletos(boletos)
          pdf = new_document
          boletos.each_with_index do |boleto, index|
            draw_boleto(pdf, boleto)
            pdf.start_new_page unless index == boletos.length - 1
          end
          pdf.render
        end

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

        def draw_boleto(pdf, boleto)
          # 1) Recibo do Pagador (topo, versão compacta sem código de barras)
          desenha_recibo_pagador(pdf, boleto)

          # 2) Linha de corte pontilhada
          desenha_linha_corte(pdf)

          # 3) Ficha de Compensação (abaixo, versão completa com código de barras + PIX)
          desenha_ficha_compensacao(pdf, boleto)
        end

        # =================================================================
        # RECIBO DO PAGADOR (parte superior do boleto)
        # =================================================================
        # Layout simplificado, sem "Local de pagamento" e sem código de barras.
        # Contém: topo, beneficiário, dados do documento, carteira, sacado,
        # instruções reduzidas e autenticação mecânica (Recibo do Pagador).
        def desenha_recibo_pagador(pdf, boleto)
          desenha_topo(pdf, boleto, titulo_direito: 'Recibo do Pagador')
          desenha_linha_beneficiario(pdf, boleto)
          desenha_linha_documento(pdf, boleto)
          desenha_linha_carteira(pdf, boleto)
          desenha_linha_totalizadores_recibo(pdf, boleto)
          desenha_linha_sacado(pdf, boleto)
          desenha_linha_autenticacao_recibo(pdf)
        end

        # Linha pontilhada de corte entre o Recibo do Pagador e a Ficha de
        # Compensação. Inclui um pequeno texto "Corte aqui" no canto.
        def desenha_linha_corte(pdf)
          pdf.move_down 6
          y = pdf.cursor
          width = pdf.bounds.width

          pdf.stroke_color COR_TEXTO_LABEL
          pdf.line_width 0.5
          pdf.dash(2, space: 2)
          pdf.stroke_horizontal_line 0, width, at: y
          pdf.undash

          # Texto "Corte aqui"
          pdf.fill_color COR_TEXTO_LABEL
          pdf.text_box 'Corte aqui --->',
                       at: [width - 60, y + 3],
                       width: 60,
                       height: 8,
                       size: 6,
                       align: :right
          pdf.fill_color COR_TEXTO_VALOR

          pdf.stroke_color COR_BORDA
          pdf.move_down 6
        end

        # Ficha de Compensação (a parte do boleto que é realmente paga).
        def desenha_ficha_compensacao(pdf, boleto)
          desenha_topo(pdf, boleto)
          desenha_linha_local_pagamento(pdf, boleto)
          desenha_linha_beneficiario(pdf, boleto)
          desenha_linha_documento(pdf, boleto)
          desenha_linha_carteira(pdf, boleto)
          desenha_bloco_instrucoes_totalizadores(pdf, boleto)
          desenha_linha_sacado(pdf, boleto)
          desenha_linha_sacador_avalista(pdf, boleto)
          desenha_codigo_barras_e_pix(pdf, boleto)
        end

        # Linha única de 5 totalizadores lado-a-lado (para o recibo, mais compacto)
        def desenha_linha_totalizadores_recibo(pdf, boleto)
          draw_row(pdf, [
                     { label: '(-) Desconto / Abatimento', value: boleto.descontos_e_abatimentos&.to_currency || '', width_ratio: 0.20, align: :right },
                     { label: '(-) Outras deduções', value: '', width_ratio: 0.20, align: :right },
                     { label: '(+) Mora / Multa', value: '', width_ratio: 0.20, align: :right },
                     { label: '(+) Outros Acréscimos', value: '', width_ratio: 0.20, align: :right },
                     { label: '(=) Valor cobrado', value: '', width_ratio: 0.20, align: :right }
                   ])
        end

        # Linha de autenticação mecânica do recibo (no canto direito).
        def desenha_linha_autenticacao_recibo(pdf)
          y = pdf.cursor
          width = pdf.bounds.width
          altura = ROW_HEIGHT * 0.85

          pdf.stroke_color COR_BORDA
          pdf.stroke_rectangle([0, y], width, altura)

          pdf.fill_color COR_TEXTO_LABEL
          pdf.text_box 'Autenticação mecânica - Recibo do Pagador',
                       at: [4, y - 4],
                       width: width - 8,
                       height: altura - 4,
                       size: 7,
                       align: :right,
                       valign: :top
          pdf.fill_color COR_TEXTO_VALOR

          pdf.move_down altura
        end

        # Desenha o topo do boleto: Logo | Código banco-DV | Linha digitável.
        #
        # @param titulo_direito [String, nil] Texto pequeno acima da linha
        #   digitável (ex: "Recibo do Pagador"). Útil para diferenciar recibo
        #   da ficha de compensação.
        def desenha_topo(pdf, boleto, titulo_direito: nil)
          width = pdf.bounds.width
          y_topo = pdf.cursor

          # Se houver título (ex: "Recibo do Pagador"), reserva 10pt acima para ele
          if titulo_direito
            pdf.fill_color COR_TEXTO_LABEL
            pdf.text_box titulo_direito,
                         at: [0, y_topo - 1],
                         width: width - 4,
                         height: 9,
                         size: 7,
                         align: :right,
                         style: :italic
            pdf.fill_color COR_TEXTO_VALOR
            pdf.move_down 10
          end

          y = pdf.cursor
          logo_w = 80
          codigo_w = 55

          pdf.stroke_color COR_BORDA
          pdf.line_width 0.5

          # Fundo sombreado no topo (cinza claro)
          pdf.fill_color COR_FUNDO_CABECALHO
          pdf.fill_rectangle([0, y], width, HEADER_HEIGHT)
          pdf.fill_color COR_TEXTO_VALOR

          # Logo do banco (se houver PNG) ou texto como fallback
          desenha_logo_banco(pdf, boleto, 0, y, logo_w, HEADER_HEIGHT)

          # Código do banco - DV (centro, destaque)
          pdf.fill_color 'FFFFFF'
          pdf.fill_rectangle([logo_w, y], codigo_w, HEADER_HEIGHT)
          pdf.fill_color COR_TEXTO_VALOR

          pdf.text_box "#{boleto.banco}-#{boleto.banco_dv}",
                       at: [logo_w, y - 4],
                       width: codigo_w,
                       height: HEADER_HEIGHT,
                       size: CODIGO_BANCO_SIZE,
                       align: :center,
                       valign: :center,
                       style: :bold

          # Linha digitável (direita, fundo branco)
          pdf.fill_color 'FFFFFF'
          pdf.fill_rectangle([logo_w + codigo_w, y], width - logo_w - codigo_w, HEADER_HEIGHT)
          pdf.fill_color COR_TEXTO_VALOR

          pdf.text_box boleto.codigo_barras.linha_digitavel,
                       at: [logo_w + codigo_w + 5, y - 4],
                       width: width - logo_w - codigo_w - 10,
                       height: HEADER_HEIGHT,
                       size: LINHA_DIG_SIZE,
                       align: :right,
                       valign: :center,
                       style: :bold

          # Bordas verticais internas
          pdf.stroke_color COR_BORDA
          pdf.stroke_vertical_line y, y - HEADER_HEIGHT, at: logo_w
          pdf.stroke_vertical_line y, y - HEADER_HEIGHT, at: logo_w + codigo_w

          # Borda inferior grossa (destaca o header)
          pdf.line_width 1.2
          pdf.stroke_horizontal_line 0, width, at: y - HEADER_HEIGHT
          pdf.line_width 0.5

          pdf.move_down HEADER_HEIGHT
        end

        def desenha_logo_banco(pdf, boleto, x, y, col_width, altura)
          png_path = boleto.logotipo.sub(/\.eps\z/, '.png')
          if File.exist?(png_path)
            pdf.image png_path, at: [x + 2, y - 2], height: altura - 6, width: col_width - 4
          else
            pdf.text_box nome_banco_para_logo(boleto),
                         at: [x, y - 6],
                         width: col_width,
                         height: altura,
                         size: 8,
                         align: :center,
                         valign: :center,
                         style: :bold
          end
        rescue StandardError
          pdf.text_box nome_banco_para_logo(boleto),
                       at: [x, y - 6],
                       width: col_width,
                       height: altura,
                       size: 8,
                       align: :center,
                       valign: :center,
                       style: :bold
        end

        # Nome do banco para fallback do logo (quando não há PNG).
        def nome_banco_para_logo(boleto)
          if boleto.respond_to?(:banco_nome) && boleto.banco_nome
            boleto.banco_nome.to_s.upcase
          else
            boleto.class.to_s.split('::').last.upcase
          end
        end

        def desenha_linha_local_pagamento(pdf, boleto)
          draw_row(pdf, [
                     { label: 'Local de pagamento', value: boleto.local_pagamento.to_s, width_ratio: 0.75, value_style: :bold },
                     { label: 'Vencimento', value: boleto.data_vencimento.to_s_br, width_ratio: 0.25, value_style: :bold, destaque: true }
                   ])
        end

        def desenha_linha_beneficiario(pdf, boleto)
          benef_texto = montar_beneficiario(boleto)
          draw_row(pdf, [
                     { label: 'Beneficiário', value: benef_texto, width_ratio: 0.75, value_style: :bold, multiline: true },
                     { label: 'Valor do Documento', value: boleto.valor_documento.to_currency, width_ratio: 0.25, value_style: :bold, destaque: true }
                   ], height: ROW_BENEF_HEIGHT)
        end

        def montar_beneficiario(boleto)
          partes = []
          if boleto.cedente && boleto.documento_cedente
            partes << "#{boleto.cedente} - CNPJ/CPF: #{boleto.documento_cedente.to_s.formata_documento}"
          elsif boleto.cedente
            partes << boleto.cedente
          end
          partes << boleto.cedente_endereco.to_s if boleto.cedente_endereco
          partes.join("\n")
        end

        def desenha_linha_documento(pdf, boleto)
          draw_row(pdf, [
                     { label: 'Data do documento', value: boleto.data_documento&.to_s_br || '', width_ratio: 0.14 },
                     { label: 'N. do Documento', value: boleto.documento_numero.to_s, width_ratio: 0.22 },
                     { label: 'Espécie', value: boleto.especie_documento.to_s, width_ratio: 0.08 },
                     { label: 'Aceite', value: boleto.aceite.to_s, width_ratio: 0.07 },
                     { label: 'Data Processamento', value: boleto.data_processamento&.to_s_br || '', width_ratio: 0.14 },
                     { label: 'Cooperativa contratante/Cód. Beneficiário', value: (boleto.agencia_conta_boleto || '').to_s.gsub(/\s+\/\s+/, '/'), width_ratio: 0.35 }
                   ])
        end

        def desenha_linha_carteira(pdf, boleto)
          # Mostra apenas "carteira" quando a variacao é "01" (default comum),
          # ou "carteira/variacao" quando a variacao é explicitamente outra.
          carteira_txt = if boleto.variacao && boleto.variacao.to_s != '01'
                           "#{boleto.carteira}/#{boleto.variacao}"
                         else
                           boleto.carteira.to_s
                         end
          draw_row(pdf, [
                     { label: 'Uso do banco', value: '', width_ratio: 0.14 },
                     { label: 'Carteira', value: carteira_txt, width_ratio: 0.22 },
                     { label: 'Espécie', value: boleto.especie.to_s, width_ratio: 0.08 },
                     { label: 'Quantidade', value: boleto.quantidade.to_s, width_ratio: 0.07 },
                     { label: 'Valor', value: (boleto.valor.to_f.positive? ? boleto.valor.to_f.to_currency : ''), width_ratio: 0.14 },
                     { label: 'Nosso número', value: boleto.nosso_numero_boleto.to_s, width_ratio: 0.35 }
                   ])
        end

        def desenha_bloco_instrucoes_totalizadores(pdf, boleto)
          width = pdf.bounds.width
          y = pdf.cursor
          left_width = width * 0.65
          right_width = width * 0.35
          altura = BLOCO_INSTRUCOES_ALTURA

          # Faixa cinza clara no topo (label)
          label_stripe_height = 10
          pdf.fill_color COR_FUNDO_LABEL
          pdf.fill_rectangle([0, y], left_width, label_stripe_height)
          pdf.fill_color COR_TEXTO_VALOR

          # Borda externa do bloco
          pdf.stroke_color COR_BORDA
          pdf.stroke_rectangle([0, y], width, altura)

          # Label da coluna de instruções
          pdf.fill_color COR_TEXTO_LABEL
          pdf.text_box 'Instruções (Texto de responsabilidade do beneficiário)',
                       at: [4, y - 3],
                       width: left_width - 8,
                       height: 8,
                       size: LABEL_SIZE
          pdf.fill_color COR_TEXTO_VALOR

          # Área de instruções: suporta até INSTRUCOES_LINHAS_MAX (7) linhas de texto
          instrucoes = montar_instrucoes(boleto)
          area_instrucoes_altura = INSTRUCOES_LINHA_ALTURA * INSTRUCOES_LINHAS_MAX
          # Garante que a área não exceda o bloco
          area_instrucoes_altura = [area_instrucoes_altura, altura - 14].min

          pdf.text_box instrucoes,
                       at: [4, y - 12],
                       width: left_width - 8,
                       height: area_instrucoes_altura,
                       size: VALUE_SIZE,
                       leading: 1,
                       overflow: :shrink_to_fit

          # Separador vertical entre colunas
          pdf.stroke_vertical_line y, y - altura, at: left_width

          # Coluna direita: 5 totalizadores empilhados
          totalizadores = [
            ['(-) Desconto / Abatimento', boleto.descontos_e_abatimentos&.to_currency || ''],
            ['(-) Outras deduções', ''],
            ['(+) Mora / Multa', ''],
            ['(+) Outros Acréscimos', ''],
            ['(=) Valor cobrado', '']
          ]
          totalizadores.each_with_index do |(label, valor), i|
            top = y - (i * TOTALIZADORES_HEIGHT)

            # Faixa cinza clara de label
            pdf.fill_color COR_FUNDO_LABEL
            pdf.fill_rectangle([left_width, top], right_width, label_stripe_height)
            pdf.fill_color COR_TEXTO_VALOR

            # Label (esquerda, pequeno)
            pdf.fill_color COR_TEXTO_LABEL
            pdf.text_box label,
                         at: [left_width + 4, top - 3],
                         width: right_width - 8,
                         height: 8,
                         size: LABEL_SIZE
            pdf.fill_color COR_TEXTO_VALOR

            # Valor (alinhado à direita)
            pdf.text_box valor,
                         at: [left_width + 4, top - 12],
                         width: right_width - 8,
                         height: 9,
                         size: VALUE_SIZE,
                         align: :right

            # Separador horizontal entre totalizadores (exceto último)
            pdf.stroke_horizontal_line left_width, width, at: top - TOTALIZADORES_HEIGHT if i < totalizadores.length - 1
          end

          pdf.move_down altura
        end

        def montar_instrucoes(boleto)
          return boleto.instrucoes.to_s if boleto.instrucoes && !boleto.instrucoes.to_s.strip.empty?

          [boleto.instrucao1, boleto.instrucao2, boleto.instrucao3,
           boleto.instrucao4, boleto.instrucao5, boleto.instrucao6].compact.reject { |l| l.to_s.strip.empty? }.join("\n")
        end

        def desenha_linha_sacado(pdf, boleto)
          partes = []
          if boleto.sacado && boleto.sacado_documento
            partes << "#{boleto.sacado} - #{boleto.sacado_documento.to_s.formata_documento}"
          elsif boleto.sacado
            partes << boleto.sacado
          end
          partes << boleto.sacado_endereco.to_s if boleto.sacado_endereco

          draw_row(pdf, [
                     { label: 'Sacado', value: partes.join("\n"), width_ratio: 1.0, value_style: :bold, multiline: true }
                   ], height: ROW_BENEF_HEIGHT)
        end

        def desenha_linha_sacador_avalista(pdf, boleto)
          avalista = if boleto.avalista && boleto.avalista_documento
                       "#{boleto.avalista} - #{boleto.avalista_documento}"
                     else
                       ''
                     end
          draw_row(pdf, [
                     { label: 'Sacador/Avalista', value: avalista, width_ratio: 0.80 },
                     { label: 'Cód. baixa', value: '', width_ratio: 0.20 }
                   ], height: ROW_HEIGHT * 0.85)
        end

        def draw_row(pdf, columns, height: ROW_HEIGHT)
          width = pdf.bounds.width
          y = pdf.cursor
          x_cursor = 0

          # Faixa cinza clara na parte superior de cada célula (onde fica o label)
          # Dá o efeito visual de "cabeçalho de campo" característico do boleto
          label_stripe_height = 10
          pdf.fill_color COR_FUNDO_LABEL
          pdf.fill_rectangle([0, y], width, label_stripe_height)
          pdf.fill_color COR_TEXTO_VALOR

          # Borda externa do retângulo
          pdf.stroke_color COR_BORDA
          pdf.stroke_rectangle([0, y], width, height)

          columns.each_with_index do |col, index|
            col_width = (width * col[:width_ratio]).round(2)

            # Destaque especial: fundo leve para campos destacados (ex.: Vencimento, Valor)
            if col[:destaque]
              pdf.fill_color COR_FUNDO_CABECALHO
              pdf.fill_rectangle([x_cursor, y], col_width, height)
              pdf.fill_color COR_TEXTO_VALOR
              # Redesenha a faixa do label por cima do destaque
              pdf.fill_color COR_FUNDO_LABEL
              pdf.fill_rectangle([x_cursor, y], col_width, label_stripe_height)
              pdf.fill_color COR_TEXTO_VALOR
            end

            # Label (topo, pequeno, cinza escuro)
            pdf.fill_color COR_TEXTO_LABEL
            pdf.text_box col[:label].to_s,
                         at: [x_cursor + 4, y - 3],
                         width: col_width - 8,
                         height: 8,
                         size: LABEL_SIZE,
                         overflow: :shrink_to_fit
            pdf.fill_color COR_TEXTO_VALOR

            # Valor
            align = col[:align] || :left
            value_style = col[:value_style]
            text_opts = {
              at: [x_cursor + 4, y - 12],
              width: col_width - 8,
              height: height - 14,
              size: VALUE_SIZE,
              align: align,
              overflow: :shrink_to_fit
            }
            text_opts[:style] = value_style if value_style

            pdf.text_box col[:value].to_s, **text_opts

            # Separador vertical entre colunas (exceto a última)
            pdf.stroke_vertical_line y, y - height, at: x_cursor + col_width unless index == columns.length - 1

            x_cursor += col_width
          end

          pdf.move_down height
        end

        def desenha_codigo_barras_e_pix(pdf, boleto)
          return unless boleto.codigo_barras

          width = pdf.bounds.width
          y_start = pdf.cursor
          tem_pix = boleto.emv && emv_valido?(boleto.emv)

          barras_width = tem_pix ? width * 0.55 : width * 0.60
          direita_x = barras_width + 10

          pdf.bounding_box([0, y_start], width: barras_width, height: BARCODE_HEIGHT) do
            barcode = Barby::Code25Interleaved.new(boleto.codigo_barras.to_s)
            barcode.annotate_pdf(pdf, height: BARCODE_HEIGHT - 5, xdim: 0.9)
          end

          if tem_pix
            qr_x = direita_x
            # Renderiza QR Code diretamente sem usar bounding_box (evita double-move)
            qrcode = RQRCode::QRCode.new(boleto.emv.to_s, level: :h)
            png = qrcode.as_png(size: 300, module_size: 6, border_modules: 1)

            pdf.image StringIO.new(png.to_s),
                      at: [qr_x, y_start],
                      width: QRCODE_SIZE

            # Label "Pague com PIX" em verde, centralizado abaixo do QR Code
            pdf.fill_color COR_PIX
            pdf.text_box pix_label(boleto),
                         at: [qr_x, y_start - QRCODE_SIZE - 2],
                         width: QRCODE_SIZE,
                         height: 10,
                         size: 8,
                         align: :center,
                         style: :bold
            pdf.fill_color COR_TEXTO_VALOR

            # Autenticação mecânica (direita do QR Code)
            autent_x = qr_x + QRCODE_SIZE + 10
            pdf.fill_color COR_TEXTO_LABEL
            pdf.text_box 'Autenticação mecânica - Ficha de Compensação',
                         at: [autent_x, y_start - 5],
                         width: width - autent_x,
                         height: 15,
                         size: 7,
                         align: :right,
                         valign: :top
            pdf.fill_color COR_TEXTO_VALOR
          else
            # Autenticação mecânica (toda a direita)
            pdf.fill_color COR_TEXTO_LABEL
            pdf.text_box 'Autenticação mecânica - Ficha de Compensação',
                         at: [direita_x, y_start - 5],
                         width: width - direita_x,
                         height: 15,
                         size: 7,
                         align: :right,
                         valign: :top
            pdf.fill_color COR_TEXTO_VALOR
          end

          pdf.move_down BARCODE_HEIGHT + 8
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
