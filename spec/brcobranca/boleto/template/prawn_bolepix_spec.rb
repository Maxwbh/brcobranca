# frozen_string_literal: true

require 'spec_helper'

begin
  require 'brcobranca/boleto/template/prawn_bolepix'
  PRAWN_TEMPLATE_LOADED = true
rescue LoadError
  PRAWN_TEMPLATE_LOADED = false
end

if PRAWN_TEMPLATE_LOADED && Brcobranca::Boleto::Template::PRAWN_AVAILABLE
  RSpec.describe Brcobranca::Boleto::Template::PrawnBolepix do
    let(:valid_attributes) do
      {
        data_documento: Date.parse('2025-04-28'),
        data_vencimento: Date.parse('2025-05-10'),
        data_processamento: Date.parse('2025-05-07'),
        valor: 100.0,
        cedente: 'Empresa Exemplo Ltda',
        documento_cedente: '11222333000181',
        cedente_endereco: 'Rua Exemplo, 100 - Centro - Cidade - UF - 00000-000',
        sacado: 'Cliente Exemplo',
        sacado_documento: '00000000191',
        sacado_endereco: 'Rua Teste, 200 - UF - 00000-000',
        agencia: '4092',
        conta_corrente: '834467',
        convenio: '834467',
        nosso_numero: '374875',
        carteira: '1',
        instrucoes: "Instrucao 1\nInstrucao 2",
        local_pagamento: 'Pague em qualquer banco ou correspondente.'
      }
    end

    let(:boleto) do
      b = Brcobranca::Boleto::Sicoob.new(valid_attributes)
      b.extend(Brcobranca::Boleto::Template::PrawnBolepix)
      b
    end

    describe '#to(:pdf)' do
      it 'gera um PDF valido' do
        pdf_bytes = boleto.to(:pdf)
        expect(pdf_bytes).to be_a(String)
        expect(pdf_bytes).to start_with('%PDF-')
      end

      it 'gera PDF valido terminando com %%EOF' do
        pdf_bytes = boleto.to(:pdf)
        expect(pdf_bytes).to include("%%EOF")
        expect(pdf_bytes.bytesize).to be > 1024
      end
    end

    describe '#to_pdf' do
      it 'funciona como alias de to(:pdf)' do
        expect(boleto.to_pdf).to start_with('%PDF-')
      end
    end

    describe 'com QR Code PIX' do
      let(:emv_valido) do
        '00020126580014br.gov.bcb.pix0136' \
        '123e4567-e12b-12d1-a456-4266554400005204000053039865802BR' \
        '5913EMPRESA TESTE6009SAO PAULO62070503***63049D3E'
      end

      it 'gera PDF maior quando boleto.emv esta presente' do
        pdf_sem_pix = boleto.to(:pdf)

        boleto.emv = emv_valido
        pdf_com_pix = boleto.to(:pdf)

        expect(pdf_com_pix.bytesize).to be > pdf_sem_pix.bytesize
      end

      it 'nao gera QR Code quando emv e invalido (nao comeca com 0002)' do
        boleto.emv = 'string_invalida'
        pdf_emv_invalido = boleto.to(:pdf)

        boleto.emv = nil
        pdf_sem_emv = boleto.to(:pdf)

        expect(pdf_emv_invalido.bytesize).to eq(pdf_sem_emv.bytesize)
      end
    end

    describe '#lote' do
      it 'gera PDF com multiplos boletos' do
        b1 = Brcobranca::Boleto::Sicoob.new(valid_attributes)
        b2 = Brcobranca::Boleto::Sicoob.new(valid_attributes.merge(nosso_numero: '374876'))
        b1.extend(Brcobranca::Boleto::Template::PrawnBolepix)
        b2.extend(Brcobranca::Boleto::Template::PrawnBolepix)

        pdf_bytes = b1.lote([b1, b2])
        expect(pdf_bytes).to start_with('%PDF-')
      end
    end

    describe 'formatos nao suportados' do
      it 'rejeita formatos diferentes de :pdf' do
        expect { boleto.to(:jpg) }.to raise_error(ArgumentError, /apenas :pdf/)
      end
    end

    describe 'validacao do EMV' do
      it 'ignora QR Code quando emv nao comeca com 0002' do
        boleto.emv = 'string_invalida'
        expect { boleto.to(:pdf) }.not_to raise_error
      end
    end

    describe 'compatibilidade' do
      it 'funciona com todos os bancos que nao tem banco_nome' do
        b = Brcobranca::Boleto::Bradesco.new(
          agencia: '0548', conta_corrente: '0001448', carteira: '06',
          nosso_numero: '00000004042', valor: 100.0,
          data_vencimento: Date.today + 30, cedente: 'Teste',
          documento_cedente: '12345678000100', sacado: 'Sacado',
          sacado_documento: '12345678900'
        )
        b.extend(Brcobranca::Boleto::Template::PrawnBolepix)
        expect { b.to(:pdf) }.not_to raise_error
      end
    end
  end
else
  RSpec.describe 'PrawnBolepix (gems nao instaladas)' do
    it 'marca como pending quando prawn/rqrcode/barby/chunky_png nao estao disponiveis' do
      pending 'Instale: gem install prawn prawn-table barby rqrcode chunky_png'
      expect(PRAWN_TEMPLATE_LOADED).to be true
    end
  end
end
