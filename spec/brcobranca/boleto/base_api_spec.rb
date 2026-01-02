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

  # ============================================================
  # Fase 2: Métodos de Validação Seguros (v12.3.0)
  # ============================================================

  describe '#valido?' do
    it 'retorna true para boleto válido' do
      expect(boleto.valido?).to be true
    end

    it 'retorna false para boleto inválido sem levantar exceção' do
      boleto_invalido = Brcobranca::Boleto::Sicoob.new

      expect { boleto_invalido.valido? }.not_to raise_error
      expect(boleto_invalido.valido?).to be false
    end

    it 'retorna false quando boleto tem campos obrigatórios vazios' do
      boleto_incompleto = Brcobranca::Boleto::Sicoob.new(
        agencia: '4327',
        conta_corrente: '417270'
        # faltando: nosso_numero, sacado, sacado_documento
      )

      expect(boleto_incompleto.valido?).to be false
    end
  end

  describe '#to_hash_seguro' do
    it 'retorna hash com valid: true para boleto válido' do
      resultado = boleto.to_hash_seguro

      expect(resultado[:valid]).to be true
      expect(resultado[:errors]).to be_empty
      expect(resultado[:codigo_barras]).to be_a(String)
      expect(resultado[:linha_digitavel]).to be_a(String)
    end

    it 'retorna hash com valid: false para boleto inválido' do
      boleto_invalido = Brcobranca::Boleto::Sicoob.new

      resultado = boleto_invalido.to_hash_seguro

      expect(resultado[:valid]).to be false
      expect(resultado[:errors]).to be_an(Array)
      expect(resultado[:errors]).not_to be_empty
    end

    it 'não lança exceção para boleto inválido' do
      boleto_invalido = Brcobranca::Boleto::Sicoob.new

      expect { boleto_invalido.to_hash_seguro }.not_to raise_error
    end

    it 'inclui dados de entrada mesmo quando inválido' do
      boleto_parcial = Brcobranca::Boleto::Sicoob.new(
        cedente: 'Empresa Teste',
        valor: 100.0
      )

      resultado = boleto_parcial.to_hash_seguro

      expect(resultado[:valid]).to be false
      expect(resultado[:cedente]).to eq('Empresa Teste')
      expect(resultado[:valor]).to eq(100.0)
    end

    it 'inclui lista de erros específicos' do
      boleto_invalido = Brcobranca::Boleto::Sicoob.new

      resultado = boleto_invalido.to_hash_seguro

      expect(resultado[:errors]).to include(a_string_matching(/não pode estar em branco/))
    end
  end

  describe '#as_json_seguro' do
    it 'retorna hash com chaves string' do
      resultado = boleto.as_json_seguro

      expect(resultado).to be_a(Hash)
      expect(resultado.keys.first).to be_a(String)
      expect(resultado['valid']).to be true
    end

    it 'funciona para boleto inválido' do
      boleto_invalido = Brcobranca::Boleto::Sicoob.new

      resultado = boleto_invalido.as_json_seguro

      expect(resultado['valid']).to be false
      expect(resultado['errors']).to be_an(Array)
    end
  end

  describe '#to_json_seguro' do
    it 'retorna string JSON válida' do
      json_string = boleto.to_json_seguro

      expect(json_string).to be_a(String)
      expect { JSON.parse(json_string) }.not_to raise_error
    end

    it 'funciona para boleto inválido' do
      boleto_invalido = Brcobranca::Boleto::Sicoob.new

      json_string = boleto_invalido.to_json_seguro
      parsed = JSON.parse(json_string)

      expect(parsed['valid']).to be false
      expect(parsed['errors']).to be_an(Array)
    end
  end
end

RSpec.describe Brcobranca::Util::Errors do
  let(:base_object) { double('base') }
  let(:errors) { described_class.new(base_object) }

  describe '#to_hash' do
    it 'retorna hash vazio quando não há erros' do
      expect(errors.to_hash).to eq({})
    end

    it 'retorna hash com erros agrupados por atributo' do
      errors.add(:sacado, 'não pode estar em branco')
      errors.add(:agencia, 'não é um número')

      resultado = errors.to_hash

      expect(resultado[:sacado]).to include('Sacado não pode estar em branco')
      expect(resultado[:agencia]).to include('Agencia não é um número')
    end

    it 'agrupa múltiplos erros do mesmo atributo' do
      errors.add(:valor, 'não pode estar em branco')
      errors.add(:valor, 'deve ser maior que zero')

      resultado = errors.to_hash

      expect(resultado[:valor].size).to eq(2)
    end
  end

  describe '#as_json' do
    it 'retorna hash com chaves string' do
      errors.add(:sacado, 'erro')

      resultado = errors.as_json

      expect(resultado.keys.first).to be_a(String)
      expect(resultado['sacado']).to be_an(Array)
    end
  end

  describe '#to_json' do
    it 'retorna string JSON válida' do
      errors.add(:campo, 'erro')

      json_string = errors.to_json

      expect(json_string).to be_a(String)
      expect { JSON.parse(json_string) }.not_to raise_error
    end
  end

  describe '#any?' do
    it 'retorna false quando não há erros' do
      expect(errors.any?).to be false
    end

    it 'retorna true quando há erros' do
      errors.add(:campo, 'erro')

      expect(errors.any?).to be true
    end
  end

  describe '#empty?' do
    it 'retorna true quando não há erros' do
      expect(errors.empty?).to be true
    end

    it 'retorna false quando há erros' do
      errors.add(:campo, 'erro')

      expect(errors.empty?).to be false
    end
  end

  describe '#first_messages' do
    it 'retorna primeiro erro de cada atributo' do
      errors.add(:campo1, 'erro 1')
      errors.add(:campo1, 'erro 2')
      errors.add(:campo2, 'erro 3')

      resultado = errors.first_messages

      expect(resultado[:campo1]).to eq('Campo1 erro 1')
      expect(resultado[:campo2]).to eq('Campo2 erro 3')
    end
  end

  describe '#clear' do
    it 'limpa todos os erros' do
      errors.add(:campo, 'erro')
      expect(errors.any?).to be true

      errors.clear

      expect(errors.empty?).to be true
    end
  end

  describe '#merge!' do
    it 'adiciona erros de outro objeto Errors' do
      other_errors = described_class.new(base_object)
      other_errors.add(:campo, 'erro do outro')

      errors.merge!(other_errors)

      expect(errors.to_hash[:campo]).to include('Campo erro do outro')
    end
  end
end
