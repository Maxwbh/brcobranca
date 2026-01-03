# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'Brcobranca::Retorno API' do
  # ============================================================
  # Fase 4: Testes da API de Serialização para Retorno (v12.5.0)
  # ============================================================

  describe Brcobranca::Retorno::Base do
    let(:registro) do
      registro = Brcobranca::Retorno::Base.new
      registro.nosso_numero = '12345678'
      registro.documento_numero = 'DOC123'
      registro.valor_titulo = '10000'
      registro.data_vencimento = '311225'
      registro.carteira = '09'
      registro.valor_recebido = '10050'
      registro.data_credito = '021226'
      registro.data_ocorrencia = '311225'
      registro.juros_mora = '50'
      registro.codigo_ocorrencia = '06'
      registro.motivo_ocorrencia = ['00']
      registro.sequencial = '000001'
      registro.agencia_com_dv = '12345'
      registro.cedente_com_dv = '123456'
      registro.banco_recebedor = '756'
      registro
    end

    describe '#to_hash' do
      it 'retorna um Hash com todos os atributos' do
        resultado = registro.to_hash

        expect(resultado).to be_a(Hash)
        expect(resultado[:nosso_numero]).to eq('12345678')
        expect(resultado[:valor_titulo]).to eq('10000')
        expect(resultado[:data_vencimento]).to eq('311225')
      end

      it 'remove valores nil por padrão (compact: true)' do
        resultado = registro.to_hash

        expect(resultado.values).not_to include(nil)
      end

      it 'inclui valores nil quando compact: false' do
        resultado = registro.to_hash(compact: false)

        expect(resultado.keys).to include(:tipo_cobranca) # campo nil
        expect(resultado[:tipo_cobranca]).to be_nil
      end
    end

    describe '#as_json' do
      it 'retorna Hash com chaves string' do
        resultado = registro.as_json

        expect(resultado).to be_a(Hash)
        expect(resultado.keys.first).to be_a(String)
        expect(resultado['nosso_numero']).to eq('12345678')
      end
    end

    describe '#to_json' do
      it 'retorna string JSON válida' do
        json_string = registro.to_json

        expect(json_string).to be_a(String)
        expect { JSON.parse(json_string) }.not_to raise_error
      end

      it 'contém os dados do registro' do
        parsed = JSON.parse(registro.to_json)

        expect(parsed['nosso_numero']).to eq('12345678')
        expect(parsed['valor_recebido']).to eq('10050')
      end
    end

    describe '#dados_titulo' do
      it 'retorna dados principais do título' do
        resultado = registro.dados_titulo

        expect(resultado[:nosso_numero]).to eq('12345678')
        expect(resultado[:documento_numero]).to eq('DOC123')
        expect(resultado[:valor_titulo]).to eq('10000')
        expect(resultado[:data_vencimento]).to eq('311225')
        expect(resultado[:carteira]).to eq('09')
      end

      it 'não inclui campos nil' do
        expect(registro.dados_titulo.values).not_to include(nil)
      end
    end

    describe '#dados_recebimento' do
      it 'retorna dados de recebimento' do
        resultado = registro.dados_recebimento

        expect(resultado[:valor_recebido]).to eq('10050')
        expect(resultado[:data_credito]).to eq('021226')
        expect(resultado[:juros_mora]).to eq('50')
      end
    end

    describe '#dados_ocorrencia' do
      it 'retorna dados da ocorrência' do
        resultado = registro.dados_ocorrencia

        expect(resultado[:codigo_ocorrencia]).to eq('06')
        expect(resultado[:motivo_ocorrencia]).to eq(['00'])
        expect(resultado[:sequencial]).to eq('000001')
      end
    end

    describe '#dados_bancarios' do
      it 'retorna dados bancários' do
        resultado = registro.dados_bancarios

        expect(resultado[:agencia_com_dv]).to eq('12345')
        expect(resultado[:cedente_com_dv]).to eq('123456')
        expect(resultado[:banco_recebedor]).to eq('756')
      end
    end

    describe '#dados_pix' do
      it 'retorna nil quando não há dados PIX' do
        expect(registro.dados_pix).to be_nil
      end

      it 'retorna dados PIX quando disponíveis' do
        registro.tipo_chave_dict = 'CPF'
        registro.codigo_chave_dict = '12345678901'
        registro.txid = 'TXN123456'

        resultado = registro.dados_pix

        expect(resultado[:tipo_chave_dict]).to eq('CPF')
        expect(resultado[:codigo_chave_dict]).to eq('12345678901')
        expect(resultado[:txid]).to eq('TXN123456')
      end
    end
  end

  # ============================================================
  # Testes do Factory Method Retorno.parse
  # ============================================================

  describe 'Brcobranca::Retorno.detectar_formato' do
    let(:linha_cnab400) { 'A' * 400 }
    let(:linha_cnab240) { 'B' * 240 }
    let(:linha_cbr643) { 'C' * 643 }

    it 'detecta formato CNAB400' do
      Tempfile.create(['retorno', '.ret']) do |f|
        f.write(linha_cnab400 + "\n")
        f.rewind
        expect(Brcobranca::Retorno.detectar_formato(f.path)).to eq(:cnab400)
      end
    end

    it 'detecta formato CNAB240' do
      Tempfile.create(['retorno', '.ret']) do |f|
        f.write(linha_cnab240 + "\n")
        f.rewind
        expect(Brcobranca::Retorno.detectar_formato(f.path)).to eq(:cnab240)
      end
    end

    it 'detecta formato CBR643' do
      Tempfile.create(['retorno', '.ret']) do |f|
        f.write(linha_cbr643 + "\n")
        f.rewind
        expect(Brcobranca::Retorno.detectar_formato(f.path)).to eq(:cbr643)
      end
    end

    it 'levanta erro para formato não reconhecido' do
      Tempfile.create(['retorno', '.ret']) do |f|
        f.write('X' * 100 + "\n")
        f.rewind
        expect do
          Brcobranca::Retorno.detectar_formato(f.path)
        end.to raise_error(ArgumentError, /Formato não reconhecido/)
      end
    end
  end

  describe 'Brcobranca::Retorno.detectar_banco' do
    it 'detecta banco em CNAB400' do
      # Criar linha CNAB400 com código do banco na posição 77-79 (índice 76-78)
      linha = ' ' * 76 + '237' + ' ' * 321 # Total: 400 caracteres
      Tempfile.create(['retorno', '.ret']) do |f|
        f.write(linha + "\n")
        f.rewind
        expect(Brcobranca::Retorno.detectar_banco(f.path, :cnab400)).to eq('237')
      end
    end

    it 'detecta banco em CNAB240' do
      # Criar linha CNAB240 com código do banco na posição 1-3 (índice 0-2)
      linha = '756' + ' ' * 237 # Total: 240 caracteres
      Tempfile.create(['retorno', '.ret']) do |f|
        f.write(linha + "\n")
        f.rewind
        expect(Brcobranca::Retorno.detectar_banco(f.path, :cnab240)).to eq('756')
      end
    end

    it 'retorna 001 para CBR643 (Banco do Brasil)' do
      linha = 'C' * 643
      Tempfile.create(['retorno', '.ret']) do |f|
        f.write(linha + "\n")
        f.rewind
        expect(Brcobranca::Retorno.detectar_banco(f.path, :cbr643)).to eq('001')
      end
    end
  end

  describe 'Brcobranca::Retorno.formato_valido?' do
    it 'retorna true para arquivo CNAB400 válido' do
      Tempfile.create(['retorno', '.ret']) do |f|
        f.write('A' * 400 + "\n")
        f.rewind
        expect(Brcobranca::Retorno.formato_valido?(f.path)).to be true
      end
    end

    it 'retorna false para formato inválido' do
      Tempfile.create(['retorno', '.ret']) do |f|
        f.write('X' * 100 + "\n")
        f.rewind
        expect(Brcobranca::Retorno.formato_valido?(f.path)).to be false
      end
    end
  end

  describe 'Brcobranca::Retorno::FORMATOS' do
    it 'inclui todos os formatos suportados' do
      expect(Brcobranca::Retorno::FORMATOS).to include(:cnab240, :cnab400, :cbr643)
    end
  end
end
