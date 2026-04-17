# frozen_string_literal: true

begin
  require 'rghost'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rghost'
  require 'rghost'
end

begin
  require 'rghost_barcode'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rghost_barcode'
  require 'rghost_barcode'
end

# Garante compatibilidade com rghost >= 0.9.9 (ver rghost.rb)
unless defined?(RGhost::VERSION)
  module RGhost
    module VERSION
      MAJOR = 0
      MINOR = 9
      TINY  = 9
      DATE  = 1_709_769_600
      STRING = [MAJOR, MINOR, TINY].join('.')
    end
  end
end

module Brcobranca
  module Boleto
    module Template
      # Templates para usar com Rghost - versão híbrida com suporte a PIX/QR Code
      #
      # Gera boletos no formato padrão FEBRABAN incluindo QR Code PIX quando o
      # atributo `boleto.emv` está presente (string BR Code conforme padrão EMV
      # do Banco Central).
      module RghostBolepix
        extend self
        include RGhost unless include?(RGhost)
        RGhost::Config::GS[:external_encoding] = Brcobranca.configuration.external_encoding
        RGhost::Config::GS[:default_params] << '-dNOSAFER'

        # Label padrão exibido ao lado do QR Code PIX.
        # Pode ser sobrescrito pelo boleto através do atributo `pix_label`
        # ou globalmente via `Brcobranca.configuration.pix_label` (se configurado).
        DEFAULT_PIX_LABEL = 'Pague com PIX'

        # Gera o boleto em usando o formato desejado [:pdf, :jpg, :tif, :png, :ps, :laserjet, ... etc]
        #
        # @return [Stream]
        # @see http://wiki.github.com/shairontoledo/rghost/supported-devices-drivers-and-formats Veja mais formatos na documentação do rghost.
        # @see Rghost#modelo_generico Recebe os mesmos parâmetros do Rghost#modelo_generico.
        def to(formato, options = {})
          modelo_generico(self, options.merge!(formato: formato))
        end

        # Gera multiplos boletos em um único arquivo.
        #
        # @return [Stream]
        # @see http://wiki.github.com/shairontoledo/rghost/supported-devices-drivers-and-formats
        def lote(boletos, options = {})
          modelo_generico_multipage(boletos, options)
        end

        #  Cria o métodos dinâmicos (to_pdf, to_gif e etc) com todos os fomátos válidos.
        #
        # @return [Stream]
        # @example
        #  @boleto.to_pdf #=> boleto gerado no formato pdf
        def method_missing(m, *args)
          method = m.to_s
          if method.start_with?('to_')
            modelo_generico(self, (args.first || {}).merge!(formato: method[3..]))
          else
            super
          end
        end

        private

        # Retorna o template path padrão.
        def template_path
          @template_path ||= File.join(
            File.dirname(__FILE__), '..', '..', '..', '..',
            'assets', 'templates', 'modelo_generico.eps'
          )
        end

        # Stream de um boleto único.
        #
        # @return [Stream]
        # @param [Boleto] boleto
        # @param [Hash] options opções de renderização
        # @option options [Symbol] :resolucao Resolução em pixels
        # @option options [Symbol] :formato Formato desejado [:pdf, :jpg, ...]
        def modelo_generico(boleto, options = {})
          doc = Document.new paper: :A4 # 210x297

          raise 'Não foi possível encontrar o template. Verifique o caminho' unless File.exist?(template_path)

          desenha_pagina(doc, boleto)

          finaliza_documento(doc, options)
        end

        # Stream com múltiplos boletos.
        #
        # @return [Stream]
        # @param [Array<Boleto>] boletos
        # @param [Hash] options opções de renderização
        def modelo_generico_multipage(boletos, options = {})
          doc = Document.new paper: :A4 # 210x297

          raise 'Não foi possível encontrar o template. Verifique o caminho' unless File.exist?(template_path)

          boletos.each_with_index do |boleto, index|
            desenha_pagina(doc, boleto)
            doc.next_page unless index == boletos.length - 1
          end

          finaliza_documento(doc, options)
        end

        # Desenha uma página completa do boleto com cabeçalho, rodapé,
        # código de barras e QR Code PIX (se aplicável).
        #
        # @param doc [RGhost::Document]
        # @param boleto [Brcobranca::Boleto::Base]
        def desenha_pagina(doc, boleto)
          modelo_generico_template(doc, boleto, template_path)
          modelo_generico_cabecalho(doc, boleto)
          modelo_generico_rodape(doc, boleto)
          desenha_codigo_barras(doc, boleto)
          desenha_qrcode_pix(doc, boleto)
        end

        # Desenha o código de barras Interleaved 2 of 5.
        def desenha_codigo_barras(doc, boleto)
          return unless boleto.codigo_barras

          doc.barcode_interleaved2of5(
            boleto.codigo_barras,
            width: '10.3 cm',
            height: '1.3 cm',
            x: "#{@x - 1.7} cm",
            y: "#{@y - 1.67} cm"
          )
        end

        # Desenha o QR Code PIX a partir da string EMV do boleto.
        #
        # Só gera se `boleto.emv` estiver presente e for válido.
        # O label exibido pode ser customizado via:
        #  - Brcobranca.configuration.pix_label (se configurado)
        #  - boleto.pix_label (se o boleto responder ao método)
        #  - DEFAULT_PIX_LABEL como fallback
        def desenha_qrcode_pix(doc, boleto)
          return unless boleto.emv
          return unless emv_valido?(boleto.emv)

          doc.barcode_qrcode(
            boleto.emv,
            width: '2.5 cm',
            height: '2.5 cm',
            eclevel: 'H',
            x: "#{@x + 12.9} cm",
            y: "#{@y - 2.50} cm"
          )
          move_more(doc, @x + 12.9, @y - 3.70)
          doc.show pix_label(boleto)
        end

        # Obtém o label exibido ao lado do QR Code PIX.
        def pix_label(boleto)
          return boleto.pix_label if boleto.respond_to?(:pix_label) && boleto.pix_label

          config_label = Brcobranca.configuration.respond_to?(:pix_label) ? Brcobranca.configuration.pix_label : nil
          config_label || DEFAULT_PIX_LABEL
        end

        # Validação mínima do EMV BR Code.
        #
        # Verifica se o EMV começa com "0002" (Payload Format Indicator)
        # que é o primeiro campo obrigatório de um BR Code válido.
        # Não faz validação completa de CRC16 (complexa e pouco útil aqui).
        def emv_valido?(emv)
          return false if emv.nil? || emv.to_s.strip.empty?

          # BR Code válido sempre começa com "0002" seguido do tamanho e valor
          emv.to_s.start_with?('0002')
        end

        # Finaliza o documento e retorna o stream no formato solicitado.
        def finaliza_documento(doc, options)
          formato = options.delete(:formato) || Brcobranca.configuration.formato
          resolucao = options.delete(:resolucao) || Brcobranca.configuration.resolucao
          doc.render_stream(formato.to_sym, resolution: resolucao)
        end

        # Define o template a ser usado no boleto
        def modelo_generico_template(doc, _boleto, template_path)
          doc.define_template(:template, template_path, x: '0.5 cm', y: '2.7 cm')
          doc.use_template :template

          doc.define_tags do
            tag :grande, size: 13
            tag :maior, size: 15
          end
        end

        def move_more(doc, x, y)
          @x += x
          @y += y
          doc.moveto x: "#{@x} cm", y: "#{@y} cm"
        end

        # Monta o cabeçalho do layout do boleto
        def modelo_generico_cabecalho(doc, boleto)
          # INICIO Primeira parte do BOLETO
          @x = 0.50
          @y = 27.42
          doc.image boleto.logotipo, x: "#{@x} cm", y: "#{@y} cm"

          move_more(doc, 4.84, 0.02)
          doc.show "#{boleto.banco}-#{boleto.banco_dv}", tag: :maior
          move_more(doc, 2, 0)
          doc.show boleto.codigo_barras.linha_digitavel, tag: :grande
          move_more(doc, -6.5, -0.83)

          doc.show boleto.cedente

          move_more(doc, 15.8, 0)
          doc.show boleto.agencia_conta_boleto

          move_more(doc, -15.8, -0.9)
          doc.show boleto.cedente_endereco

          move_more(doc, 15.8, 0)
          doc.show boleto.nosso_numero_boleto

          move_more(doc, -15.8, -0.8)
          doc.show boleto.documento_numero

          move_more(doc, 3.5, 0)
          doc.show boleto.especie

          move_more(doc, 1.5, 0)
          doc.show boleto.quantidade

          move_more(doc, 2, 0)
          doc.show boleto.documento_cedente.formata_documento.to_s

          move_more(doc, 3.8, 0)
          doc.show boleto.data_vencimento.to_s_br

          move_more(doc, 5, 0)
          doc.show boleto.valor_documento.to_currency

          move_more(doc, -15.8, -0.75)
          doc.show boleto.descontos_e_abatimentos&.to_currency

          move_more(doc, 0.8, -0.55)
          doc.show "#{boleto.sacado} - #{boleto.sacado_documento.formata_documento}"

          move_more(doc, 0, -0.3)
          doc.show boleto.sacado_endereco.to_s
          return unless boleto.demonstrativo

          doc.text_area boleto.demonstrativo, width: '18.5 cm', text_align: :left, x: "#{@x - 0.8} cm",
                                              y: "#{@y - 0.9} cm", row_height: '0.4 cm'
        end

        # Monta o corpo e rodapé do layout do boleto
        def modelo_generico_rodape(doc, boleto)
          @x = 0.50
          @y = 12.22
          doc.image boleto.logotipo, x: "#{@x} cm", y: "#{@y} cm"

          move_more(doc, 4.84, 0.01)
          doc.show "#{boleto.banco}-#{boleto.banco_dv}", tag: :maior

          move_more(doc, 2, 0)
          doc.show boleto.codigo_barras.linha_digitavel, tag: :grande

          move_more(doc, -6.5, -0.9)
          doc.show boleto.local_pagamento

          move_more(doc, 15.8, 0)
          doc.show boleto.data_vencimento.to_s_br if boleto.data_vencimento

          move_more(doc, -15.8, -0.8)
          if boleto.cedente_endereco
            doc.show boleto.cedente_endereco
            move_more(doc, 1.2, 0.3)
            doc.show boleto.cedente
            move_more(doc, -1.2, -0.3)
          else
            doc.show boleto.cedente
          end

          move_more(doc, 15.8, 0)
          doc.show boleto.agencia_conta_boleto

          move_more(doc, -15.8, -0.9)
          doc.show boleto.data_documento.to_s_br if boleto.data_documento

          move_more(doc, 3.5, 0)
          doc.show boleto.documento_numero

          move_more(doc, 5.8, 0)
          doc.show boleto.especie_documento

          move_more(doc, 1.7, 0)
          doc.show boleto.aceite

          move_more(doc, 1.3, 0)

          doc.show boleto.data_processamento.to_s_br if boleto.data_processamento

          move_more(doc, 3.5, 0)
          doc.show boleto.nosso_numero_boleto

          move_more(doc, -12.1, -0.8)
          if boleto.variacao
            doc.show "#{boleto.carteira}-#{boleto.variacao}"
          else
            doc.show boleto.carteira
          end

          move_more(doc, 2, 0)
          doc.show boleto.especie

          move_more(doc, 10.1, 0)
          doc.show boleto.valor_documento.to_currency

          move_more(doc, 0, -0.8)
          doc.show boleto.descontos_e_abatimentos&.to_currency

          move_more(doc, 0, 0.8)
          if boleto.instrucoes
            doc.text_area boleto.instrucoes, width: '14 cm',
                                             text_align: :left, x: "#{@x -= 15.8} cm",
                                             y: "#{@y -= 0.9} cm",
                                             row_height: '0.4 cm'
            move_more(doc, 0, -2)
          else
            move_more(doc, -15.8, -0.9)
            doc.show boleto.instrucao1

            move_more(doc, 0, -0.4)
            doc.show boleto.instrucao2

            move_more(doc, 0, -0.4)
            doc.show boleto.instrucao3

            move_more(doc, 0, -0.4)
            doc.show boleto.instrucao4

            move_more(doc, 0, -0.4)
            doc.show boleto.instrucao5

            move_more(doc, 0, -0.4)
            doc.show boleto.instrucao6
          end

          move_more(doc, 0.5, -1.9)
          if boleto.sacado && boleto.sacado_documento
            sacado_info = "#{boleto.sacado} - CPF/CNPJ: #{boleto.sacado_documento.formata_documento}"
            doc.show sacado_info
          end

          move_more(doc, 0, -0.4)
          doc.show boleto.sacado_endereco.to_s

          move_more(doc, 1.2, -0.93)
          doc.show "#{boleto.avalista} - #{boleto.avalista_documento}" if boleto.avalista && boleto.avalista_documento
        end
      end
    end
  end
end
