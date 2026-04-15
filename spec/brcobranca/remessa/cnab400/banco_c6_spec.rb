# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab400::BancoC6 do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(
      valor: 199.9,
      data_vencimento: Date.current,
      nosso_numero: '0000000123',
      documento: 6969,
      documento_sacado: '12345678901',
      nome_sacado: 'PABLO DIEGO JOSÉ FRANCISCO DE PAULA',
      endereco_sacado: 'RUA RIO GRANDE DO SUL 123',
      bairro_sacado: 'CENTRO',
      cep_sacado: '12345678',
      cidade_sacado: 'SAO PAULO',
      uf_sacado: 'SP'
    )
  end

  let(:params) do
    {
      codigo_beneficiario: '000000123456',
      carteira: '10',
      empresa_mae: 'EMPRESA EXEMPLO LTDA',
      documento_cedente: '12345678000191',
      sequencial_remessa: '1',
      pagamentos: [pagamento]
    }
  end

  let(:banco_c6) { subject.class.new(params) }

  context 'validações dos campos' do
    context '@carteira' do
      it 'deve ser inválido se não possuir uma carteira' do
        object = subject.class.new(params.merge(carteira: nil))
        expect(object.invalid?).to be true
        expect(object.errors.full_messages).to include(/Carteira/)
      end

      it 'deve ser inválido se a carteira não for 10 ou 20' do
        banco_c6.carteira = '99'
        expect(banco_c6.invalid?).to be true
        expect(banco_c6.errors.full_messages).to include(/Carteira/)
      end

      it 'deve aceitar carteira 10 (Emissão Banco)' do
        banco_c6.carteira = '10'
        expect(banco_c6.valid?).to be true
      end

      it 'deve aceitar carteira 20 (Emissão Cliente)' do
        banco_c6.carteira = '20'
        expect(banco_c6.valid?).to be true
      end
    end

    context '@documento_cedente' do
      it 'deve ser inválido se não possuir o documento_cedente' do
        object = subject.class.new(params.merge(documento_cedente: nil))
        expect(object.invalid?).to be true
        expect(object.errors.full_messages).to include('Documento cedente não pode estar em branco.')
      end

      it 'deve ser inválido se o documento do cedente não tiver entre 11 e 14 dígitos' do
        banco_c6.documento_cedente = '123'
        expect(banco_c6.invalid?).to be true
        expect(banco_c6.errors.full_messages).to include('Documento cedente deve ter entre 11 e 14 dígitos.')
      end
    end

    context '@codigo_beneficiario' do
      it 'deve ser inválido se não possuir o codigo_beneficiario' do
        object = subject.class.new(params.merge(codigo_beneficiario: nil))
        expect(object.invalid?).to be true
        expect(object.errors.full_messages).to include('Codigo beneficiario não pode estar em branco.')
      end

      it 'deve ser inválido se tiver mais de 12 dígitos' do
        banco_c6.codigo_beneficiario = '1234567890123'
        expect(banco_c6.invalid?).to be true
        expect(banco_c6.errors.full_messages).to include('Codigo beneficiario deve ter no máximo 12 dígitos.')
      end
    end
  end

  context 'formatações dos valores' do
    it 'cod_banco deve ser 336' do
      expect(banco_c6.cod_banco).to eq '336'
    end

    it 'nome_banco deve possuir 15 caracteres (brancos conforme layout C6)' do
      expect(banco_c6.nome_banco.size).to eq 15
    end

    it 'info_conta deve retornar 20 posições' do
      info_conta = banco_c6.info_conta
      expect(info_conta.size).to eq 20
      expect(info_conta[0, 12]).to eq '000000123456' # Código do Beneficiário
    end

    it 'complemento deve retornar 294 caracteres' do
      expect(banco_c6.complemento.size).to eq 294
    end

    it 'complemento deve conter conta cobrança nas posições 9-20' do
      # No complemento (começa em pos 101 do arquivo), pos 109-120 = pos 9-20 do complemento (0-indexed: 8-19)
      expect(banco_c6.complemento[8, 12]).to eq '000000123456'
    end
  end

  context 'monta remessa' do
    it_behaves_like 'cnab400'

    context 'header' do
      it 'informações devem estar posicionadas corretamente no header' do
        header = banco_c6.monta_header
        expect(header.size).to eq 400
        expect(header[0]).to eq '0'                                        # Tipo de Registro
        expect(header[1]).to eq '1'                                        # Código de Remessa
        expect(header[2..8]).to eq 'REMESSA'                               # Literal Remessa
        expect(header[9..10]).to eq '01'                                   # Código do Serviço
        expect(header[11..18]).to eq 'COBRANCA'                            # Literal do Serviço
        expect(header[26..37]).to eq '000000123456'                        # Código do Beneficiário
        expect(header[76..78]).to eq '336'                                 # Código do Banco
        expect(header[94..99]).to eq Date.current.strftime('%d%m%y')       # Data de Gravação
        expect(header[108..119]).to eq '000000123456'                      # Conta Cobrança
        expect(header[394..399]).to eq '000001'                            # Sequencial do Registro
      end
    end

    context 'detalhe' do
      it 'informações devem estar posicionadas corretamente no detalhe (carteira 10)' do
        detalhe = banco_c6.monta_detalhe(pagamento, 2)
        expect(detalhe.size).to eq 400
        expect(detalhe[0]).to eq '1'                                              # Tipo de Registro
        expect(detalhe[1..2]).to eq '02'                                          # Tipo de Inscrição
        expect(detalhe[3..16]).to eq '12345678000191'                             # CNPJ do Beneficiário
        expect(detalhe[17..28]).to eq '000000123456'                              # Código do Beneficiário
        expect(detalhe[62..72]).to eq ''.rjust(11, ' ')                           # Nosso Número (carteira 10 = brancos)
        expect(detalhe[73]).to eq ' '                                             # DV Nosso Número (carteira 10 = branco)
        expect(detalhe[82..84]).to eq '336'                                       # Código do Banco
        expect(detalhe[106..107]).to eq '10'                                      # Código da Carteira
        expect(detalhe[108..109]).to eq '01'                                      # Código de Ocorrência (Remessa)
        expect(detalhe[110..119]).to eq '0000000000'                              # Seu Número
        expect(detalhe[120..125]).to eq Date.current.strftime('%d%m%y')           # Data de Vencimento
        expect(detalhe[126..138]).to eq '0000000019990'                           # Valor do Título (199,90)
        expect(detalhe[149]).to eq 'N'                                            # Aceite
        expect(detalhe[218..219]).to eq '01'                                      # Tipo Pagador (CPF)
        expect(detalhe[220..233]).to eq '00012345678901'                          # Documento Pagador
        expect(detalhe[394..399]).to eq '000002'                                  # Sequencial Registro
      end

      it 'na carteira 20 (Emissão Cliente) o nosso número deve ser preenchido' do
        banco_c6.carteira = '20'
        detalhe = banco_c6.monta_detalhe(pagamento, 2)
        expect(detalhe[62..72]).to eq '00000000123'                # Nosso Número 11 posições
        expect(detalhe[73]).to match(/\d/)                         # DV calculado
        expect(detalhe[106..107]).to eq '20'                       # Carteira 20
      end
    end

    context 'arquivo' do
      it 'gera arquivo completo com header, detalhe e trailer' do
        arquivo = banco_c6.gera_arquivo
        linhas = arquivo.split("\r\n").reject(&:empty?)
        expect(linhas.size).to eq 3 # header + 1 detalhe + trailer
        expect(linhas[0][0]).to eq '0'
        expect(linhas[1][0]).to eq '1'
        expect(linhas[2][0]).to eq '9'
        linhas.each { |linha| expect(linha.size).to eq 400 }
      end
    end
  end
end
