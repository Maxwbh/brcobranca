# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab400::BancoC6Pix do
  let(:pagamento_pix) do
    Brcobranca::Remessa::PagamentoPix.new(
      valor: 250.00,
      data_vencimento: Date.current + 30,
      nosso_numero: '0000000042',
      documento: '12345',
      documento_sacado: '12345678901',
      nome_sacado: 'CLIENTE TESTE DA SILVA',
      endereco_sacado: 'RUA DAS FLORES 123',
      bairro_sacado: 'CENTRO',
      cep_sacado: '01234567',
      cidade_sacado: 'SAO PAULO',
      uf_sacado: 'SP',
      codigo_chave_dict: '12345678000100',
      tipo_chave_dict: 'cnpj',
      tipo_pagamento_pix: '00',
      quantidade_pagamentos_pix: 1,
      tipo_valor_pix: '2',
      valor_maximo_pix: 250.00,
      percentual_maximo_pix: 100.0,
      valor_minimo_pix: 250.00,
      percentual_minimo_pix: 100.0,
      txid: 'TXID336C6BANK042'
    )
  end

  let(:params) do
    {
      codigo_beneficiario: '000000123456',
      carteira: '10',
      empresa_mae: 'EMPRESA EXEMPLO LTDA',
      documento_cedente: '12345678000100',
      sequencial_remessa: '1',
      pagamentos: [pagamento_pix]
    }
  end

  let(:remessa) { described_class.new(params) }

  describe 'heranca e mixin' do
    it 'herda de BancoC6' do
      expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab400::BancoC6)
    end

    it 'inclui PixMixin' do
      expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab400::PixMixin)
    end

    it 'responde a monta_detalhe_pix' do
      expect(remessa).to respond_to(:monta_detalhe_pix)
    end
  end

  it_behaves_like 'cnab400 PIX'

  describe 'detalhe PIX' do
    let(:detalhe) { remessa.monta_detalhe_pix(pagamento_pix, 3) }

    it 'registro tipo 8 com 400 posicoes' do
      expect(detalhe.size).to eq(400)
      expect(detalhe[0]).to eq('8')
    end

    it 'tipo de pagamento 00' do
      expect(detalhe[1..2]).to eq('00')
    end

    it 'tipo de chave CNPJ mapeado para 2' do
      expect(detalhe[42]).to eq('2')
    end

    it 'chave DICT nas posicoes 44-120' do
      expect(detalhe[43..119].strip).to eq('12345678000100')
    end

    it 'TXID nas posicoes 121-155' do
      expect(detalhe[120..154].strip).to eq('TXID336C6BANK042')
    end

    it 'valor maximo PIX' do
      expect(detalhe[6..18]).to eq('0000000025000')
    end

    it 'valor minimo PIX' do
      expect(detalhe[24..36]).to eq('0000000025000')
    end

    it 'sequencial do registro' do
      expect(detalhe[394..399]).to eq('000003')
    end
  end

  describe 'arquivo completo com PIX' do
    it 'contem header + detalhe + detalhe_pix + trailer' do
      arquivo = remessa.gera_arquivo
      linhas = arquivo.split("\r\n").reject(&:empty?)
      expect(linhas.size).to eq(4)
      expect(linhas[0][0]).to eq('0')
      expect(linhas[1][0]).to eq('1')
      expect(linhas[2][0]).to eq('8')
      expect(linhas[3][0]).to eq('9')
      linhas.each { |l| expect(l.size).to eq(400) }
    end

    it 'multiplos pagamentos PIX geram pares detalhe+pix' do
      remessa.pagamentos << pagamento_pix.dup
      arquivo = remessa.gera_arquivo
      linhas = arquivo.split("\r\n").reject(&:empty?)
      expect(linhas.size).to eq(6)
    end
  end

  describe 'carteira 20 com PIX' do
    let(:remessa_c20) { described_class.new(params.merge(carteira: '20')) }

    it 'gera remessa valida' do
      expect(remessa_c20).to be_valid
    end

    it 'detalhe usa carteira 20' do
      detalhe = remessa_c20.monta_detalhe(pagamento_pix, 2)
      expect(detalhe[106..107]).to eq('20')
    end

    it 'nosso numero preenchido na carteira 20' do
      detalhe = remessa_c20.monta_detalhe(pagamento_pix, 2)
      expect(detalhe[62..72].strip).not_to be_empty
    end
  end

  describe 'tipos de chave DICT' do
    it 'CPF mapeado para 1' do
      pagamento_pix.tipo_chave_dict = 'cpf'
      pagamento_pix.codigo_chave_dict = '12345678901'
      detalhe = remessa.monta_detalhe_pix(pagamento_pix, 3)
      expect(detalhe[42]).to eq('1')
    end

    it 'email mapeado para 4' do
      pagamento_pix.tipo_chave_dict = 'email'
      pagamento_pix.codigo_chave_dict = 'teste@exemplo.com'
      detalhe = remessa.monta_detalhe_pix(pagamento_pix, 3)
      expect(detalhe[42]).to eq('4')
    end

    it 'telefone mapeado para 3' do
      pagamento_pix.tipo_chave_dict = 'telefone'
      pagamento_pix.codigo_chave_dict = '+5511999999999'
      detalhe = remessa.monta_detalhe_pix(pagamento_pix, 3)
      expect(detalhe[42]).to eq('3')
    end

    it 'chave_aleatoria mapeada para 5' do
      pagamento_pix.tipo_chave_dict = 'chave_aleatoria'
      pagamento_pix.codigo_chave_dict = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
      detalhe = remessa.monta_detalhe_pix(pagamento_pix, 3)
      expect(detalhe[42]).to eq('5')
    end
  end
end
