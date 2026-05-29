# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PIX — cenarios por banco' do
  let(:pix_attrs) do
    {
      chave_pix: '12345678000100',
      tipo_chave_pix: 'cnpj',
      txid: 'TXID20260529001'
    }
  end

  let(:pix_com_emv) do
    pix_attrs.merge(emv: '00020126580014br.gov.bcb.pix0136a1b2c3d4-e5f6-7890-abcd-ef1234567890')
  end

  shared_examples 'boleto com PIX' do
    it 'boleto e valido' do
      expect(boleto).to be_valid
    end

    it 'dados_pix retorna chave e tipo' do
      pix = boleto.dados_pix
      expect(pix[:chave_pix]).to eq('12345678000100')
      expect(pix[:tipo_chave_pix]).to eq('cnpj')
      expect(pix[:txid]).to eq('TXID20260529001')
    end

    it 'to_hash inclui PIX nos dados de entrada' do
      hash = boleto.to_hash
      expect(hash[:chave_pix]).to eq('12345678000100')
    end

    it 'to_hash inclui PIX nos dados calculados' do
      expect(boleto.to_hash[:pix][:chave_pix]).to eq('12345678000100')
    end

    it 'to_json inclui campos PIX' do
      parsed = JSON.parse(boleto.to_json)
      expect(parsed['chave_pix']).to eq('12345678000100')
    end

    it 'sem EMV qrcode_disponivel e false' do
      expect(boleto.dados_pix[:qrcode_disponivel]).to be false
    end

    it 'com EMV qrcode_disponivel e true' do
      boleto.emv = '00020126580014br.gov.bcb.pix...'
      expect(boleto.dados_pix[:qrcode_disponivel]).to be true
    end
  end

  shared_examples 'boleto sem PIX' do
    it 'dados_pix retorna nil sem campos PIX' do
      expect(boleto.dados_pix).to be_nil
    end

    it 'to_hash nao inclui chave_pix' do
      expect(boleto.to_hash).not_to have_key(:chave_pix)
    end
  end

  describe 'Banco do Brasil (001)' do
    let(:boleto) do
      Brcobranca::Boleto::BancoBrasil.new(
        agencia: '1234', conta_corrente: '12345678',
        convenio: '1238798', carteira: '18',
        nosso_numero: '7700168', valor: 100.00,
        cedente: 'Empresa LTDA', sacado: 'Cliente',
        sacado_documento: '12345678901',
        **pix_attrs
      )
    end

    include_examples 'boleto com PIX'
  end

  describe 'Santander (033)' do
    let(:boleto) do
      Brcobranca::Boleto::Santander.new(
        agencia: '0059', conta_corrente: '000000001',
        convenio: '1899775', carteira: '102',
        nosso_numero: '9000272', valor: 100.00,
        cedente: 'Empresa LTDA', sacado: 'Cliente',
        sacado_documento: '12345678901',
        **pix_attrs
      )
    end

    include_examples 'boleto com PIX'
  end

  describe 'Caixa (104)' do
    let(:boleto) do
      Brcobranca::Boleto::Caixa.new(
        agencia: '0001', conta_corrente: '00000000001',
        convenio: '123456', carteira: '1',
        nosso_numero: '000000000000001', valor: 100.00,
        cedente: 'Empresa LTDA', sacado: 'Cliente',
        sacado_documento: '12345678901',
        **pix_attrs
      )
    end

    include_examples 'boleto com PIX'
  end

  describe 'Bradesco (237)' do
    let(:boleto) do
      Brcobranca::Boleto::Bradesco.new(
        agencia: '0548', conta_corrente: '0001448',
        carteira: '06', nosso_numero: '00000004042',
        valor: 100.00, cedente: 'Empresa LTDA',
        sacado: 'Cliente', sacado_documento: '12345678901',
        **pix_attrs
      )
    end

    include_examples 'boleto com PIX'
  end

  describe 'C6 Bank (336)' do
    let(:boleto) do
      Brcobranca::Boleto::BancoC6.new(
        agencia: '0001', conta_corrente: '0000528',
        convenio: '000000123456',
        carteira: '10', nosso_numero: '0000000001',
        valor: 100.00, cedente: 'Empresa LTDA',
        sacado: 'Cliente', sacado_documento: '12345678901',
        **pix_attrs
      )
    end

    include_examples 'boleto com PIX'
  end

  describe 'Itau (341)' do
    let(:boleto) do
      Brcobranca::Boleto::Itau.new(
        agencia: '0811', conta_corrente: '53678',
        carteira: '175', nosso_numero: '12345678',
        valor: 100.00, cedente: 'Empresa LTDA',
        sacado: 'Cliente', sacado_documento: '12345678901',
        **pix_attrs
      )
    end

    include_examples 'boleto com PIX'
  end

  describe 'Sicoob (756)' do
    let(:boleto) do
      Brcobranca::Boleto::Sicoob.new(
        agencia: '4327', conta_corrente: '417270',
        convenio: '229385', carteira: '1',
        nosso_numero: '2', valor: 100.00,
        cedente: 'Empresa LTDA', sacado: 'Cliente',
        sacado_documento: '12345678901',
        **pix_attrs
      )
    end

    include_examples 'boleto com PIX'
  end

  describe 'Banco sem PIX preenchido' do
    let(:boleto) do
      Brcobranca::Boleto::Bradesco.new(
        agencia: '0548', conta_corrente: '0001448',
        carteira: '06', nosso_numero: '00000004042',
        valor: 100.00, cedente: 'Empresa LTDA',
        sacado: 'Cliente', sacado_documento: '12345678901'
      )
    end

    include_examples 'boleto sem PIX'
  end

  describe 'Tipos de chave PIX' do
    let(:base_attrs) do
      {
        agencia: '4327', conta_corrente: '417270',
        convenio: '229385', carteira: '1',
        nosso_numero: '2', valor: 100.00,
        cedente: 'Empresa LTDA', sacado: 'Cliente',
        sacado_documento: '12345678901'
      }
    end

    it 'CPF' do
      boleto = Brcobranca::Boleto::Sicoob.new(
        base_attrs.merge(chave_pix: '12345678901', tipo_chave_pix: 'cpf')
      )
      expect(boleto.dados_pix[:tipo_chave_pix]).to eq('cpf')
    end

    it 'CNPJ' do
      boleto = Brcobranca::Boleto::Sicoob.new(
        base_attrs.merge(chave_pix: '12345678000100', tipo_chave_pix: 'cnpj')
      )
      expect(boleto.dados_pix[:tipo_chave_pix]).to eq('cnpj')
    end

    it 'email' do
      boleto = Brcobranca::Boleto::Sicoob.new(
        base_attrs.merge(chave_pix: 'financeiro@empresa.com.br', tipo_chave_pix: 'email')
      )
      expect(boleto.dados_pix[:tipo_chave_pix]).to eq('email')
    end

    it 'telefone' do
      boleto = Brcobranca::Boleto::Sicoob.new(
        base_attrs.merge(chave_pix: '+5511999999999', tipo_chave_pix: 'telefone')
      )
      expect(boleto.dados_pix[:tipo_chave_pix]).to eq('telefone')
    end

    it 'chave_aleatoria (UUID)' do
      boleto = Brcobranca::Boleto::Sicoob.new(
        base_attrs.merge(
          chave_pix: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          tipo_chave_pix: 'chave_aleatoria'
        )
      )
      expect(boleto.dados_pix[:tipo_chave_pix]).to eq('chave_aleatoria')
    end
  end
end
