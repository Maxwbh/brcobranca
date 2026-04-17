# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Boleto::Sicoob do
  describe 'Carteira 9 (nova modalidade com Número do Contrato)' do
    let(:valid_attributes) do
      {
        data_documento: Date.parse('2025-06-10'),
        data_vencimento: Date.parse('2025-06-20'),
        aceite: 'N',
        valor: 100.00,
        cedente: 'EMPRESA EXEMPLO LTDA',
        documento_cedente: '12345678000100',
        sacado: 'Cliente Teste',
        sacado_documento: '12345678900',
        agencia: '4327',
        conta_corrente: '417270',
        convenio: '229385',
        numero_contrato: '0000123',
        nosso_numero: '1',
        carteira: '9'
      }
    end

    it 'identifica corretamente carteira que usa número de contrato' do
      boleto = described_class.new(valid_attributes)
      expect(boleto.carteira_contrato?).to be true
    end

    it 'identifica carteira tradicional corretamente' do
      boleto = described_class.new(valid_attributes.merge(carteira: '1'))
      expect(boleto.carteira_contrato?).to be false
    end

    it 'aceita também carteira "09"' do
      boleto = described_class.new(valid_attributes.merge(carteira: '09'))
      expect(boleto.carteira_contrato?).to be true
    end

    it 'formata número do contrato com zeros à esquerda' do
      boleto = described_class.new(valid_attributes.merge(numero_contrato: '123'))
      expect(boleto.numero_contrato).to eq('0000123')
    end

    it 'na Carteira 9, usa numero_contrato no código de barras em vez de convenio' do
      boleto = described_class.new(valid_attributes)
      segunda_parte = boleto.codigo_barras_segunda_parte
      expect(segunda_parte.size).to be(25)
      # Estrutura: carteira(1) + agencia(4) + variacao(2) + contrato(7) + nosso_num(8) + quantidade(3)
      expect(segunda_parte[0]).to eq('9')
      expect(segunda_parte[1..4]).to eq('4327')
      expect(segunda_parte[7..13]).to eq('0000123') # numero_contrato, NÃO convenio
    end

    it 'na carteira tradicional, continua usando convenio no código de barras' do
      boleto = described_class.new(valid_attributes.merge(carteira: '1'))
      segunda_parte = boleto.codigo_barras_segunda_parte
      expect(segunda_parte[7..13]).to eq('0229385') # convenio
    end

    it 'na Carteira 9, agencia_conta_boleto usa numero_contrato' do
      boleto = described_class.new(valid_attributes)
      expect(boleto.agencia_conta_boleto).to eq('4327 / 0000123')
    end

    it 'DV do nosso número na Carteira 9 usa numero_contrato' do
      boleto_c1 = described_class.new(valid_attributes.merge(carteira: '1'))
      boleto_c9 = described_class.new(valid_attributes)
      # DV deve ser diferente pois a base do cálculo muda
      expect(boleto_c9.nosso_numero_dv).not_to eq(boleto_c1.nosso_numero_dv) if valid_attributes[:numero_contrato] != valid_attributes[:convenio]
    end

    it 'aceita número do contrato com até 7 dígitos' do
      boleto = described_class.new(valid_attributes.merge(numero_contrato: '1234567'))
      expect(boleto).to be_valid
    end

    it 'rejeita número do contrato maior que 7 dígitos' do
      boleto = described_class.new(valid_attributes.merge(numero_contrato: '12345678'))
      expect(boleto).not_to be_valid
    end

    it 'numero_contrato é opcional para carteiras tradicionais' do
      boleto = described_class.new(valid_attributes.merge(carteira: '1', numero_contrato: nil))
      expect(boleto).to be_valid
    end
  end
end
