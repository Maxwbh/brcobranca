# frozen_string_literal: true

require 'brcobranca/boleto/template/prawn_tema'

# Template Prawn para carnê de pagamento (Fase 1).
#
# Espelha o modelo do RGhost carnê (assets/templates/modelo_carne.eps):
#   - Cada boleto ocupa uma faixa de 21 x 9 cm
#   - Canhoto destacável à esquerda (~4,2 cm) com os dados essenciais
#   - Linha vertical pontilhada de corte entre canhoto e ficha
#   - Ficha de Compensação à direita (FEBRABAN) com código de barras
#   - QR Code PIX na ficha quando `boleto.emv` estiver presente
#   - `lote_carne`: 3 boletos por página A4, separados por linha pontilhada
#
# Requer as gems: prawn, barby, rqrcode, chunky_png (mesmas do PrawnBolepix).
module Brcobranca
  module Boleto
    module Template
      # Disponibilidade das gems (compartilhada com PrawnBolepix).
      unless defined?(PRAWN_AVAILABLE)
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
      end

      # Carnê de pagamento via Prawn — canhoto + ficha, 3 por página A4.
      module PrawnCarne
        extend self

        # Dimensões da faixa do carnê (21 x 9 cm em points)
        STRIP_WIDTH = 595.28
        STRIP_HEIGHT = 255.12
        STRIP_MARGIN = 14
        CANHOTO_WIDTH = 118
        CORTE_GAP = 8

        LABEL_SIZE = 5
        VALUE_SIZE = 8
        ROW_H = 17
        HEADER_H = 20
        BARCODE_H = 32
        QRCODE_W = 68

        # Visual moderno (mesma linguagem do PrawnBolepix): grade fina em cinza
        # claro, fundo branco, labels discretos e teal oficial PIX.
        COR_FUNDO_DESTAQUE = 'F7F7F7'
        COR_TEXTO_LABEL = '777777'
        COR_TEXTO_VALOR = '000000'
        COR_BORDA = 'B3B3B3'
        COR_BORDA_FORTE = '333333'
        COR_PIX = '32BCAD'

        # Gera um único boleto em página 21x9cm (mesmo papel do RGhost carnê).
        def to_carne(formato, _options = {})
          unless PRAWN_AVAILABLE
            raise 'Prawn não está disponível. Instale: gem install prawn prawn-table barby rqrcode chunky_png'
          end
          raise ArgumentError, "Formato #{formato} não suportado pelo PrawnCarne (apenas :pdf)" unless formato.to_sym == :pdf

          pdf = Prawn::Document.new(
            page_size: [STRIP_WIDTH, STRIP_HEIGHT],
            margin: [STRIP_MARGIN, STRIP_MARGIN, STRIP_MARGIN, STRIP_MARGIN],
            info: documento_info
          )
          PrawnTema.aplica_fonte(pdf, self)
          desenha_carne(pdf, self)
          pdf.render
        end

        # Gera múltiplos boletos: 3 por página A4, separados por linha de corte.
        def lote_carne(boletos, _options = {})
          raise 'Prawn não está disponível.' unless PRAWN_AVAILABLE

          pdf = Prawn::Document.new(page_size: 'A4', margin: [16, 16, 16, 16], info: documento_info)
          altura_util = STRIP_HEIGHT - (2 * STRIP_MARGIN)
          PrawnTema.aplica_fonte(pdf, boletos.first) if boletos.any?

          boletos.each_with_index do |boleto, index|
            posicao = index % 3
            pdf.start_new_page if index.positive? && posicao.zero?

            topo = pdf.bounds.height - (posicao * (altura_util + 24))
            pdf.bounding_box([0, topo], width: pdf.bounds.width, height: altura_util) do
              desenha_carne(pdf, boleto)
            end

            desenha_corte_horizontal(pdf, topo - altura_util - 12) if posicao < 2 && index < boletos.length - 1
          end

          pdf.render
        end

        def method_missing(m, *args)
          method = m.to_s
          return to_carne(:pdf, args.first || {}) if method == 'to_pdf'

          super
        end

        def respond_to_missing?(method_name, include_private = false)
          method_name.to_s == 'to_pdf' || super
        end

        private

        def documento_info
          {
            Title: 'Carnê de Pagamento',
            Creator: 'brcobranca',
            Producer: 'Prawn + RQRCode + Barby'
          }
        end

        # ============================================================
        # Faixa completa do carnê: canhoto | corte | ficha
        # ============================================================
        def desenha_carne(pdf, boleto)
          largura = pdf.bounds.width
          altura = pdf.bounds.height
          topo = pdf.cursor

          ficha_x = CANHOTO_WIDTH + CORTE_GAP

          pdf.bounding_box([0, topo], width: CANHOTO_WIDTH, height: altura) do
            desenha_canhoto(pdf, boleto)
          end

          desenha_corte_vertical(pdf, CANHOTO_WIDTH + (CORTE_GAP / 2), topo, altura)

          pdf.bounding_box([ficha_x, topo], width: largura - ficha_x, height: altura) do
            desenha_ficha(pdf, boleto)
          end
        end

        # Linha pontilhada vertical entre canhoto e ficha.
        def desenha_corte_vertical(pdf, x, topo, altura)
          pdf.stroke_color COR_TEXTO_LABEL
          pdf.line_width 0.5
          pdf.dash(2, space: 2)
          pdf.stroke_vertical_line topo, topo - altura, at: x
          pdf.undash
          pdf.stroke_color COR_BORDA
        end

        # Linha pontilhada horizontal entre boletos da página (lote).
        def desenha_corte_horizontal(pdf, y)
          pdf.stroke_color COR_TEXTO_LABEL
          pdf.line_width 0.5
          pdf.dash(2, space: 2)
          pdf.stroke_horizontal_line 0, pdf.bounds.width, at: y
          pdf.undash
          pdf.stroke_color COR_BORDA
        end

        # ============================================================
        # CANHOTO (esquerda) — dados essenciais empilhados
        # ============================================================
        def desenha_canhoto(pdf, boleto)
          desenha_cabecalho_canhoto(pdf, boleto)
          desenha_selo_parcela_canhoto(pdf, boleto)

          campo_canhoto(pdf, 'Vencimento', boleto.data_vencimento.to_s_br, bold: true)
          campo_canhoto(pdf, 'Agência/Código do Beneficiário', boleto.agencia_conta_boleto.to_s)
          campo_canhoto(pdf, 'Nosso número', boleto.nosso_numero_boleto.to_s)
          campo_canhoto(pdf, '(=) Valor do documento', boleto.valor_documento.to_currency, bold: true)
          campo_canhoto(pdf, 'Nº documento', boleto.documento_numero.to_s)
          campo_canhoto(pdf, 'Sacado', boleto.sacado.to_s, altura: ROW_H + 6)

          pdf.fill_color COR_TEXTO_LABEL
          pdf.text_box 'Recibo do Pagador',
                       at: [0, pdf.cursor - 2],
                       width: CANHOTO_WIDTH,
                       height: 8,
                       size: 6,
                       align: :center,
                       style: :italic
          pdf.fill_color COR_TEXTO_VALOR
        end

        def desenha_cabecalho_canhoto(pdf, boleto)
          y = pdf.cursor
          cor_marca = PrawnTema.cor_marca(boleto)
          cor_texto = cor_marca ? PrawnTema.cor_texto_sobre(cor_marca) : COR_TEXTO_VALOR

          # Faixa preenchida apenas quando há cor da marca (personalização);
          # sem tema, cabeçalho branco limpo com régua forte.
          if cor_marca
            pdf.fill_color cor_marca
            pdf.fill_rectangle([0, y], CANHOTO_WIDTH, HEADER_H)
            pdf.fill_color COR_TEXTO_VALOR
          end

          # Logo da empresa (tema) tem prioridade sobre o logo do banco no canhoto
          logo_ok = PrawnTema.desenha_logo(pdf, boleto, x: 2, y: y - 2, altura: HEADER_H - 4)
          PrawnTema.desenha_logo_banco_prawn(pdf, boleto, 0, y, CANHOTO_WIDTH - 38, HEADER_H) unless logo_ok

          pdf.fill_color cor_texto
          pdf.text_box "#{boleto.banco}-#{boleto.banco_dv}",
                       at: [CANHOTO_WIDTH - 38, y - 3],
                       width: 38,
                       height: HEADER_H,
                       size: 10,
                       align: :center,
                       valign: :center,
                       style: :bold
          pdf.fill_color COR_TEXTO_VALOR

          pdf.stroke_color COR_BORDA_FORTE
          pdf.line_width 0.9
          pdf.stroke_horizontal_line 0, CANHOTO_WIDTH, at: y - HEADER_H
          pdf.line_width 0.5
          pdf.stroke_color COR_BORDA
          pdf.move_down HEADER_H
        end

        # Selo "PARCELA n/N" destacado no canhoto (tema opcional — Fase 2a).
        def desenha_selo_parcela_canhoto(pdf, boleto)
          selo = PrawnTema.selo_parcela(boleto)
          return unless selo

          y = pdf.cursor
          altura = PrawnTema::SELO_ALTURA
          cor = PrawnTema.cor_marca(boleto) || COR_FUNDO_DESTAQUE
          cor_texto = PrawnTema.cor_marca(boleto) ? PrawnTema.cor_texto_sobre(cor) : COR_TEXTO_VALOR

          pdf.fill_color cor
          pdf.fill_rectangle([0, y], CANHOTO_WIDTH, altura)
          pdf.fill_color cor_texto
          pdf.text_box selo,
                       at: [0, y - 3], width: CANHOTO_WIDTH, height: altura - 4,
                       size: 10, align: :center, style: :bold
          pdf.fill_color COR_TEXTO_VALOR

          pdf.stroke_color COR_BORDA
          pdf.stroke_horizontal_line 0, CANHOTO_WIDTH, at: y - altura
          pdf.move_down altura
        end

        def campo_canhoto(pdf, label, valor, bold: false, altura: ROW_H)
          y = pdf.cursor

          pdf.fill_color COR_TEXTO_LABEL
          pdf.text_box label, at: [2, y - 1], width: CANHOTO_WIDTH - 4, height: 7,
                              size: LABEL_SIZE, overflow: :shrink_to_fit
          pdf.fill_color COR_TEXTO_VALOR

          opts = { at: [2, y - 9], width: CANHOTO_WIDTH - 4, height: altura - 10,
                   size: VALUE_SIZE - 1, overflow: :shrink_to_fit }
          opts[:style] = :bold if bold
          pdf.text_box valor.to_s, **opts

          pdf.stroke_color COR_BORDA
          pdf.stroke_horizontal_line 0, CANHOTO_WIDTH, at: y - altura
          pdf.move_down altura
        end

        # ============================================================
        # FICHA DE COMPENSAÇÃO (direita)
        # ============================================================
        def desenha_ficha(pdf, boleto)
          y_inicio = pdf.cursor
          desenha_cabecalho_ficha(pdf, boleto)

          ficha_row(pdf, [
                      { label: 'Local de pagamento', value: boleto.local_pagamento.to_s, ratio: 0.72, bold: true },
                      { label: 'Vencimento', value: boleto.data_vencimento.to_s_br, ratio: 0.28, bold: true, destaque: true }
                    ])

          ficha_row(pdf, [
                      { label: 'Beneficiário', value: nome_beneficiario(boleto), ratio: 0.72, bold: true },
                      { label: 'Agência/Código do Beneficiário', value: boleto.agencia_conta_boleto.to_s, ratio: 0.28 }
                    ])

          ficha_row(pdf, [
                      { label: 'Data documento', value: boleto.data_documento&.to_s_br.to_s, ratio: 0.14 },
                      { label: 'Nº documento', value: boleto.documento_numero.to_s, ratio: 0.22 },
                      { label: 'Espécie doc.', value: boleto.especie_documento.to_s, ratio: 0.10 },
                      { label: 'Aceite', value: boleto.aceite.to_s, ratio: 0.08 },
                      { label: 'Data process.', value: boleto.data_processamento&.to_s_br.to_s, ratio: 0.18 },
                      { label: 'Nosso número', value: boleto.nosso_numero_boleto.to_s, ratio: 0.28 }
                    ])

          ficha_row(pdf, [
                      { label: 'Uso do banco', value: '', ratio: 0.14 },
                      { label: 'Carteira', value: boleto.carteira.to_s, ratio: 0.12 },
                      { label: 'Espécie', value: boleto.especie.to_s, ratio: 0.10 },
                      { label: 'Quantidade', value: boleto.quantidade.to_s, ratio: 0.10 },
                      { label: 'Valor', value: '', ratio: 0.26 },
                      { label: '(=) Valor documento', value: boleto.valor_documento.to_currency, ratio: 0.28, bold: true,
                        destaque: true }
                    ])

          y_antes_instrucoes = pdf.cursor
          desenha_instrucoes_sacado(pdf, boleto)
          desenha_barras_pix(pdf, boleto)
          # Marca d'água diagonal (tema opcional): POR CIMA do conteúdo, na
          # cor da marca — restrita às linhas de campos acima das instruções
          # (zona de exclusão do QR Code e do código de barras).
          PrawnTema.desenha_marca_dagua(pdf, boleto, largura: pdf.bounds.width,
                                                     y: y_inicio - 20,
                                                     altura: y_inicio - y_antes_instrucoes - 24,
                                                     tamanho: 18, rotacao: 15)
        end

        def desenha_cabecalho_ficha(pdf, boleto)
          largura = pdf.bounds.width
          y = pdf.cursor
          logo_w = 64
          codigo_w = 40

          # Cabeçalho limpo (fundo branco): Logo | Código | Linha digitável,
          # com réguas verticais fortes e sublinhado marcante.
          PrawnTema.desenha_logo_banco_prawn(pdf, boleto, 0, y, logo_w, HEADER_H)

          pdf.fill_color COR_TEXTO_VALOR
          pdf.text_box "#{boleto.banco}-#{boleto.banco_dv}",
                       at: [logo_w, y - 3], width: codigo_w, height: HEADER_H,
                       size: 11, align: :center, valign: :center, style: :bold

          pdf.text_box boleto.codigo_barras.linha_digitavel,
                       at: [logo_w + codigo_w + 4, y - 3],
                       width: largura - logo_w - codigo_w - 8,
                       height: HEADER_H,
                       size: 9, align: :right, valign: :center, style: :bold

          pdf.stroke_color COR_BORDA_FORTE
          pdf.line_width 0.8
          pdf.stroke_vertical_line y - 1, y - HEADER_H + 3, at: logo_w
          pdf.stroke_vertical_line y - 1, y - HEADER_H + 3, at: logo_w + codigo_w
          pdf.line_width 0.9
          pdf.stroke_horizontal_line 0, largura, at: y - HEADER_H
          pdf.line_width 0.5
          pdf.stroke_color COR_BORDA
          pdf.move_down HEADER_H
        end

        def nome_beneficiario(boleto)
          if boleto.cedente && boleto.documento_cedente
            "#{boleto.cedente} - #{boleto.documento_cedente.to_s.formata_documento}"
          else
            boleto.cedente.to_s
          end
        end

        def ficha_row(pdf, colunas, altura: ROW_H)
          largura = pdf.bounds.width
          y = pdf.cursor
          x = 0

          # Grade fina e clara, fundo branco — labels pequenos em cinza fazem
          # o papel de "cabeçalho de campo" sem faixas sombreadas.
          pdf.stroke_color COR_BORDA
          pdf.stroke_rectangle([0, y], largura, altura)

          colunas.each_with_index do |col, i|
            w = (largura * col[:ratio]).round(2)

            if col[:destaque]
              pdf.fill_color COR_FUNDO_DESTAQUE
              pdf.fill_rectangle([x, y], w, altura)
              pdf.fill_color COR_TEXTO_VALOR
            end

            pdf.fill_color COR_TEXTO_LABEL
            pdf.text_box col[:label].to_s, at: [x + 3, y - 1], width: w - 6, height: 7,
                                           size: LABEL_SIZE, overflow: :shrink_to_fit
            pdf.fill_color COR_TEXTO_VALOR

            opts = { at: [x + 3, y - 9], width: w - 6, height: altura - 10,
                     size: VALUE_SIZE, overflow: :shrink_to_fit }
            opts[:style] = :bold if col[:bold]
            opts[:align] = col[:align] if col[:align]
            pdf.text_box col[:value].to_s, **opts

            pdf.stroke_vertical_line y, y - altura, at: x + w unless i == colunas.length - 1
            x += w
          end

          pdf.move_down altura
        end

        # Instruções (até 6 linhas) + Sacado (abaixo) e, com PIX, a célula
        # "Pague com Pix" integrada à direita — mesma linguagem do boleto:
        #   [ Instruções / Sacado | Pague com Pix ]
        def desenha_instrucoes_sacado(pdf, boleto)
          largura = pdf.bounds.width
          y = pdf.cursor
          altura = 88
          tem_pix = boleto.emv && PrawnTema.emv_valido?(boleto.emv)
          pix_w = tem_pix ? QRCODE_W + 10 : 0
          left_w = largura - pix_w

          pdf.stroke_color COR_BORDA
          pdf.stroke_rectangle([0, y], largura, altura)

          pdf.fill_color COR_TEXTO_LABEL
          pdf.text_box 'Instruções (texto de responsabilidade do beneficiário)',
                       at: [3, y - 1], width: left_w - 6, height: 7, size: LABEL_SIZE
          pdf.fill_color COR_TEXTO_VALOR

          # Área de instruções: comporta 6 linhas
          pdf.text_box montar_instrucoes(boleto),
                       at: [3, y - 10], width: left_w - 6, height: 44,
                       size: VALUE_SIZE - 1, leading: 0.5, overflow: :shrink_to_fit

          sacado_y = y - 56
          pdf.stroke_horizontal_line 0, left_w, at: sacado_y
          pdf.fill_color COR_TEXTO_LABEL
          pdf.text_box 'Sacado', at: [3, sacado_y - 1], width: left_w - 6, height: 6, size: LABEL_SIZE
          pdf.fill_color COR_TEXTO_VALOR

          pdf.text_box montar_sacado(boleto),
                       at: [3, sacado_y - 8], width: left_w - 6, height: altura - 56 - 9,
                       size: VALUE_SIZE - 1, overflow: :shrink_to_fit

          if tem_pix
            pdf.stroke_vertical_line y, y - altura, at: left_w
            desenha_celula_pix(pdf, boleto, x: left_w, y: y, largura: pix_w, altura: altura)
          end

          pdf.move_down altura
        end

        # Célula "Pague com Pix" integrada ao bloco de instruções (cabeçalho
        # teal + QR Code vetorial centralizado).
        def desenha_celula_pix(pdf, boleto, x:, y:, largura:, altura:)
          header_h = 9

          pdf.fill_color COR_PIX
          pdf.fill_rectangle([x, y], largura, header_h)
          pdf.fill_color 'FFFFFF'
          pdf.text_box PrawnTema.resolve_pix_label(boleto).upcase,
                       at: [x, y - 2], width: largura, height: 7,
                       size: 5, style: :bold, align: :center

          qr_size = [altura - header_h - 3, largura - 4].min
          qr_x = x + ((largura - qr_size) / 2.0)
          PrawnTema.desenha_qr_vetorial(pdf, boleto.emv.to_s,
                                        x: qr_x, y: y - header_h - 2, tamanho: qr_size)
          pdf.fill_color COR_TEXTO_VALOR
        end

        def montar_instrucoes(boleto)
          return boleto.instrucoes.to_s if boleto.instrucoes && !boleto.instrucoes.to_s.strip.empty?

          [boleto.instrucao1, boleto.instrucao2, boleto.instrucao3,
           boleto.instrucao4, boleto.instrucao5, boleto.instrucao6].compact.reject { |l| l.to_s.strip.empty? }.join("\n")
        end

        def montar_sacado(boleto)
          partes = []
          if boleto.sacado && boleto.sacado_documento
            partes << "#{boleto.sacado} - #{boleto.sacado_documento.to_s.formata_documento}"
          elsif boleto.sacado
            partes << boleto.sacado
          end
          partes << boleto.sacado_endereco.to_s if boleto.sacado_endereco
          partes.join(' — ')
        end

        # Código de barras I2/5 na base da ficha. O QR Code PIX fica na célula
        # integrada ao bloco de instruções (desenha_celula_pix) — aqui o
        # barcode ocupa a largura ampla com a autenticação mecânica à direita.
        def desenha_barras_pix(pdf, boleto)
          return unless boleto.codigo_barras

          largura = pdf.bounds.width
          y = pdf.cursor - 2
          # 72% de largura garante xdim suficiente para leitura do I2/5
          # também em tela (não há mais painel PIX nesta linha).
          barras_w = largura * 0.72

          pdf.bounding_box([0, y], width: barras_w, height: BARCODE_H) do
            barcode = Barby::Code25Interleaved.new(boleto.codigo_barras.to_s)
            modules = barcode.encoding.length
            xdim = [(barras_w - 8).to_f / modules, 0.9].min
            barcode.annotate_pdf(pdf, height: BARCODE_H - 3, xdim: xdim)
          end

          pdf.fill_color COR_TEXTO_LABEL
          pdf.text_box 'Autenticação mecânica - Ficha de Compensação',
                       at: [largura - 160, y - 4], width: 160, height: 14,
                       size: 5, align: :right
          pdf.fill_color COR_TEXTO_VALOR

          # Rodapé de contato da empresa (tema opcional — Fase 2a),
          # à esquerda, abaixo do código de barras
          return unless PrawnTema.rodape_contato(boleto)

          pdf.fill_color COR_TEXTO_LABEL
          pdf.text_box PrawnTema.rodape_contato(boleto),
                       at: [0, y - BARCODE_H - 4], width: barras_w, height: 7,
                       size: 5, overflow: :shrink_to_fit
          pdf.fill_color COR_TEXTO_VALOR
        end

      end
    end
  end
end
