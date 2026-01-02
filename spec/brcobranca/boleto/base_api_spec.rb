# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Brcobranca::Boleto::Base API' do
  # Usamos Sicoob como exemplo pois é um banco bem documentado
  let(:valid_attributes) do
    {
      data_documento: Date.parse('2016-02-16'),
      data_vencimento: Date.parse('2016-02-18'),
      aceite: 'N',
      valor: 50.0,
      cedente: 'Kivanio Barbosa',
      documento_cedente: '12345678912',
      sacado: 'Claudio Pozzebom',
      sacado_documento: '12345678900',
      agencia: '4327',
      conta_corrente: '417270',
      convenio: '229385',
      nosso_numero: '2'
    }
  end

  let(:boleto) { Brcobranca::Boleto::Sicoob.new(valid_attributes) }

  describe '#to_hash' do
    it 'retorna um Hash com todos os dados do boleto' do
      resultado = boleto.to_hash

      expect(resultado).to be_a(Hash)
      expect(resultado.keys).to include(:convenio, :valor, :codigo_barras, :linha_digitavel)
    end

    it 'inclui dados de entrada' do
      resultado = boleto.to_hash

      expect(resultado[:convenio]).to eq('0229385')
      expect(resultado[:valor]).to eq(50.0)
      expect(resultado[:cedente]).to eq('Kivanio Barbosa')
      expect(resultado[:sacado]).to eq('Claudio Pozzebom')
    end

    it 'inclui dados calculados' do
      resultado = boleto.to_hash

      expect(resultado[:banco]).to eq('756')
      expect(resultado[:banco_nome]).to eq('Sicoob')
      expect(resultado[:codigo_barras]).to be_a(String)
      expect(resultado[:codigo_barras].length).to eq(44)
      expect(resultado[:linha_digitavel]).to be_a(String)
      expect(resultado[:nosso_numero_boleto]).to eq('00000024')
    end

    it 'retorna apenas dados calculados com opção somente_calculados' do
      resultado = boleto.to_hash(somente_calculados: true)

      expect(resultado.keys).to include(:banco, :codigo_barras, :linha_digitavel)
      expect(resultado.keys).not_to include(:convenio, :valor, :cedente)
    end

    it 'lança exceção para boleto inválido' do
      boleto_invalido = Brcobranca::Boleto::Sicoob.new

      expect { boleto_invalido.to_hash }.to raise_error(Brcobranca::BoletoInvalido)
    end
  end

  describe '#as_json' do
    it 'retorna Hash com chaves string' do
      resultado = boleto.as_json

      expect(resultado).to be_a(Hash)
      expect(resultado.keys.first).to be_a(String)
      expect(resultado['codigo_barras']).to be_a(String)
    end

    it 'aceita opção somente_calculados' do
      resultado = boleto.as_json(somente_calculados: true)

      expect(resultado.keys).to include('banco', 'codigo_barras')
      expect(resultado.keys).not_to include('convenio', 'cedente')
    end
  end

  describe '#to_json' do
    it 'retorna uma string JSON válida' do
      json_string = boleto.to_json

      expect(json_string).to be_a(String)
      expect { JSON.parse(json_string) }.not_to raise_error
    end

    it 'contém os dados do boleto' do
      json_string = boleto.to_json
      parsed = JSON.parse(json_string)

      expect(parsed['banco']).to eq('756')
      expect(parsed['codigo_barras']).to be_a(String)
    end
  end

  describe '#dados_entrada' do
    it 'retorna apenas campos de entrada' do
      resultado = boleto.dados_entrada

      expect(resultado).to be_a(Hash)
      expect(resultado.keys).to include(:convenio, :valor, :cedente, :sacado)
      expect(resultado.keys).not_to include(:banco, :codigo_barras, :linha_digitavel)
    end

    it 'não lança exceção para boleto inválido' do
      boleto_invalido = Brcobranca::Boleto::Sicoob.new

      expect { boleto_invalido.dados_entrada }.not_to raise_error
    end
  end

  describe '#dados_calculados' do
    it 'retorna campos calculados' do
      resultado = boleto.dados_calculados

      expect(resultado[:banco]).to eq('756')
      expect(resultado[:banco_dv]).to be_a(Integer)
      expect(resultado[:banco_nome]).to eq('Sicoob')
      expect(resultado[:nosso_numero_dv]).to be_a(Integer)
      expect(resultado[:nosso_numero_boleto]).to eq('00000024')
      expect(resultado[:agencia_conta_boleto]).to eq('4327 / 0229385')
      expect(resultado[:valor_documento]).to eq(50.0)
      expect(resultado[:codigo_barras].length).to eq(44)
      expect(resultado[:linha_digitavel]).to include('.')
    end

    it 'lança exceção para boleto inválido' do
      boleto_invalido = Brcobranca::Boleto::Sicoob.new

      expect { boleto_invalido.dados_calculados }.to raise_error(Brcobranca::BoletoInvalido)
    end
  end

  describe '#banco_nome' do
    it 'retorna o nome do banco' do
      expect(boleto.banco_nome).to eq('Sicoob')
    end

    it 'retorna nome correto para diferentes bancos' do
      bradesco = Brcobranca::Boleto::Bradesco.new(valid_attributes.merge(conta_corrente: '1234567'))
      expect(bradesco.banco_nome).to eq('Bradesco')

      itau = Brcobranca::Boleto::Itau.new(valid_attributes)
      expect(itau.banco_nome).to eq('Itau')
    end
  end

  describe '#dados_pix' do
    it 'retorna nil quando emv não está definido' do
      expect(boleto.dados_pix).to be_nil
    end

    it 'retorna dados do PIX quando emv está definido' do
      boleto_pix = Brcobranca::Boleto::Sicoob.new(
        valid_attributes.merge(emv: '00020126580014br.gov.bcb.pix...')
      )

      resultado = boleto_pix.dados_pix

      expect(resultado).to be_a(Hash)
      expect(resultado[:emv]).to start_with('00020126')
      expect(resultado[:qrcode_disponivel]).to be true
    end
  end

  describe 'compatibilidade com diferentes bancos' do
    it 'funciona com Bradesco' do
      bradesco = Brcobranca::Boleto::Bradesco.new(
        valid_attributes.merge(conta_corrente: '1234567')
      )

      expect { bradesco.to_hash }.not_to raise_error
      expect(bradesco.to_hash[:banco]).to eq('237')
    end

    it 'funciona com Itau' do
      itau = Brcobranca::Boleto::Itau.new(valid_attributes)

      expect { itau.to_hash }.not_to raise_error
      expect(itau.to_hash[:banco]).to eq('341')
    end

    it 'funciona com Caixa' do
      caixa = Brcobranca::Boleto::Caixa.new(
        valid_attributes.merge(
          convenio: '123456',
          versao_aplicativo: '0'
        )
      )

      expect { caixa.to_hash }.not_to raise_error
      expect(caixa.to_hash[:banco]).to eq('104')
    end
  end
end
