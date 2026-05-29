# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab240::SicoobPix do
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
      codigo_chave_dict: '12345678000100',
      tipo_chave_dict: 'cnpj',
      txid: 'TXID756SICOOB001'
    )
  end

  let(:params) do
    {
      empresa_mae: 'SOCIEDADE BRASILEIRA DE ZOOLOGIA LTDA',
      agencia: '4327',
      conta_corrente: '03666',
      documento_cedente: '74576177000177',
      modalidade_carteira: '01',
      convenio: '512231',
      pagamentos: [pagamento_pix]
    }
  end

  let(:remessa) { described_class.new(params) }

  describe 'heranca e mixin' do
    it 'herda de Sicoob' do
      expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab240::Sicoob)
    end

    it 'inclui PixMixin' do
      expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab240::PixMixin)
    end

    it 'responde a monta_segmento_y' do
      expect(remessa).to respond_to(:monta_segmento_y)
    end
  end

  describe 'segmento Y-03 (PIX)' do
    let(:segmento_y) { remessa.monta_segmento_y(pagamento_pix, 1, 5) }

    it 'tem 240 posicoes' do
      expect(segmento_y.size).to eq(240)
    end

    it 'codigo do banco nas posicoes 1-3' do
      expect(segmento_y[0..2]).to eq('756')
    end

    it 'tipo de registro 3 na posicao 8' do
      expect(segmento_y[7]).to eq('3')
    end

    it 'segmento Y na posicao 14' do
      expect(segmento_y[13]).to eq('Y')
    end

    it 'identificador 03 nas posicoes 17-18' do
      expect(segmento_y[16..17]).to eq('03')
    end

    it 'tipo chave CNPJ mapeado para 2' do
      expect(segmento_y[27]).to eq('2')
    end

    it 'chave DICT nas posicoes 29-105' do
      expect(segmento_y[28..104].strip).to eq('12345678000100')
    end

    it 'TXID nas posicoes 106-140' do
      expect(segmento_y[105..139].strip).to eq('TXID756SICOOB001')
    end
  end

  describe 'lote com segmento Y' do
    it 'lote inclui segmento Y apos P/Q/R' do
      lote = remessa.monta_lote(1)
      segmentos = lote.map { |l| l[13] }
      expect(segmentos).to include('Y')
    end

    it 'lote tem 6 registros: header + P + Q + R + Y + trailer' do
      lote = remessa.monta_lote(1)
      expect(lote.size).to eq(6)
    end

    it 'todos os registros tem 240 posicoes' do
      lote = remessa.monta_lote(1)
      lote.each { |reg| expect(reg.size).to eq(240) }
    end
  end

  describe 'arquivo completo' do
    it 'gera arquivo valido' do
      arquivo = remessa.gera_arquivo
      expect(arquivo).not_to be_empty
    end

    it 'todas as linhas tem 240 posicoes' do
      linhas = remessa.gera_arquivo.split("\r\n").reject(&:empty?)
      linhas.each { |l| expect(l.size).to eq(240) }
    end

    it 'contem segmento Y (PIX)' do
      arquivo = remessa.gera_arquivo
      expect(arquivo).to include('Y')
    end

    it 'multiplos pagamentos PIX geram segmentos Y adicionais' do
      remessa.pagamentos << pagamento_pix.dup
      lote = remessa.monta_lote(1)
      segmentos_y = lote.select { |l| l[13] == 'Y' }
      expect(segmentos_y.size).to eq(2)
    end
  end
end
