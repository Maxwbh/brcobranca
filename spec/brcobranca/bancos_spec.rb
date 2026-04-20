# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Bancos do
  describe '.todos' do
    it 'retorna 18 bancos' do
      expect(described_class.todos.size).to eq(18)
    end

    it 'cada banco tem codigo, nome e boleto' do
      described_class.todos.each do |banco|
        expect(banco).to have_key(:codigo)
        expect(banco).to have_key(:nome)
        expect(banco).to have_key(:boleto)
      end
    end
  end

  describe '.find' do
    it 'encontra banco por codigo' do
      sicoob = described_class.find('756')
      expect(sicoob[:nome]).to eq('Sicoob')
      expect(sicoob[:carteiras]).to include('1', '9')
    end

    it 'encontra C6 Bank' do
      c6 = described_class.find('336')
      expect(c6[:nome]).to eq('C6 Bank')
      expect(c6[:carteiras]).to include('10', '20')
    end

    it 'retorna nil para banco inexistente' do
      expect(described_class.find('999')).to be_nil
    end
  end

  describe '.codigos' do
    it 'retorna array de codigos de banco' do
      codigos = described_class.codigos
      expect(codigos).to include('001', '237', '341', '756', '336')
      expect(codigos.size).to eq(18)
    end
  end

  describe '.com_remessa' do
    it 'retorna bancos com remessa em qualquer formato' do
      bancos = described_class.com_remessa
      expect(bancos.size).to be >= 14
    end

    it 'filtra por formato CNAB 240' do
      bancos = described_class.com_remessa('240')
      codigos = bancos.map { |b| b[:codigo] }
      expect(codigos).to include('001', '104', '756')
    end

    it 'filtra por formato CNAB 400' do
      bancos = described_class.com_remessa('400')
      codigos = bancos.map { |b| b[:codigo] }
      expect(codigos).to include('237', '341', '336')
    end
  end

  describe '.com_retorno' do
    it 'retorna bancos com retorno implementado' do
      bancos = described_class.com_retorno
      expect(bancos.size).to be >= 10
    end
  end

  describe '.com_pix' do
    it 'retorna 7 bancos com suporte PIX' do
      bancos = described_class.com_pix
      expect(bancos.size).to eq(7)
    end

    it 'inclui Santander, Bradesco, Itau, C6, BB, Caixa, Sicoob' do
      codigos = described_class.com_pix.map { |b| b[:codigo] }
      expect(codigos).to include('033', '237', '341', '336', '001', '104', '756')
    end
  end

  describe '.formatos_cnab' do
    it 'retorna formatos disponiveis' do
      expect(described_class.formatos_cnab).to include('240', '400')
    end

    it 'inclui formato 444 do Itau' do
      expect(described_class.formatos_cnab).to include('444')
    end
  end

  describe '.as_json' do
    let(:json) { described_class.as_json }

    it 'retorna hash com totais' do
      expect(json[:total_bancos]).to eq(18)
      expect(json[:total_com_pix]).to eq(7)
    end

    it 'cada banco no JSON tem campos esperados' do
      banco = json[:bancos].first
      expect(banco).to have_key(:codigo)
      expect(banco).to have_key(:nome)
      expect(banco).to have_key(:boleto)
      expect(banco).to have_key(:cnab)
      expect(banco).to have_key(:carteiras)
    end

    it 'cnab e array de formatos com remessa/retorno boolean' do
      bb = json[:bancos].find { |b| b[:codigo] == '001' }
      cnab400 = bb[:cnab].find { |c| c[:formato] == '400' }
      expect(cnab400[:remessa]).to be true
      expect(cnab400[:retorno]).to be true
    end

    it 'pix e array de formatos' do
      sicoob = json[:bancos].find { |b| b[:codigo] == '756' }
      expect(sicoob[:pix]).to eq([{ formato: '240' }])
    end

    it 'Sicoob tem extras (carteira 9, layout 810)' do
      sicoob = json[:bancos].find { |b| b[:codigo] == '756' }
      expect(sicoob[:extras]).to have_key(:carteira_9)
      expect(sicoob[:extras]).to have_key(:layout_810)
    end
  end

  describe '.to_json' do
    it 'retorna string JSON valida' do
      json_str = described_class.to_json
      parsed = JSON.parse(json_str)
      expect(parsed['total_bancos']).to eq(18)
    end
  end
end
