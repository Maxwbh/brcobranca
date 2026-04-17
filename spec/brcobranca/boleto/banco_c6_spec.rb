# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Boleto::BancoC6 do # :nodoc:[all]
  before do
    @valid_attributes = {
      valor: 10.00,
      local_pagamento: 'QUALQUER BANCO ATÉ O VENCIMENTO',
      cedente: 'Kivanio Barbosa',
      documento_cedente: '12345678000191',
      sacado: 'Claudio Pozzebom',
      sacado_documento: '12345678900',
      agencia: '0001',
      conta_corrente: '0000528',
      convenio: '000000123456',
      nosso_numero: '0000000001'
    }
  end

  it 'Criar nova instância com atributos válidos' do
    boleto_novo = described_class.new(@valid_attributes)
    expect(boleto_novo.banco).to eql('336')
    expect(boleto_novo.banco_dv).to eql('7')
    expect(boleto_novo.especie_documento).to eql('DM')
    expect(boleto_novo.especie).to eql('R$')
    expect(boleto_novo.moeda).to eql('9')
    expect(boleto_novo.data_processamento).to eql(Date.current)
    expect(boleto_novo.data_vencimento).to eql(Date.current)
    expect(boleto_novo.aceite).to eql('S')
    expect(boleto_novo.quantidade).to be(1)
    expect(boleto_novo.valor).to eq(10.00)
    expect(boleto_novo.valor_documento).to eq(10.0)
    expect(boleto_novo.cedente).to eql('Kivanio Barbosa')
    expect(boleto_novo.documento_cedente).to eql('12345678000191')
    expect(boleto_novo.sacado).to eql('Claudio Pozzebom')
    expect(boleto_novo.sacado_documento).to eql('12345678900')
    expect(boleto_novo.conta_corrente).to eql('0000528')
    expect(boleto_novo.agencia).to eql('0001')
    expect(boleto_novo.convenio).to eql('000000123456')
    expect(boleto_novo.nosso_numero).to eql('0000000001')
    expect(boleto_novo.carteira).to eql('10')
  end

  it 'Gerar o código de barras' do
    boleto_novo = described_class.new @valid_attributes
    expect { boleto_novo.codigo_barras }.not_to raise_error
    expect(boleto_novo.codigo_barras_segunda_parte).not_to be_blank
  end

  it 'Não permitir gerar boleto com atributos inválidos' do
    boleto_novo = described_class.new
    expect { boleto_novo.codigo_barras }.to raise_error(Brcobranca::BoletoInvalido)
  end

  it 'Convênio deve possuir 12 dígitos' do
    boleto_novo = described_class.new @valid_attributes.merge(convenio: '1234567890123')
    expect(boleto_novo).not_to be_valid
  end

  it 'Convênio deve ser preenchido com zeros à esquerda quando menor que 12 dígitos' do
    boleto_novo = described_class.new @valid_attributes.merge(convenio: '123456')
    expect(boleto_novo.convenio).to eq('000000123456')
    expect(boleto_novo).to be_valid
  end

  it 'Nosso número deve possuir 10 dígitos' do
    boleto_novo = described_class.new @valid_attributes.merge(nosso_numero: '12345678901')
    expect(boleto_novo).not_to be_valid
  end

  it 'Nosso número deve ser preenchido com zeros à esquerda quando menor que 10 dígitos' do
    boleto_novo = described_class.new @valid_attributes.merge(nosso_numero: '1')
    expect(boleto_novo.nosso_numero).to eq('0000000001')
    expect(boleto_novo).to be_valid
  end

  it 'Carteira deve ser 10 ou 20' do
    boleto_valido = described_class.new @valid_attributes.merge(carteira: '10')
    expect(boleto_valido).to be_valid

    boleto_valido2 = described_class.new @valid_attributes.merge(carteira: '20')
    expect(boleto_valido2).to be_valid

    boleto_invalido = described_class.new @valid_attributes.merge(carteira: '99')
    expect(boleto_invalido).not_to be_valid
  end

  it 'Indicador de layout é 3 para carteira 10 e 4 para carteira 20' do
    boleto_c10 = described_class.new @valid_attributes.merge(carteira: '10')
    expect(boleto_c10.indicador_layout).to eq('3')

    boleto_c20 = described_class.new @valid_attributes.merge(carteira: '20')
    expect(boleto_c20.indicador_layout).to eq('4')
  end

  it 'Montar nosso_numero_boleto' do
    boleto_novo = described_class.new @valid_attributes
    expect(boleto_novo.nosso_numero_boleto).to match(/\A0000000001-\d\z/)
  end

  it 'Montar agencia_conta_boleto' do
    boleto_novo = described_class.new(@valid_attributes)
    expect(boleto_novo.agencia_conta_boleto).to eql('0001 / 000000123456')

    boleto_novo.convenio = '654321'
    expect(boleto_novo.agencia_conta_boleto).to eql('0001 / 000000654321')
  end

  it 'Montar segunda parte do código de barras com layout oficial do C6' do
    boleto_novo = described_class.new(@valid_attributes)
    # Formato: [Cedente 12][Nosso 10][Carteira 2][Indicador 1] = 25
    segunda_parte = boleto_novo.codigo_barras_segunda_parte
    expect(segunda_parte.size).to eq(25)
    expect(segunda_parte[0, 12]).to eq('000000123456')
    expect(segunda_parte[12, 10]).to eq('0000000001')
    expect(segunda_parte[22, 2]).to eq('10')
    expect(segunda_parte[24]).to eq('3')
  end

  it 'Montar segunda parte do código de barras para carteira 20 (Emissão Cliente)' do
    boleto_novo = described_class.new(@valid_attributes.merge(carteira: '20'))
    segunda_parte = boleto_novo.codigo_barras_segunda_parte
    expect(segunda_parte[22, 2]).to eq('20')
    expect(segunda_parte[24]).to eq('4')
  end

  it 'Montar código de barras completo de 44 posições' do
    boleto_novo = described_class.new(@valid_attributes)
    codigo = boleto_novo.codigo_barras
    expect(codigo.size).to eq(44)
    expect(codigo[0, 3]).to eq('336')
    expect(codigo[3]).to eq('9')
  end

  describe 'Busca logotipo do banco' do
    it_behaves_like 'busca_logotipo'
  end

  it 'indicador_layout faz parte do código de barras' do
    boleto_novo = described_class.new(@valid_attributes.merge(carteira: '10'))
    expect(boleto_novo.codigo_barras[-1]).to eq('3')

    boleto_novo2 = described_class.new(@valid_attributes.merge(carteira: '20'))
    expect(boleto_novo2.codigo_barras[-1]).to eq('4')
  end
end
