# frozen_string_literal: true

require 'brcobranca/boleto/template/prawn_tema'

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
        # A fonte padrão (Helvetica/WinAnsi) cobre toda a acentuação PT-BR;
        # o aviso m17n do Prawn seria só ruído nos logs de produção.
        Prawn::Fonts::AFM.hide_m17n_warning = true if defined?(Prawn::Fonts::AFM)
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
        # Chips de resumo do Recibo do Pagador (Vencimento | Valor | Nosso número)
        CHIP_HEIGHT = 32

        # ==================== CORES ====================
        # Visual moderno: grade fina em cinza claro, muito branco, labels
        # discretos — os destaques ficam por conta dos valores em negrito
        # e do teal PIX (referência: boletos Efi/Asaas).
        # Cinza muito claro para fundo dos campos em destaque
        COR_FUNDO_DESTAQUE = 'F7F7F7'
        # Cinza para texto de labels
        COR_TEXTO_LABEL = '777777'
        # Preto para valores
        COR_TEXTO_VALOR = '000000'
        # Cinza claro para a grade de campos
        COR_BORDA = 'B3B3B3'
        # Cinza escuro para réguas fortes (linha sob o cabeçalho)
        COR_BORDA_FORTE = '333333'
        # Teal oficial da marca PIX (preenchimentos e molduras)
        COR_PIX = '32BCAD'
        # Teal escuro para texto PIX sobre fundo branco (contraste)
        COR_PIX_TEXTO = '0F7564'

        def to(formato, _options = {})
          unless PRAWN_AVAILABLE
            raise 'Prawn não está disponível. Instale: gem install prawn prawn-table barby rqrcode chunky_png'
          end

          unless formato.to_sym == :pdf
            raise ArgumentError,
                  "Formato #{formato} não suportado pelo PrawnBolepix (apenas :pdf)"
          end

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
          PrawnTema.aplica_fonte(pdf, boleto)
          draw_boleto(pdf, boleto)
          pdf.render
        end

        def render_boletos(boletos)
          pdf = new_document
          boletos.each_with_index do |boleto, index|
            PrawnTema.aplica_fonte(pdf, boleto)
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
          # Faixa de identidade visual da empresa (tema opcional — Fase 2a)
          PrawnTema.desenha_faixa(pdf, boleto, largura: pdf.bounds.width, titulo: boleto.cedente.to_s)
          y_inicio = pdf.cursor
          desenha_topo(pdf, boleto, titulo_direito: 'Recibo do Pagador')
          desenha_resumo_chips(pdf, boleto)
          desenha_zona_dados_e_pix(pdf, boleto)
          desenha_linha_sacado(pdf, boleto)
          desenha_linha_autenticacao_recibo(pdf)
          # Marca d'água diagonal (tema opcional): POR CIMA do conteúdo, na
          # cor da marca — o recibo não tem código de barras nem QR Code.
          PrawnTema.desenha_marca_dagua(pdf, boleto, largura: pdf.bounds.width,
                                                     y: y_inicio - 30, altura: y_inicio - pdf.cursor - 40)
        end

        # Faixa de resumo com 3 caixas destacadas: Vencimento | Valor | Nosso nº
        # (como as caixas Cobrança/Vencimento/Valor Final do boleto Efi):
        # borda fina cinza, label pequeno em caixa alta e valor grande em negrito.
        def desenha_resumo_chips(pdf, boleto)
          width = pdf.bounds.width
          y = pdf.cursor
          gap = 6
          chip_w = ((width - (gap * 2)) / 3.0).round(2)

          chips = [
            ['VENCIMENTO', boleto.data_vencimento.to_s_br],
            ['VALOR DO DOCUMENTO', boleto.valor_documento.to_currency],
            ['NOSSO NÚMERO', boleto.nosso_numero_boleto.to_s]
          ]

          pdf.stroke_color COR_BORDA
          pdf.line_width 0.6

          chips.each_with_index do |(label, valor), i|
            x = i * (chip_w + gap)

            pdf.fill_color COR_FUNDO_DESTAQUE
            pdf.fill_rectangle([x, y], chip_w, CHIP_HEIGHT)
            pdf.stroke_rectangle([x, y], chip_w, CHIP_HEIGHT)

            pdf.fill_color COR_TEXTO_LABEL
            pdf.text_box label,
                         at: [x + 8, y - 5], width: chip_w - 16, height: 7,
                         size: LABEL_SIZE, overflow: :shrink_to_fit
            pdf.fill_color COR_TEXTO_VALOR
            pdf.text_box valor,
                         at: [x + 8, y - 13], width: chip_w - 16, height: 15,
                         size: 12, style: :bold, overflow: :shrink_to_fit
          end

          pdf.line_width 0.5
          pdf.move_down CHIP_HEIGHT + 6
        end

        # Zona de dados do recibo (largura total, layout tradicional).
        # O QR Code PIX aparece apenas na Ficha de Compensação — padrão dos
        # bancos para o boleto híbrido (um único bloco PIX por documento).
        def desenha_zona_dados_e_pix(pdf, boleto)
          desenha_linha_beneficiario(pdf, boleto)
          desenha_linha_documento(pdf, boleto)
          desenha_linha_carteira(pdf, boleto)
          desenha_linha_totalizadores_recibo(pdf, boleto)
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
          y_inicio = pdf.cursor
          desenha_topo(pdf, boleto)
          desenha_linha_local_pagamento(pdf, boleto)
          desenha_linha_beneficiario(pdf, boleto)
          desenha_linha_documento(pdf, boleto)
          desenha_linha_carteira(pdf, boleto)
          y_antes_bloco = pdf.cursor
          desenha_bloco_instrucoes_totalizadores(pdf, boleto)
          desenha_linha_sacado(pdf, boleto)
          desenha_linha_sacador_avalista(pdf, boleto)
          desenha_codigo_barras_e_pix(pdf, boleto)
          # Marca d'água diagonal (tema opcional): POR CIMA do conteúdo, na
          # cor da marca — restrita às linhas de campos acima do bloco de
          # instruções (zona de exclusão do QR Code e do código de barras).
          PrawnTema.desenha_marca_dagua(pdf, boleto, largura: pdf.bounds.width,
                                                     y: y_inicio - 26,
                                                     altura: y_inicio - y_antes_bloco - 30,
                                                     tamanho: 26)
          # Rodapé de contato da empresa (tema opcional — Fase 2a),
          # abaixo da área do código de barras
          PrawnTema.desenha_rodape(pdf, boleto, largura: pdf.bounds.width, y: pdf.cursor - 6)
        end

        # Linha única de 5 totalizadores lado-a-lado (para o recibo, mais compacto)
        def desenha_linha_totalizadores_recibo(pdf, boleto)
          draw_row(pdf, [
                     { label: '(-) Desconto / Abatimento', value: boleto.descontos_e_abatimentos&.to_currency || '',
                       width_ratio: 0.20, align: :right },
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

          # Cabeçalho limpo (fundo branco): Logo | Código | Linha digitável,
          # separados por réguas verticais fortes e sublinhado por uma régua
          # forte — o visual clássico do topo de boleto, sem fundo sombreado.
          pdf.stroke_color COR_BORDA_FORTE
          pdf.line_width 0.8

          # Logo do banco (se houver PNG) ou texto como fallback
          PrawnTema.desenha_logo_banco_prawn(pdf, boleto, 0, y, logo_w, HEADER_HEIGHT)

          pdf.fill_color COR_TEXTO_VALOR
          pdf.text_box "#{boleto.banco}-#{boleto.banco_dv}",
                       at: [logo_w, y - 4],
                       width: codigo_w,
                       height: HEADER_HEIGHT,
                       size: CODIGO_BANCO_SIZE,
                       align: :center,
                       valign: :center,
                       style: :bold

          pdf.text_box boleto.codigo_barras.linha_digitavel,
                       at: [logo_w + codigo_w + 5, y - 4],
                       width: width - logo_w - codigo_w - 10,
                       height: HEADER_HEIGHT,
                       size: LINHA_DIG_SIZE,
                       align: :right,
                       valign: :center,
                       style: :bold

          # Réguas verticais fortes entre logo, código e linha digitável
          pdf.stroke_vertical_line y - 2, y - HEADER_HEIGHT + 4, at: logo_w
          pdf.stroke_vertical_line y - 2, y - HEADER_HEIGHT + 4, at: logo_w + codigo_w

          # Régua forte sob o cabeçalho
          pdf.line_width 1.1
          pdf.stroke_horizontal_line 0, width, at: y - HEADER_HEIGHT
          pdf.line_width 0.5
          pdf.stroke_color COR_BORDA

          pdf.move_down HEADER_HEIGHT + 2
        end

        def desenha_linha_local_pagamento(pdf, boleto)
          draw_row(pdf, [
                     { label: 'Local de pagamento', value: boleto.local_pagamento.to_s, width_ratio: 0.75,
                       value_style: :bold },
                     { label: 'Vencimento', value: boleto.data_vencimento.to_s_br, width_ratio: 0.25, value_style: :bold,
                       destaque: true }
                   ])
        end

        def desenha_linha_beneficiario(pdf, boleto)
          benef_texto = montar_beneficiario(boleto)
          draw_row(pdf, [
                     { label: 'Beneficiário', value: benef_texto, width_ratio: 0.75, value_style: :bold, multiline: true },
                     { label: 'Valor do Documento', value: boleto.valor_documento.to_currency, width_ratio: 0.25,
                       value_style: :bold, destaque: true }
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
                     { label: 'Cooperativa contratante/Cód. Beneficiário',
                       value: (boleto.agencia_conta_boleto || '').to_s.gsub(%r{\s+/\s+}, '/'), width_ratio: 0.35 }
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
                     { label: 'Valor', value: (boleto.valor.to_f.positive? ? boleto.valor.to_f.to_currency : ''),
                       width_ratio: 0.14 },
                     { label: 'Nosso número', value: boleto.nosso_numero_boleto.to_s, width_ratio: 0.35 }
                   ])
        end

        def desenha_bloco_instrucoes_totalizadores(pdf, boleto)
          width = pdf.bounds.width
          y = pdf.cursor
          tem_pix = boleto.emv && PrawnTema.emv_valido?(boleto.emv)

          # Com PIX, o bloco ganha uma célula central para o QR Code
          # (integrado ao grid da ficha, como nos boletos modernos):
          #   [ Instruções 57% | Pague com Pix 18% | Totalizadores 25% ]
          # Sem PIX: [ Instruções 75% | Totalizadores 25% ]
          # Os totalizadores usam 25% para alinhar com a coluna de
          # Vencimento/Valor do Documento das linhas acima (régua em 75%),
          # deixando o máximo de espaço para as instruções.
          pix_width = tem_pix ? width * 0.18 : 0
          right_width = width * 0.25
          left_width = width - right_width - pix_width
          # Com PIX o bloco é mais alto (6 módulos), garantindo QR Code de
          # ~2,7 cm legível também em tela; os 5 totalizadores se distribuem
          # proporcionalmente na nova altura.
          altura = tem_pix ? TOTALIZADORES_HEIGHT * 6 : BLOCO_INSTRUCOES_ALTURA
          total_row_h = altura / 5.0

          # Borda externa do bloco (grade fina clara, fundo branco)
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

          # Célula central "Pague com Pix" (somente quando há EMV)
          if tem_pix
            desenha_celula_pix(pdf, boleto, x: left_width, y: y, largura: pix_width, altura: altura)
            pdf.stroke_vertical_line y, y - altura, at: left_width + pix_width
          end

          # Coluna direita: 5 totalizadores empilhados
          total_x = left_width + pix_width
          totalizadores = [
            ['(-) Desconto / Abatimento', boleto.descontos_e_abatimentos&.to_currency || ''],
            ['(-) Outras deduções', ''],
            ['(+) Mora / Multa', ''],
            ['(+) Outros Acréscimos', ''],
            ['(=) Valor cobrado', '']
          ]
          totalizadores.each_with_index do |(label, valor), i|
            top = y - (i * total_row_h)

            # Label (esquerda, pequeno)
            pdf.fill_color COR_TEXTO_LABEL
            pdf.text_box label,
                         at: [total_x + 4, top - 3],
                         width: right_width - 8,
                         height: 8,
                         size: LABEL_SIZE
            pdf.fill_color COR_TEXTO_VALOR

            # Valor (alinhado à direita)
            pdf.text_box valor,
                         at: [total_x + 4, top - 12],
                         width: right_width - 8,
                         height: 9,
                         size: VALUE_SIZE,
                         align: :right

            # Separador horizontal entre totalizadores (exceto último) —
            # começa em total_x para não cruzar a célula do QR Code PIX
            pdf.stroke_horizontal_line total_x, width, at: top - total_row_h if i < totalizadores.length - 1
          end

          pdf.move_down altura
        end

        def montar_instrucoes(boleto)
          return boleto.instrucoes.to_s if boleto.instrucoes && !boleto.instrucoes.to_s.strip.empty?

          [boleto.instrucao1, boleto.instrucao2, boleto.instrucao3,
           boleto.instrucao4, boleto.instrucao5, boleto.instrucao6].compact.reject { |l| l.to_s.strip.empty? }.join("\n")
        end

        # Célula "Pague com Pix" integrada ao bloco de instruções da ficha:
        # cabeçalho no teal PIX, QR Code centralizado e nota de confirmação.
        def desenha_celula_pix(pdf, boleto, x:, y:, largura:, altura:)
          header_h = 10

          # Cabeçalho preenchido no teal PIX (mesma altura da zona de labels)
          pdf.fill_color COR_PIX
          pdf.fill_rectangle([x, y], largura, header_h)
          pdf.fill_color 'FFFFFF'
          pdf.text_box PrawnTema.resolve_pix_label(boleto).upcase,
                       at: [x, y - 2], width: largura, height: 8,
                       size: 6, style: :bold, align: :center

          # QR Code centralizado na célula (vetorial, compartilhado no PrawnTema),
          # com folga em todos os lados — a leitura tem prioridade sobre legendas.
          qr_size = [altura - header_h - 4, largura - 4].min
          qr_x = x + ((largura - qr_size) / 2.0)
          PrawnTema.desenha_qr_vetorial(pdf, boleto.emv.to_s, x: qr_x, y: y - header_h - 3, tamanho: qr_size)
          pdf.fill_color COR_TEXTO_VALOR
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

          # Grade fina e clara, fundo branco — labels pequenos em cinza fazem o
          # papel de "cabeçalho de campo" sem faixas sombreadas.
          pdf.stroke_color COR_BORDA
          pdf.stroke_rectangle([0, y], width, height)

          columns.each_with_index do |col, index|
            col_width = (width * col[:width_ratio]).round(2)

            # Destaque especial: fundo leve para campos destacados (ex.: Vencimento, Valor)
            if col[:destaque]
              pdf.fill_color COR_FUNDO_DESTAQUE
              pdf.fill_rectangle([x_cursor, y], col_width, height)
              pdf.fill_color COR_TEXTO_VALOR
            end

            # Label (topo, pequeno, cinza)
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

        # Código de barras I2/5 na base da ficha. O QR Code PIX fica na célula
        # central do bloco de instruções (desenha_celula_pix) — aqui o barcode
        # ocupa a largura padrão com a autenticação mecânica à direita.
        def desenha_codigo_barras_e_pix(pdf, boleto)
          return unless boleto.codigo_barras

          width = pdf.bounds.width
          y_start = pdf.cursor
          # 68%% de largura prioriza a leitura do I2/5 tambem em tela
          # (mesma otimizacao aplicada ao carne).
          barras_width = width * 0.68
          direita_x = barras_width + 10

          pdf.bounding_box([0, y_start], width: barras_width, height: BARCODE_HEIGHT) do
            barcode = Barby::Code25Interleaved.new(boleto.codigo_barras.to_s)
            # xdim calculado para o barcode caber na caixa com zona de
            # silêncio (8pt), garantindo a leitura do I2/5.
            modules = barcode.encoding.length
            xdim = [(barras_width - 8).to_f / modules, 0.9].min
            barcode.annotate_pdf(pdf, height: BARCODE_HEIGHT - 5, xdim: xdim)
          end

          pdf.fill_color COR_TEXTO_LABEL
          pdf.text_box 'Autenticação mecânica - Ficha de Compensação',
                       at: [direita_x, y_start - 5],
                       width: width - direita_x,
                       height: 15,
                       size: 7,
                       align: :right,
                       valign: :top
          pdf.fill_color COR_TEXTO_VALOR

          # O bounding_box do barcode já desceu o cursor em BARCODE_HEIGHT;
          # aqui apenas o respiro final (evita dobrar o deslocamento e afastar
          # demais o rodapé de contato do tema).
          pdf.move_down 8
        end

      end
    end
  end
end
