# frozen_string_literal: true

require 'spec_helper'
require 'brcobranca/boleto/template/prawn_carne'

RSpec.describe Brcobranca::Boleto::Template::PrawnCarne do
  before do
    skip 'Gems do Prawn nao instaladas' unless Brcobranca::Boleto::Template::PRAWN_AVAILABLE
  end

  let(:emv) do
    '00020126580014br.gov.bcb.pix0136' \
      '123e4567-e12b-12d1-a456-4266554400005204000053039865802BR' \
      '5913EMPRESA TESTE6009SAO PAULO62070503***63049D3E'
  end

  def parcela(numero, com_pix: true)
    attrs = {
      agencia: '4327', conta_corrente: '417270',
      convenio: '229385', nosso_numero: numero.to_s, carteira: '1',
      valor: 135.00,
      data_vencimento: Date.new(2026, 7, 12),
      data_documento: Date.new(2026, 6, 12),
      documento_numero: "CT-#{numero}",
      cedente: 'Empresa Exemplo LTDA',
      documento_cedente: '12345678000100',
      sacado: 'Cliente Teste da Silva',
      sacado_documento: '12345678900',
      instrucao1: "Parcela #{numero} de 3"
    }
    attrs[:emv] = emv if com_pix
    Brcobranca::Boleto::Sicoob.new(attrs)
  end

  describe '#to_carne' do
    it 'gera PDF valido para um boleto' do
      boleto = parcela(1)
      boleto.extend(described_class)
      pdf = boleto.to_carne(:pdf)
      expect(pdf[0, 4]).to eq('%PDF')
      expect(pdf).to include('%%EOF')
    end

    it 'gera PDF sem PIX quando emv ausente' do
      boleto = parcela(1, com_pix: false)
      boleto.extend(described_class)
      expect(boleto.to_carne(:pdf)[0, 4]).to eq('%PDF')
    end

    it 'rejeita formato diferente de pdf' do
      boleto = parcela(1)
      boleto.extend(described_class)
      expect { boleto.to_carne(:png) }.to raise_error(ArgumentError, /apenas :pdf/)
    end

    it 'responde a to_pdf via method_missing' do
      boleto = parcela(1)
      boleto.extend(described_class)
      expect(boleto.to_pdf[0, 4]).to eq('%PDF')
    end
  end

  describe '.lote_carne' do
    it 'gera PDF com 3 boletos em uma pagina' do
      boletos = (1..3).map { |n| parcela(n) }
      pdf = described_class.lote_carne(boletos)
      expect(pdf[0, 4]).to eq('%PDF')
      expect(pdf.scan('/Type /Page').size).to be >= 1
    end

    it 'gera segunda pagina a partir do quarto boleto' do
      boletos = (1..4).map { |n| parcela(n) }
      pdf = described_class.lote_carne(boletos)
      expect(pdf.scan(%r{/Type /Page\b}).size).to be >= 2
    end
  end
end
