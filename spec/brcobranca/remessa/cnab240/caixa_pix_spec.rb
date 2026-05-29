# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab240::CaixaPix do
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
      valor_iof: 9.9,
      valor_abatimento: 24.35,
      documento_avalista: '12345678901',
      nome_avalista: 'AVALISTA EXEMPLO',
      numero: '123',
      documento: 6969,
      codigo_chave_dict: 'financeiro@empresa.com.br',
      tipo_chave_dict: 'email',
      txid: 'TXID104CAIXA001'
    )
  end

  let(:params) do
    {
      empresa_mae: 'SOCIEDADE BRASILEIRA DE ZOOLOGIA LTDA',
      agencia: '12345',
      conta_corrente: '1234',
      versao_aplicativo: '1234',
      documento_cedente: '12345678901',
      convenio: '123456',
      digito_agencia: '1',
      sequencial_remessa: '000001',
      pagamentos: [pagamento_pix]
    }
  end

  let(:remessa) { described_class.new(params) }

  describe 'heranca e mixin' do
    it 'herda de Caixa' do
      expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab240::Caixa)
    end

    it 'inclui PixMixin' do
      expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab240::PixMixin)
    end
  end

  describe 'segmento Y-03 (PIX)' do
    let(:segmento_y) { remessa.monta_segmento_y(pagamento_pix, 1, 5) }

    it 'tem 240 posicoes' do
      expect(segmento_y.size).to eq(240)
    end

    it 'codigo do banco 104' do
      expect(segmento_y[0..2]).to eq('104')
    end

    it 'tipo chave email mapeado para 4' do
      expect(segmento_y[27]).to eq('4')
    end

    it 'chave DICT (email)' do
      expect(segmento_y[28..104].strip).to eq('financeiro@empresa.com.br')
    end

    it 'TXID presente' do
      expect(segmento_y[105..139].strip).to eq('TXID104CAIXA001')
    end
  end

  describe 'lote com segmento Y' do
    it 'lote inclui segmento Y' do
      lote = remessa.monta_lote(1)
      segmentos = lote.map { |l| l[13] }
      expect(segmentos).to include('Y')
    end

    it 'lote tem 6 registros' do
      lote = remessa.monta_lote(1)
      expect(lote.size).to eq(6)
    end
  end

  describe 'arquivo completo' do
    it 'gera arquivo valido com segmento Y' do
      arquivo = remessa.gera_arquivo
      expect(arquivo).not_to be_empty
      expect(arquivo).to include('Y')
    end

    it 'todas as linhas tem 240 posicoes' do
      linhas = remessa.gera_arquivo.split("\r\n").reject(&:empty?)
      linhas.each { |l| expect(l.size).to eq(240) }
    end
  end
end
