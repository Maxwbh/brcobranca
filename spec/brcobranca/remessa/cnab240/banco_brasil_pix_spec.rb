# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab240::BancoBrasilPix do
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
      codigo_chave_dict: '+5511999999999',
      tipo_chave_dict: 'telefone',
      txid: 'TXID001BB00001'
    )
  end

  let(:params) do
    {
      empresa_mae: 'SOCIEDADE BRASILEIRA DE ZOOLOGIA LTDA',
      agencia: '1234',
      conta_corrente: '12345',
      documento_cedente: '12345678901',
      convenio: '1234567',
      carteira: '12',
      variacao: '123',
      pagamentos: [pagamento_pix]
    }
  end

  let(:remessa) { described_class.new(params) }

  describe 'heranca e mixin' do
    it 'herda de BancoBrasil' do
      expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab240::BancoBrasil)
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

    it 'codigo do banco 001' do
      expect(segmento_y[0..2]).to eq('001')
    end

    it 'tipo chave telefone mapeado para 3' do
      expect(segmento_y[27]).to eq('3')
    end

    it 'chave DICT (telefone)' do
      expect(segmento_y[28..104].strip).to eq('+5511999999999')
    end

    it 'TXID presente' do
      expect(segmento_y[105..139].strip).to eq('TXID001BB00001')
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

    it 'multiplos pagamentos PIX geram segmentos Y extras' do
      remessa.pagamentos << pagamento_pix.dup
      lote = remessa.monta_lote(1)
      segmentos_y = lote.select { |l| l[13] == 'Y' }
      expect(segmentos_y.size).to eq(2)
    end
  end
end
