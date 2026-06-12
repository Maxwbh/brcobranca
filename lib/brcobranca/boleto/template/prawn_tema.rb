# frozen_string_literal: true

# Tema visual compartilhado pelos templates Prawn (PrawnBolepix e PrawnCarne).
#
# Lê os atributos opcionais de tema do boleto (logo_empresa, cor_marca,
# parcela_atual/total_parcelas, rodape_contato) e desenha os elementos de
# identidade visual da empresa cedente — sempre fora das áreas normativas
# da Ficha de Compensação (linha digitável, código de barras, QR Code).
#
# Todos os métodos têm fallback silencioso: sem atributos de tema, nada é
# desenhado e o visual permanece idêntico ao padrão.
module Brcobranca
  module Boleto
    module Template
      module PrawnTema
        module_function

        COR_HEX_REGEX = /\A[0-9A-Fa-f]{6}\z/
        FAIXA_ALTURA = 24
        SELO_ALTURA = 16

        # Indica se o boleto tem algum atributo de tema preenchido.
        def tema?(boleto)
          !cor_marca(boleto).nil? || !logo_empresa(boleto).nil? || !selo_parcela(boleto).nil?
        end

        # Cor da marca validada (hex RRGGBB) ou nil.
        def cor_marca(boleto)
          return nil unless boleto.respond_to?(:cor_marca)

          cor = boleto.cor_marca.to_s.delete_prefix('#')
          cor.match?(COR_HEX_REGEX) ? cor.upcase : nil
        end

        # Cor de texto com contraste adequado sobre a cor de fundo
        # (luminância relativa — preto sobre cores claras, branco sobre escuras).
        def cor_texto_sobre(hex)
          r = hex[0, 2].to_i(16)
          g = hex[2, 2].to_i(16)
          b = hex[4, 2].to_i(16)
          luminancia = (0.299 * r) + (0.587 * g) + (0.114 * b)
          luminancia > 150 ? '000000' : 'FFFFFF'
        end

        # Texto do selo de parcela ("PARCELA 2/12") ou nil.
        def selo_parcela(boleto)
          return nil unless boleto.respond_to?(:parcela_atual)

          atual = boleto.parcela_atual.to_i
          total = boleto.total_parcelas.to_i
          return nil unless atual.positive? && total.positive? && atual <= total

          "PARCELA #{atual}/#{total}"
        end

        # Logo da empresa: path existente (String) ou objeto IO; nil caso contrário.
        def logo_empresa(boleto)
          return nil unless boleto.respond_to?(:logo_empresa)

          logo = boleto.logo_empresa
          return logo if logo.respond_to?(:read)
          return logo if logo.is_a?(String) && File.exist?(logo)

          nil
        end

        # Rodapé de contato (truncado em 120 caracteres) ou nil.
        def rodape_contato(boleto)
          return nil unless boleto.respond_to?(:rodape_contato)

          texto = boleto.rodape_contato.to_s.strip
          texto.empty? ? nil : texto[0, 120]
        end

        # Desenha a faixa de marca: fundo na cor da empresa, logo à esquerda,
        # título opcional ao centro e selo de parcela à direita.
        # Retorna a altura consumida (0 se não há tema).
        def desenha_faixa(pdf, boleto, largura:, titulo: nil)
          return 0 unless tema?(boleto)

          y = pdf.cursor
          cor = cor_marca(boleto) || 'EEEEEE'
          cor_texto = cor_texto_sobre(cor)

          pdf.fill_color cor
          pdf.fill_rectangle([0, y], largura, FAIXA_ALTURA)

          desenha_logo(pdf, boleto, x: 4, y: y - 2, altura: FAIXA_ALTURA - 4)

          if titulo
            pdf.fill_color cor_texto
            pdf.text_box titulo,
                         at: [80, y - 6], width: largura - 200, height: 12,
                         size: 9, style: :bold, overflow: :shrink_to_fit
          end

          if (selo = selo_parcela(boleto))
            pdf.fill_color cor_texto
            pdf.text_box selo,
                         at: [largura - 116, y - 5], width: 112, height: 14,
                         size: 11, style: :bold, align: :right
          end

          pdf.fill_color '000000'
          pdf.move_down FAIXA_ALTURA + 2
          FAIXA_ALTURA + 2
        end

        # Desenha o logo da empresa na posição indicada (fallback silencioso).
        def desenha_logo(pdf, boleto, x:, y:, altura:)
          logo = logo_empresa(boleto)
          return false unless logo

          logo.rewind if logo.respond_to?(:rewind)
          pdf.image logo, at: [x, y], height: altura
          true
        rescue StandardError
          false
        end

        # Desenha o rodapé de contato (texto pequeno cinza, centralizado).
        def desenha_rodape(pdf, boleto, largura:, y:)
          texto = rodape_contato(boleto)
          return false unless texto

          pdf.fill_color '555555'
          pdf.text_box texto,
                       at: [0, y], width: largura, height: 8,
                       size: 6, align: :center, overflow: :shrink_to_fit
          pdf.fill_color '000000'
          true
        end
      end
    end
  end
end
