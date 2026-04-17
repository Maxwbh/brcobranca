# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab400::PixMixin do
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
      valor_maximo_pix: 199.90,
      valor_minimo_pix: 199.90,
      txid: 'TXID20250625001'
    )
  end

  # Classe dummy para testar o mixin isolado
  let(:dummy_class) do
    Class.new do
      include Brcobranca::Remessa::Cnab400::PixMixin
    end
  end

  let(:instancia) { dummy_class.new }

  describe '#monta_detalhe_pix' do
    it 'gera registro de 400 posições' do
      detalhe = instancia.monta_detalhe_pix(pagamento_pix, 2)
      expect(detalhe.size).to eq(400)
    end

    it 'começa com "8" (código do registro PIX)' do
      detalhe = instancia.monta_detalhe_pix(pagamento_pix, 2)
      expect(detalhe[0]).to eq('8')
    end

    it 'inclui o tipo de pagamento nas posições 2-3' do
      detalhe = instancia.monta_detalhe_pix(pagamento_pix, 2)
      expect(detalhe[1..2]).to eq('00')
    end

    it 'mapeia tipo de chave CPF para "1" na posição 43' do
      detalhe = instancia.monta_detalhe_pix(pagamento_pix, 2)
      expect(detalhe[42]).to eq('1')
    end

    it 'mapeia tipo de chave CNPJ para "2" na posição 43' do
      pagamento_pix.tipo_chave_dict = 'cnpj'
      pagamento_pix.codigo_chave_dict = '12345678000100'
      detalhe = instancia.monta_detalhe_pix(pagamento_pix, 2)
      expect(detalhe[42]).to eq('2')
    end

    it 'inclui a chave DICT nas posições 44-120' do
      detalhe = instancia.monta_detalhe_pix(pagamento_pix, 2)
      expect(detalhe[43..119].strip).to eq('12345678901')
    end

    it 'inclui o TXID nas posições 121-155' do
      detalhe = instancia.monta_detalhe_pix(pagamento_pix, 2)
      expect(detalhe[120..154].strip).to eq('TXID20250625001')
    end

    it 'inclui o número sequencial nas posições 395-400' do
      detalhe = instancia.monta_detalhe_pix(pagamento_pix, 42)
      expect(detalhe[394..399]).to eq('000042')
    end

    it 'falha com pagamento PIX inválido' do
      pagamento_pix.codigo_chave_dict = nil
      expect {
        instancia.monta_detalhe_pix(pagamento_pix, 2)
      }.to raise_error(Brcobranca::RemessaInvalida)
    end
  end

  describe 'constante DICT_MAPPING' do
    it 'mapeia todos os tipos de chave DICT' do
      expect(Brcobranca::Remessa::Cnab400::PixMixin::DICT_MAPPING).to eq(
        cpf: '1',
        cnpj: '2',
        telefone: '3',
        email: '4',
        chave_aleatoria: '5'
      )
    end
  end
end

RSpec.describe Brcobranca::Remessa::Cnab400::BradescoPix do
  it 'herda de Bradesco e inclui PixMixin' do
    expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab400::Bradesco)
    expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab400::PixMixin)
  end

  it 'responde a monta_detalhe_pix' do
    expect(described_class.new).to respond_to(:monta_detalhe_pix)
  end
end

RSpec.describe Brcobranca::Remessa::Cnab400::ItauPix do
  it 'herda de Itau e inclui PixMixin' do
    expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab400::Itau)
    expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab400::PixMixin)
  end
end

RSpec.describe Brcobranca::Remessa::Cnab400::BancoC6Pix do
  it 'herda de BancoC6 e inclui PixMixin' do
    expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab400::BancoC6)
    expect(described_class.ancestors).to include(Brcobranca::Remessa::Cnab400::PixMixin)
  end
end
