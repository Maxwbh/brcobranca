# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab400::Sicoob do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(
      valor: 50.00,
      data_vencimento: Date.current,
      nosso_numero: 1,
      documento_sacado: '12345678901',
      nome_sacado: 'CLIENTE TESTE',
      endereco_sacado: 'RUA TESTE',
      bairro_sacado: 'CENTRO',
      cep_sacado: '12345678',
      cidade_sacado: 'SAO PAULO',
      uf_sacado: 'SP'
    )
  end

  let(:base_params) do
    {
      carteira: '01',
      agencia: '1234',
      conta_corrente: '12345678',
      digito_conta: '1',
      sequencial_remessa: '1',
      empresa_mae: 'EMPRESA EXEMPLO LTDA',
      documento_cedente: '12345678910',
      convenio: '123456789',
      modalidade_carteira: '2',
      tipo_formulario: '4',
      pagamentos: [pagamento]
    }
  end

  describe 'nome do banco configurável' do
    it 'usa "BANCOOBCED" como default para compatibilidade' do
      remessa = described_class.new(base_params)
      expect(remessa.nome_banco.strip).to eq('BANCOOBCED')
    end

    it 'permite definir "SICOOB" como nome do banco' do
      remessa = described_class.new(base_params.merge(nome_banco: 'SICOOB'))
      expect(remessa.nome_banco.strip).to eq('SICOOB')
    end

    it 'nome do banco sempre tem 15 caracteres' do
      remessa = described_class.new(base_params.merge(nome_banco: 'SICOOB'))
      expect(remessa.nome_banco.size).to eq(15)
    end

    it 'suporta numero_contrato para Carteira 9' do
      remessa = described_class.new(base_params.merge(numero_contrato: '1234567'))
      expect(remessa.numero_contrato).to eq('1234567')
    end

    it 'identifica carteira_contrato? para carteira 9' do
      remessa = described_class.new(base_params.merge(carteira: '09'))
      expect(remessa.carteira_contrato?).to be true
    end

    it 'identifica carteira_contrato? como false para carteira tradicional' do
      remessa = described_class.new(base_params)
      expect(remessa.carteira_contrato?).to be false
    end
  end
end
