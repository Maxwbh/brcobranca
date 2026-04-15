# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab240::Sicoob do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(
      valor: 199.9,
      data_vencimento: Date.current,
      nosso_numero: 123,
      documento_sacado: '12345678901',
      nome_sacado: 'CLIENTE TESTE',
      endereco_sacado: 'RUA TESTE 123',
      bairro_sacado: 'CENTRO',
      cep_sacado: '12345678',
      cidade_sacado: 'SAO PAULO',
      uf_sacado: 'SP'
    )
  end

  let(:base_params) do
    {
      carteira: '1',
      agencia: '1234',
      conta_corrente: '12345678',
      digito_conta: '1',
      empresa_mae: 'EMPRESA EXEMPLO LTDA',
      documento_cedente: '12345678910',
      convenio: '123456789',
      modalidade_carteira: '01',
      tipo_formulario: '4',
      parcela: '01',
      pagamentos: [pagamento]
    }
  end

  describe 'Layout 810 (Sicoob não calcula DV do nosso número)' do
    it 'versão padrão do layout é 081' do
      remessa = described_class.new(base_params)
      expect(remessa.versao_layout_arquivo).to eq('081')
    end

    it 'aceita versão 810 (cliente calcula DV)' do
      remessa = described_class.new(base_params.merge(versao_layout_arquivo_opcao: '810'))
      expect(remessa.versao_layout_arquivo).to eq('810')
      expect(remessa.valid?).to be true
    end

    it 'aceita versão 081' do
      remessa = described_class.new(base_params.merge(versao_layout_arquivo_opcao: '081'))
      expect(remessa.versao_layout_arquivo).to eq('081')
      expect(remessa.valid?).to be true
    end

    it 'rejeita versão inválida' do
      remessa = described_class.new(base_params.merge(versao_layout_arquivo_opcao: '999'))
      expect(remessa.valid?).to be false
      expect(remessa.errors.full_messages).to include(/deve ser 081 ou 810/)
    end

    it 'aceita numero_contrato para Carteira 9' do
      remessa = described_class.new(base_params.merge(numero_contrato: '1234567'))
      expect(remessa.numero_contrato).to eq('1234567')
    end
  end
end
