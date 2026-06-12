# frozen_string_literal: true

require 'spec_helper'
require 'brcobranca/boleto/template/prawn_tema'

RSpec.describe Brcobranca::Boleto::Template::PrawnTema do
  let(:boleto) do
    Brcobranca::Boleto::Sicoob.new(
      agencia: '4327', conta_corrente: '417270',
      convenio: '229385', nosso_numero: '2', carteira: '1',
      valor: 135.00, cedente: 'Empresa', documento_cedente: '12345678000100',
      sacado: 'Cliente', sacado_documento: '12345678900'
    )
  end

  describe '.cor_marca' do
    it 'aceita hex valido' do
      boleto.cor_marca = '006B3F'
      expect(described_class.cor_marca(boleto)).to eq('006B3F')
    end

    it 'aceita hex com prefixo # e normaliza para maiusculas' do
      boleto.cor_marca = '#aabbcc'
      expect(described_class.cor_marca(boleto)).to eq('AABBCC')
    end

    it 'rejeita valores invalidos' do
      ['zzz', '12345', '1234567', 'red', ''].each do |invalido|
        boleto.cor_marca = invalido
        expect(described_class.cor_marca(boleto)).to be_nil
      end
    end

    it 'retorna nil quando ausente' do
      expect(described_class.cor_marca(boleto)).to be_nil
    end
  end

  describe '.cor_texto_sobre' do
    it 'retorna branco sobre cores escuras' do
      expect(described_class.cor_texto_sobre('006B3F')).to eq('FFFFFF')
      expect(described_class.cor_texto_sobre('000000')).to eq('FFFFFF')
    end

    it 'retorna preto sobre cores claras' do
      expect(described_class.cor_texto_sobre('FFFF00')).to eq('000000')
      expect(described_class.cor_texto_sobre('FFFFFF')).to eq('000000')
    end
  end

  describe '.selo_parcela' do
    it 'monta o selo quando atual e total presentes' do
      boleto.parcela_atual = 2
      boleto.total_parcelas = 12
      expect(described_class.selo_parcela(boleto)).to eq('PARCELA 2/12')
    end

    it 'retorna nil sem total' do
      boleto.parcela_atual = 2
      expect(described_class.selo_parcela(boleto)).to be_nil
    end

    it 'retorna nil quando atual maior que total' do
      boleto.parcela_atual = 5
      boleto.total_parcelas = 3
      expect(described_class.selo_parcela(boleto)).to be_nil
    end
  end

  describe '.logo_empresa' do
    it 'retorna nil para path inexistente' do
      boleto.logo_empresa = '/caminho/que/nao/existe.png'
      expect(described_class.logo_empresa(boleto)).to be_nil
    end

    it 'aceita IO' do
      io = StringIO.new('fake-png')
      boleto.logo_empresa = io
      expect(described_class.logo_empresa(boleto)).to eq(io)
    end

    it 'retorna nil quando ausente' do
      expect(described_class.logo_empresa(boleto)).to be_nil
    end
  end

  describe '.rodape_contato' do
    it 'trunca em 120 caracteres' do
      boleto.rodape_contato = 'x' * 200
      expect(described_class.rodape_contato(boleto).size).to eq(120)
    end

    it 'retorna nil para texto vazio' do
      boleto.rodape_contato = '   '
      expect(described_class.rodape_contato(boleto)).to be_nil
    end
  end

  describe '.tema?' do
    it 'false sem nenhum atributo' do
      expect(described_class.tema?(boleto)).to be false
    end

    it 'true com cor_marca' do
      boleto.cor_marca = '006B3F'
      expect(described_class.tema?(boleto)).to be true
    end

    it 'true com selo de parcela' do
      boleto.parcela_atual = 1
      boleto.total_parcelas = 3
      expect(described_class.tema?(boleto)).to be true
    end
  end
end
