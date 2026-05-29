# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab400::BradescoPix do
  let(:pagamento_pix) do
    Brcobranca::Remessa::PagamentoPix.new(
      valor: 199.9,
      data_vencimento: Date.current,
      nosso_numero: 123,
      documento_sacado: '12345678901',
      nome_sacado: 'CLIENTE TESTE DA SILVA',
      endereco_sacado: 'RUA DAS FLORES 123',
      bairro_sacado: 'CENTRO',
      cep_sacado: '12345678',
      cidade_sacado: 'SAO PAULO',
      uf_sacado: 'SP',
      codigo_chave_dict: '12345678000100',
      tipo_chave_dict: 'cnpj',
      tipo_pagamento_pix: '00',
      quantidade_pagamentos_pix: 1,
      tipo_valor_pix: '2',
      valor_maximo_pix: 199.9,
      percentual_maximo_pix: 100.0,
      valor_minimo_pix: 199.9,
      percentual_minimo_pix: 100.0,
      txid: 'TXID237BRAD001'
    )
  end

  let(:params) do
    {
      carteira: '01',
      agencia: '12345',
      conta_corrente: '1234567',
      digito_conta: '1',
      empresa_mae: 'SOCIEDADE BRASILEIRA DE ZOOLOGIA LTDA',
      sequencial_remessa: '1',
      codigo_empresa: '123',
      pagamentos: [pagamento_pix]
    }
  end

  let(:remessa) { described_class.new(params) }

  it_behaves_like 'cnab400 PIX'

  describe 'heranca e mixin' do
    it 'herda de Bradesco' do
      expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab400::Bradesco)
    end

    it 'inclui PixMixin' do
      expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab400::PixMixin)
    end
  end

  describe 'detalhe PIX' do
    let(:detalhe) { remessa.monta_detalhe_pix(pagamento_pix, 3) }

    it 'registro tipo 8 com 400 posicoes' do
      expect(detalhe.size).to eq(400)
      expect(detalhe[0]).to eq('8')
    end

    it 'tipo chave CNPJ mapeado para 2' do
      expect(detalhe[42]).to eq('2')
    end

    it 'chave DICT presente' do
      expect(detalhe[43..119].strip).to eq('12345678000100')
    end

    it 'TXID presente' do
      expect(detalhe[120..154].strip).to eq('TXID237BRAD001')
    end
  end

  describe 'arquivo completo' do
    it 'gera 4 registros: header + detalhe + pix + trailer' do
      linhas = remessa.gera_arquivo.split("\r\n").reject(&:empty?)
      expect(linhas.size).to eq(4)
      expect(linhas[0][0]).to eq('0')
      expect(linhas[1][0]).to eq('1')
      expect(linhas[2][0]).to eq('8')
      expect(linhas[3][0]).to eq('9')
      linhas.each { |l| expect(l.size).to eq(400) }
    end

    it 'sequencial correto em todos os registros' do
      linhas = remessa.gera_arquivo.split("\r\n").reject(&:empty?)
      expect(linhas[0][394..399]).to eq('000001')
      expect(linhas[1][394..399]).to eq('000002')
      expect(linhas[2][394..399]).to eq('000003')
      expect(linhas[3][394..399]).to eq('000004')
    end
  end
end
