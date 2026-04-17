# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab240::PixMixin do
  let(:pagamento_pix) do
    Brcobranca::Remessa::PagamentoPix.new(
      valor: 199.90,
      data_vencimento: Date.parse('2025-06-25'),
      nosso_numero: 123,
      documento_sacado: '12345678901',
      nome_sacado: 'CLIENTE TESTE',
      endereco_sacado: 'RUA TESTE 123',
      bairro_sacado: 'CENTRO',
      cep_sacado: '12345678',
      cidade_sacado: 'SAO PAULO',
      uf_sacado: 'SP',
      codigo_chave_dict: '12345678901',
      tipo_chave_dict: 'cpf',
      txid: 'TXID20250625001'
    )
  end

  let(:dummy_class) do
    Class.new do
      include Brcobranca::Remessa::Cnab240::PixMixin

      def cod_banco
        '756'
      end
    end
  end

  let(:instancia) { dummy_class.new }

  describe '#monta_segmento_y' do
    it 'gera segmento de 240 posições' do
      segmento = instancia.monta_segmento_y(pagamento_pix, 1, 5)
      expect(segmento.size).to eq(240)
    end

    it 'inclui código do banco nas posições 1-3' do
      segmento = instancia.monta_segmento_y(pagamento_pix, 1, 5)
      expect(segmento[0..2]).to eq('756')
    end

    it 'inclui código do lote nas posições 4-7' do
      segmento = instancia.monta_segmento_y(pagamento_pix, 42, 5)
      expect(segmento[3..6]).to eq('0042')
    end

    it 'inclui tipo de registro "3" na posição 8' do
      segmento = instancia.monta_segmento_y(pagamento_pix, 1, 5)
      expect(segmento[7]).to eq('3')
    end

    it 'inclui identificador de segmento "Y" na posição 14' do
      segmento = instancia.monta_segmento_y(pagamento_pix, 1, 5)
      expect(segmento[13]).to eq('Y')
    end

    it 'inclui identificador de registro opcional "03" nas posições 17-18' do
      segmento = instancia.monta_segmento_y(pagamento_pix, 1, 5)
      expect(segmento[16..17]).to eq('03')
    end

    it 'mapeia tipo de chave CPF para "1" na posição 28' do
      segmento = instancia.monta_segmento_y(pagamento_pix, 1, 5)
      expect(segmento[27]).to eq('1')
    end

    it 'inclui a chave DICT nas posições 29-105' do
      segmento = instancia.monta_segmento_y(pagamento_pix, 1, 5)
      expect(segmento[28..104].strip).to eq('12345678901')
    end

    it 'inclui o TXID nas posições 106-140' do
      segmento = instancia.monta_segmento_y(pagamento_pix, 1, 5)
      expect(segmento[105..139].strip).to eq('TXID20250625001')
    end

    it 'falha com pagamento PIX inválido' do
      pagamento_pix.codigo_chave_dict = nil
      expect {
        instancia.monta_segmento_y(pagamento_pix, 1, 5)
      }.to raise_error(Brcobranca::RemessaInvalida)
    end
  end
end

RSpec.describe Brcobranca::Remessa::Cnab240::SicoobPix do
  it 'herda de Sicoob e inclui PixMixin' do
    expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab240::Sicoob)
    expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab240::PixMixin)
  end

  it 'responde a monta_segmento_y' do
    expect(described_class.new).to respond_to(:monta_segmento_y)
  end
end

RSpec.describe Brcobranca::Remessa::Cnab240::CaixaPix do
  it 'herda de Caixa e inclui PixMixin' do
    expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab240::Caixa)
    expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab240::PixMixin)
  end
end

RSpec.describe Brcobranca::Remessa::Cnab240::BancoBrasilPix do
  it 'herda de BancoBrasil e inclui PixMixin' do
    expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab240::BancoBrasil)
    expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab240::PixMixin)
  end
end
