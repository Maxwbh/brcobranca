# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Brcobranca::Remessa API' do
  # ============================================================
  # Fase 3: Testes da API de Serialização para Remessa (v12.4.0)
  # ============================================================

  let(:pagamento_valido) do
    Brcobranca::Remessa::Pagamento.new(
      nosso_numero: '00001',
      data_vencimento: Date.parse('2025-12-31'),
      valor: 100.50,
      documento_sacado: '12345678901',
      nome_sacado: 'Cliente Exemplo',
      endereco_sacado: 'Rua Teste, 123',
      bairro_sacado: 'Centro',
      cep_sacado: '12345678',
      cidade_sacado: 'São Paulo',
      uf_sacado: 'SP'
    )
  end

  let(:pagamento_invalido) do
    Brcobranca::Remessa::Pagamento.new
  end

  # Parâmetros base para testes (compatíveis com Sicoob CNAB400)
  let(:remessa_params) do
    {
      empresa_mae: 'Empresa Teste LTDA',
      agencia: '1234',
      conta_corrente: '12345678',
      digito_conta: '1',
      carteira: '01',
      sequencial_remessa: '1',
      documento_cedente: '12345678000190',
      modalidade_carteira: '2',
      tipo_formulario: '4',
      pagamentos: [pagamento_valido]
    }
  end

  # ============================================================
  # Testes do Pagamento
  # ============================================================

  describe Brcobranca::Remessa::Pagamento do
    describe '#valido?' do
      it 'retorna true para pagamento válido' do
        expect(pagamento_valido.valido?).to be true
      end

      it 'retorna false para pagamento inválido sem exceção' do
        expect { pagamento_invalido.valido? }.not_to raise_error
        expect(pagamento_invalido.valido?).to be false
      end
    end

    describe '#to_hash' do
      it 'retorna um Hash com todos os atributos' do
        resultado = pagamento_valido.to_hash

        expect(resultado).to be_a(Hash)
        expect(resultado[:nosso_numero]).to eq('00001')
        expect(resultado[:valor]).to eq(100.50)
        expect(resultado[:nome_sacado]).to eq('Cliente Exemplo')
        expect(resultado[:uf_sacado]).to eq('SP')
      end

      it 'inclui todos os atributos definidos' do
        resultado = pagamento_valido.to_hash

        expect(resultado.keys).to include(
          :nosso_numero, :data_vencimento, :valor,
          :documento_sacado, :nome_sacado, :endereco_sacado,
          :cep_sacado, :cidade_sacado, :uf_sacado
        )
      end
    end

    describe '#as_json' do
      it 'retorna Hash com chaves string' do
        resultado = pagamento_valido.as_json

        expect(resultado).to be_a(Hash)
        expect(resultado.keys.first).to be_a(String)
        expect(resultado['nosso_numero']).to eq('00001')
      end
    end

    describe '#to_json' do
      it 'retorna string JSON válida' do
        json_string = pagamento_valido.to_json

        expect(json_string).to be_a(String)
        expect { JSON.parse(json_string) }.not_to raise_error
      end

      it 'contém os dados do pagamento' do
        parsed = JSON.parse(pagamento_valido.to_json)

        expect(parsed['nosso_numero']).to eq('00001')
        expect(parsed['valor']).to eq(100.50)
      end
    end

    describe '#to_hash_seguro' do
      it 'retorna hash com valid: true para pagamento válido' do
        resultado = pagamento_valido.to_hash_seguro

        expect(resultado[:valid]).to be true
        expect(resultado[:errors]).to be_empty
        expect(resultado[:nosso_numero]).to eq('00001')
      end

      it 'retorna hash com valid: false para pagamento inválido' do
        resultado = pagamento_invalido.to_hash_seguro

        expect(resultado[:valid]).to be false
        expect(resultado[:errors]).to be_an(Array)
        expect(resultado[:errors]).not_to be_empty
      end

      it 'não lança exceção para pagamento inválido' do
        expect { pagamento_invalido.to_hash_seguro }.not_to raise_error
      end

      it 'inclui lista de erros específicos' do
        resultado = pagamento_invalido.to_hash_seguro

        expect(resultado[:errors]).to include(a_string_matching(/não pode estar em branco/))
      end
    end

    describe '#as_json_seguro' do
      it 'retorna hash com chaves string' do
        resultado = pagamento_valido.as_json_seguro

        expect(resultado).to be_a(Hash)
        expect(resultado.keys.first).to be_a(String)
        expect(resultado['valid']).to be true
      end

      it 'funciona para pagamento inválido' do
        resultado = pagamento_invalido.as_json_seguro

        expect(resultado['valid']).to be false
        expect(resultado['errors']).to be_an(Array)
      end
    end

    describe '#to_json_seguro' do
      it 'retorna string JSON válida' do
        json_string = pagamento_valido.to_json_seguro

        expect(json_string).to be_a(String)
        expect { JSON.parse(json_string) }.not_to raise_error
      end

      it 'funciona para pagamento inválido' do
        json_string = pagamento_invalido.to_json_seguro
        parsed = JSON.parse(json_string)

        expect(parsed['valid']).to be false
        expect(parsed['errors']).to be_an(Array)
      end
    end
  end

  # ============================================================
  # Testes do Remessa::Base (via Cnab400::Sicoob)
  # ============================================================

  describe Brcobranca::Remessa::Base do
    let(:remessa) do
      Brcobranca::Remessa::Cnab400::Sicoob.new(
        remessa_params.merge(convenio: '123456789')
      )
    end

    let(:remessa_invalida) do
      Brcobranca::Remessa::Cnab400::Sicoob.new
    end

    describe '#valido?' do
      it 'retorna true para remessa válida' do
        expect(remessa.valido?).to be true
      end

      it 'retorna false para remessa inválida sem exceção' do
        expect { remessa_invalida.valido? }.not_to raise_error
        expect(remessa_invalida.valido?).to be false
      end
    end

    describe '#dados_entrada' do
      it 'retorna dados base da remessa' do
        resultado = remessa.dados_entrada

        expect(resultado).to be_a(Hash)
        expect(resultado[:empresa_mae]).to eq('Empresa Teste LTDA')
        expect(resultado[:agencia]).to eq('1234')
        expect(resultado[:conta_corrente]).to eq('12345678')
      end
    end

    describe '#dados_calculados' do
      it 'retorna dados calculados' do
        resultado = remessa.dados_calculados

        expect(resultado[:quantidade_titulos]).to eq(1)
        expect(resultado[:valor_total]).to eq(100.50)
        expect(resultado[:valor_total_formatado]).to be_a(String)
      end
    end

    describe '#to_hash' do
      it 'retorna Hash com todos os dados' do
        resultado = remessa.to_hash

        expect(resultado).to be_a(Hash)
        expect(resultado[:empresa_mae]).to eq('Empresa Teste LTDA')
        expect(resultado[:quantidade_titulos]).to eq(1)
      end

      it 'inclui pagamentos por padrão' do
        resultado = remessa.to_hash

        expect(resultado[:pagamentos]).to be_an(Array)
        expect(resultado[:pagamentos].first).to be_a(Hash)
        expect(resultado[:pagamentos].first[:nosso_numero]).to eq('00001')
      end

      it 'pode excluir pagamentos' do
        resultado = remessa.to_hash(incluir_pagamentos: false)

        expect(resultado[:pagamentos]).to be_nil
      end

      it 'retorna apenas dados calculados com opção' do
        resultado = remessa.to_hash(somente_calculados: true)

        expect(resultado.keys).to include(:quantidade_titulos, :valor_total)
        expect(resultado.keys).not_to include(:empresa_mae, :agencia)
      end
    end

    describe '#as_json' do
      it 'retorna Hash com chaves string' do
        resultado = remessa.as_json

        expect(resultado).to be_a(Hash)
        expect(resultado.keys.first).to be_a(String)
        expect(resultado['empresa_mae']).to eq('Empresa Teste LTDA')
      end

      it 'converte chaves de pagamentos também' do
        resultado = remessa.as_json

        expect(resultado['pagamentos'].first).to be_a(Hash)
        expect(resultado['pagamentos'].first.keys.first).to be_a(String)
      end
    end

    describe '#to_json' do
      it 'retorna string JSON válida' do
        json_string = remessa.to_json

        expect(json_string).to be_a(String)
        expect { JSON.parse(json_string) }.not_to raise_error
      end

      it 'contém os dados da remessa' do
        parsed = JSON.parse(remessa.to_json)

        expect(parsed['empresa_mae']).to eq('Empresa Teste LTDA')
        expect(parsed['quantidade_titulos']).to eq(1)
      end
    end

    describe '#to_hash_seguro' do
      it 'retorna hash com valid: true para remessa válida' do
        resultado = remessa.to_hash_seguro

        expect(resultado[:valid]).to be true
        expect(resultado[:errors]).to be_empty
        expect(resultado[:empresa_mae]).to eq('Empresa Teste LTDA')
      end

      it 'retorna hash com valid: false para remessa inválida' do
        resultado = remessa_invalida.to_hash_seguro

        expect(resultado[:valid]).to be false
        expect(resultado[:errors]).not_to be_empty
      end

      it 'inclui validação de pagamentos' do
        resultado = remessa.to_hash_seguro

        expect(resultado[:pagamentos]).to be_an(Array)
        expect(resultado[:pagamentos].first[:valid]).to be true
      end

      it 'não lança exceção para remessa inválida' do
        expect { remessa_invalida.to_hash_seguro }.not_to raise_error
      end
    end

    describe '#as_json_seguro' do
      it 'retorna hash com chaves string' do
        resultado = remessa.as_json_seguro

        expect(resultado['valid']).to be true
        expect(resultado['empresa_mae']).to eq('Empresa Teste LTDA')
      end
    end

    describe '#to_json_seguro' do
      it 'retorna string JSON válida' do
        json_string = remessa.to_json_seguro

        expect(json_string).to be_a(String)
        parsed = JSON.parse(json_string)
        expect(parsed['valid']).to be true
      end

      it 'funciona para remessa inválida' do
        json_string = remessa_invalida.to_json_seguro
        parsed = JSON.parse(json_string)

        expect(parsed['valid']).to be false
        expect(parsed['errors']).to be_an(Array)
      end
    end
  end

  # ============================================================
  # Testes do Factory Method Remessa.criar
  # ============================================================

  describe 'Brcobranca::Remessa.criar' do
    let(:params_sicoob) do
      remessa_params.merge(convenio: '123456789')
    end

    describe 'criação de remessa' do
      it 'cria remessa Sicoob CNAB400 por código' do
        remessa = Brcobranca::Remessa.criar(
          banco: '756',
          formato: :cnab400,
          **params_sicoob
        )

        expect(remessa).to be_a(Brcobranca::Remessa::Cnab400::Sicoob)
      end

      it 'cria remessa por nome do banco' do
        remessa = Brcobranca::Remessa.criar(
          banco: :sicoob,
          formato: :cnab400,
          **params_sicoob
        )

        expect(remessa).to be_a(Brcobranca::Remessa::Cnab400::Sicoob)
      end

      it 'cria remessa CNAB240' do
        remessa = Brcobranca::Remessa.criar(
          banco: :sicoob,
          formato: :cnab240,
          **params_sicoob
        )

        expect(remessa).to be_a(Brcobranca::Remessa::Cnab240::Sicoob)
      end

      it 'aceita string como formato' do
        remessa = Brcobranca::Remessa.criar(
          banco: '756',
          formato: 'cnab400',
          **params_sicoob
        )

        expect(remessa).to be_a(Brcobranca::Remessa::Cnab400::Sicoob)
      end
    end

    describe 'tratamento de erros' do
      it 'lança erro para banco não encontrado' do
        expect do
          Brcobranca::Remessa.criar(banco: 'inexistente', formato: :cnab400, **params_sicoob)
        end.to raise_error(ArgumentError, /não encontrado/)
      end

      it 'lança erro para formato não suportado' do
        expect do
          Brcobranca::Remessa.criar(banco: :sicoob, formato: :cnab999, **params_sicoob)
        end.to raise_error(ArgumentError, /não suportado/)
      end

      it 'lança erro para formato não disponível no banco' do
        expect do
          Brcobranca::Remessa.criar(banco: :caixa, formato: :cnab400, **params_sicoob)
        end.to raise_error(ArgumentError, /não suporta formato/)
      end
    end

    describe 'compatibilidade com múltiplos bancos' do
      it 'cria remessa Bradesco CNAB400' do
        params = {
          empresa_mae: 'Empresa Teste LTDA',
          agencia: '1234',
          conta_corrente: '1234567',
          digito_conta: '1',
          carteira: '09',
          documento_cedente: '12345678000190',
          codigo_empresa: '123456',
          pagamentos: [pagamento_valido]
        }
        remessa = Brcobranca::Remessa.criar(banco: :bradesco, formato: :cnab400, **params)

        expect(remessa).to be_a(Brcobranca::Remessa::Cnab400::Bradesco)
      end

      it 'cria remessa Itau CNAB400' do
        params = {
          empresa_mae: 'Empresa Teste LTDA',
          agencia: '1234',
          conta_corrente: '12345',
          digito_conta: '1',
          carteira: '109',
          documento_cedente: '12345678000190',
          pagamentos: [pagamento_valido]
        }
        remessa = Brcobranca::Remessa.criar(banco: :itau, formato: :cnab400, **params)

        expect(remessa).to be_a(Brcobranca::Remessa::Cnab400::Itau)
      end

      it 'cria remessa Banco Brasil CNAB240' do
        params = {
          empresa_mae: 'Empresa Teste LTDA',
          agencia: '12345',
          conta_corrente: '123456789012',
          digito_conta: '1',
          carteira: '17',
          variacao: '019',
          convenio: '1234567',
          documento_cedente: '12345678000190',
          pagamentos: [pagamento_valido]
        }
        remessa = Brcobranca::Remessa.criar(banco: :banco_brasil, formato: :cnab240, **params)

        expect(remessa).to be_a(Brcobranca::Remessa::Cnab240::BancoBrasil)
      end

      it 'cria remessa Caixa CNAB240' do
        params = {
          empresa_mae: 'Empresa Teste LTDA',
          agencia: '1234',
          digito_agencia: '1',
          conta_corrente: '123456789012',
          digito_conta: '1',
          carteira: '14',
          convenio: '123456',
          versao_aplicativo: '0000',
          documento_cedente: '12345678000190',
          pagamentos: [pagamento_valido]
        }
        remessa = Brcobranca::Remessa.criar(banco: :caixa, formato: :cnab240, **params)

        expect(remessa).to be_a(Brcobranca::Remessa::Cnab240::Caixa)
      end
    end
  end

  # ============================================================
  # Testes de métodos auxiliares
  # ============================================================

  describe 'Brcobranca::Remessa.bancos_disponiveis' do
    it 'retorna lista de bancos' do
      bancos = Brcobranca::Remessa.bancos_disponiveis

      expect(bancos).to be_an(Array)
      expect(bancos).to include('756', 'sicoob', 'bradesco', 'itau')
    end
  end

  describe 'Brcobranca::Remessa.suporta?' do
    it 'retorna true para combinação válida' do
      expect(Brcobranca::Remessa.suporta?(banco: :sicoob, formato: :cnab400)).to be true
      expect(Brcobranca::Remessa.suporta?(banco: '756', formato: :cnab240)).to be true
    end

    it 'retorna false para combinação inválida' do
      expect(Brcobranca::Remessa.suporta?(banco: :caixa, formato: :cnab400)).to be false
      expect(Brcobranca::Remessa.suporta?(banco: 'inexistente', formato: :cnab400)).to be false
    end
  end
end
