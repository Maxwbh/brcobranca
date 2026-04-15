# frozen_string_literal: true

module Brcobranca
  module Remessa
    module Cnab400
      # Remessa CNAB 400 para Banco C6 (código 336)
      #
      # Layout baseado no manual oficial "Layout de Arquivos Cobrança Bancária
      # Padrão CNAB 400 Posições - Versão 2.7 Julho 2025" do C6 Bank.
      class BancoC6 < Brcobranca::Remessa::Cnab400::Base
        # Código do Cedente fornecido pelo C6 (12 posições).
        # Também utilizado como Conta Cobrança no header.
        attr_accessor :codigo_beneficiario

        # Carteiras aceitas pelo C6:
        # - 10: Cobrança Simples Emissão Banco
        # - 20: Cobrança Simples Emissão Cliente
        CARTEIRAS = %w[10 20].freeze

        validates_presence_of :documento_cedente, :codigo_beneficiario,
                              message: 'não pode estar em branco.'
        validates_length_of :documento_cedente, minimum: 11, maximum: 14,
                                                message: 'deve ter entre 11 e 14 dígitos.'
        validates_length_of :codigo_beneficiario, maximum: 12,
                                                  message: 'deve ter no máximo 12 dígitos.'
        validates_inclusion_of :carteira, in: CARTEIRAS,
                                          message: "não é uma carteira válida. Utilize: #{CARTEIRAS.join(', ')}."

        def initialize(campos = {})
          campos = { aceite: 'N', carteira: '10' }.merge!(campos)
          super(campos)
        end

        def cod_banco
          '336'
        end

        # No layout do C6, as posições 80-94 do header são "Brancos".
        # Usamos 15 brancos para manter compatibilidade com o formato da classe base.
        def nome_banco
          ''.rjust(15, ' ')
        end

        # Informações da conta no header (posições 27-46 = 20 caracteres).
        # Composição:
        #   - Código do Beneficiário (12)
        #   - Brancos (8)
        #
        # @return [String]
        def info_conta
          "#{codigo_beneficiario.to_s.rjust(12, '0')}#{''.rjust(8, ' ')}"
        end

        # Complemento do header (posições 101-394 = 294 caracteres).
        # Composição:
        #   - Brancos (8) posições 101-108
        #   - Conta Cobrança (12) posições 109-120
        #   - Brancos (266) posições 121-386
        #   - Sequencial da Remessa (8) posições 387-394
        #
        # @return [String]
        def complemento
          sequencial = sequencial_remessa.to_s.rjust(8, '0')
          "#{''.rjust(8, ' ')}#{codigo_beneficiario.to_s.rjust(12, '0')}#{''.rjust(266, ' ')}#{sequencial}"
        end

        # Monta o registro detalhe de remessa do C6.
        #
        # Estrutura do registro detalhe (400 posições):
        #   Pos    | Tam | Conteúdo
        #     1    |  1  | "1" (Tipo de Registro - fixo)
        #    2-3   |  2  | "02" (Tipo de Inscrição - fixo)
        #    4-17  | 14  | CNPJ do Beneficiário
        #   18-29  | 12  | Código do Beneficiário
        #   30-37  |  8  | Brancos
        #   38-62  | 25  | Uso Exclusivo (número do documento do beneficiário)
        #   63-73  | 11  | Nosso Número (vazio carteira 10; "0NNNNNNNNNN" carteira 20)
        #    74    |  1  | Dígito do Nosso Número
        #   75-82  |  8  | Brancos
        #   83-85  |  3  | "336" (Código do Banco)
        #   86-106 | 21  | Brancos
        #  107-108 |  2  | Código da Carteira ("10" ou "20")
        #  109-110 |  2  | Código de Ocorrência (01 = Remessa)
        #  111-120 | 10  | Seu Número do Título
        #  121-126 |  6  | Data de Vencimento (DDMMAA)
        #  127-139 | 13  | Valor do Título (99v99)
        #  140-147 |  8  | Brancos
        #  148-149 |  2  | Espécie do Título
        #   150    |  1  | Aceite (A ou N)
        #  151-156 |  6  | Data de Emissão (DDMMAA)
        #  157-158 |  2  | Instrução 1 (zeros)
        #  159-160 |  2  | Instrução 2 (zeros)
        #  161-173 | 13  | Juros ao Dia (99v99)
        #  174-179 |  6  | Data para Desconto 1
        #  180-192 | 13  | Valor para Desconto 1
        #  193-198 |  6  | Data da Multa
        #  199-205 |  7  | Brancos
        #  206-218 | 13  | Valor do Abatimento
        #  219-220 |  2  | Tipo do Pagador (01 = CPF, 02 = CNPJ)
        #  221-234 | 14  | CPF/CNPJ do Pagador
        #  235-274 | 40  | Nome do Pagador
        #  275-314 | 40  | Endereço do Pagador
        #  315-326 | 12  | Bairro do Pagador
        #  327-334 |  8  | CEP do Pagador
        #  335-349 | 15  | Cidade do Pagador
        #  350-351 |  2  | UF do Pagador
        #  352-381 | 30  | Beneficiário Final/Mensagem
        #   382    |  1  | Indicador de Multa (0 = sem, 2 = percentual)
        #  383-384 |  2  | Percentual de Multa
        #   385    |  1  | Brancos
        #  386-391 |  6  | Data dos Juros
        #  392-394 |  3  | Brancos
        #  395-400 |  6  | Número Sequencial do Registro
        #
        # @param pagamento [Brcobranca::Remessa::Pagamento]
        # @param sequencial [Integer]
        # @return [String]
        def monta_detalhe(pagamento, sequencial)
          raise Brcobranca::RemessaInvalida, pagamento if pagamento.invalid?

          detalhe = '1'                                                              # Tipo de Registro                 9[01]
          detalhe += '02'                                                            # Tipo de Inscrição                9[02]
          detalhe << documento_cedente.to_s.rjust(14, '0')                           # CNPJ do Beneficiário             9[14]
          detalhe << codigo_beneficiario.to_s.rjust(12, '0')                         # Código do Beneficiário           9[12]
          detalhe << ''.rjust(8, ' ')                                                # Brancos                          X[08]
          detalhe << pagamento.documento_ou_numero.to_s.ljust(25, ' ')[0, 25]        # Uso Exclusivo Beneficiário       X[25]
          detalhe << nosso_numero_remessa(pagamento)                                 # Nosso Número                     9[11]
          detalhe << dv_nosso_numero(pagamento)                                      # Dígito do Nosso Número           9[01]
          detalhe << ''.rjust(8, ' ')                                                # Brancos                          X[08]
          detalhe << cod_banco                                                       # Código do Banco                  9[03]
          detalhe << ''.rjust(21, ' ')                                               # Brancos                          X[21]
          detalhe << carteira.to_s.rjust(2, '0')                                     # Código da Carteira               9[02]
          detalhe << pagamento.identificacao_ocorrencia                              # Código de Ocorrência             9[02]
          detalhe << pagamento.numero.to_s.rjust(10, '0')                            # Seu Número do Título             X[10]
          detalhe << pagamento.data_vencimento.strftime('%d%m%y')                    # Data de Vencimento               9[06]
          detalhe << pagamento.formata_valor                                         # Valor do Título                  9[13]
          detalhe << ''.rjust(8, ' ')                                                # Brancos                          X[08]
          detalhe << pagamento.especie_titulo.to_s.rjust(2, '0')                     # Espécie do Título                9[02]
          detalhe << aceite                                                          # Aceite                           X[01]
          detalhe << pagamento.data_emissao.strftime('%d%m%y')                       # Data de Emissão                  9[06]
          detalhe << '00'                                                            # Instrução 1                      9[02]
          detalhe << '00'                                                            # Instrução 2                      9[02]
          detalhe << pagamento.formata_valor_mora                                    # Juros ao Dia                     9[13]
          detalhe << pagamento.formata_data_desconto                                 # Data para Desconto 1             9[06]
          detalhe << pagamento.formata_valor_desconto                                # Valor para Desconto 1            9[13]
          detalhe << formata_data_multa(pagamento)                                   # Data da Multa                    9[06]
          detalhe << ''.rjust(7, ' ')                                                # Brancos                          X[07]
          detalhe << pagamento.formata_valor_abatimento                              # Valor do Abatimento              9[13]
          detalhe << pagamento.identificacao_sacado                                  # Tipo do Pagador                  9[02]
          detalhe << pagamento.documento_sacado.to_s.rjust(14, '0')                  # CPF/CNPJ do Pagador              9[14]
          detalhe << pagamento.nome_sacado.format_size(40)                           # Nome do Pagador                  X[40]
          detalhe << pagamento.endereco_sacado.format_size(40)                       # Endereço do Pagador              X[40]
          detalhe << pagamento.bairro_sacado.to_s.format_size(12)                    # Bairro do Pagador                X[12]
          detalhe << pagamento.cep_sacado.to_s.rjust(8, '0')                         # CEP do Pagador                   9[08]
          detalhe << pagamento.cidade_sacado.format_size(15)                         # Cidade do Pagador                X[15]
          detalhe << pagamento.uf_sacado.to_s.rjust(2, ' ')[0, 2]                    # UF do Pagador                    X[02]
          detalhe << pagamento.nome_avalista.to_s.format_size(30)                    # Beneficiário Final/Mensagem      X[30]
          detalhe << indicador_multa(pagamento)                                      # Indicador de Multa               9[01]
          detalhe << percentual_multa(pagamento)                                     # Percentual de Multa              9[02]
          detalhe << ' '                                                             # Brancos                          X[01]
          detalhe << formata_data_juros(pagamento)                                   # Data dos Juros                   9[06]
          detalhe << ''.rjust(3, ' ')                                                # Brancos                          X[03]
          detalhe << sequencial.to_s.rjust(6, '0')                                   # Número Sequencial do Registro    9[06]
          detalhe
        end

        private

        # Nosso número a ser gravado no registro detalhe.
        # - Carteira 10 (Emissão Banco): 11 posições em branco (banco gera).
        # - Carteira 20 (Emissão Cliente): "0" seguido do nosso número de 10 posições.
        def nosso_numero_remessa(pagamento)
          return ''.rjust(11, ' ') if carteira.to_s == '10'

          "0#{pagamento.nosso_numero.to_s.rjust(10, '0')}"
        end

        # Dígito verificador do nosso número calculado via Módulo 11.
        # Para carteira 10 retorna espaço (banco calcula).
        def dv_nosso_numero(pagamento)
          return ' ' if carteira.to_s == '10'

          pagamento.nosso_numero.to_s.rjust(10, '0').modulo11(
            multiplicador: (2..9).to_a,
            mapeamento: { 10 => 0, 11 => 0 }
          ) { |total| 11 - (total % 11) }.to_s
        end

        def formata_data_multa(pagamento)
          return '000000' if pagamento.data_multa.nil?

          pagamento.data_multa.strftime('%d%m%y')
        end

        def formata_data_juros(pagamento)
          return '000000' if pagamento.data_mora.nil?

          pagamento.data_mora.strftime('%d%m%y')
        end

        def indicador_multa(pagamento)
          pagamento.codigo_multa.to_i.positive? ? '2' : '0'
        end

        def percentual_multa(pagamento)
          return '00' unless pagamento.percentual_multa

          valor = pagamento.percentual_multa.to_f.round.to_i
          valor.to_s.rjust(2, '0')[0, 2]
        end
      end
    end
  end
end
