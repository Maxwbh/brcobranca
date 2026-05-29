# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'C6 Bank (336) — cenarios completos por carteira' do
  let(:valid_boleto_attrs) do
    {
      valor: 250.00,
      data_vencimento: Date.current + 30,
      data_documento: Date.current,
      cedente: 'Empresa Exemplo LTDA',
      documento_cedente: '12345678000100',
      sacado: 'Cliente Teste da Silva',
      sacado_documento: '12345678901',
      sacado_endereco: 'Rua das Flores, 123 - Centro - Sao Paulo/SP',
      agencia: '0001',
      conta_corrente: '0000528',
      convenio: '000000123456',
      nosso_numero: '0000000042'
    }
  end

  let(:pagamento_attrs) do
    {
      valor: 250.00,
      data_vencimento: Date.current + 30,
      nosso_numero: '0000000042',
      documento: '12345',
      documento_sacado: '12345678901',
      nome_sacado: 'CLIENTE TESTE DA SILVA',
      endereco_sacado: 'RUA DAS FLORES 123',
      bairro_sacado: 'CENTRO',
      cep_sacado: '01234567',
      cidade_sacado: 'SAO PAULO',
      uf_sacado: 'SP'
    }
  end

  let(:remessa_attrs) do
    {
      codigo_beneficiario: '000000123456',
      empresa_mae: 'EMPRESA EXEMPLO LTDA',
      documento_cedente: '12345678000100',
      sequencial_remessa: '1'
    }
  end

  describe 'Carteira 10 — Emissao Banco' do
    let(:boleto) { Brcobranca::Boleto::BancoC6.new(valid_boleto_attrs.merge(carteira: '10')) }

    context 'boleto' do
      it 'cria boleto valido' do
        expect(boleto).to be_valid
        expect(boleto.carteira).to eq('10')
        expect(boleto.banco).to eq('336')
      end

      it 'codigo de barras tem 44 posicoes' do
        expect(boleto.codigo_barras.size).to eq(44)
      end

      it 'indicador de layout e 3 (Emissao Banco)' do
        expect(boleto.indicador_layout).to eq('3')
        expect(boleto.codigo_barras_segunda_parte[-1]).to eq('3')
      end

      it 'campo livre: cedente(12) + nosso_numero(10) + carteira(2) + indicador(1)' do
        segunda_parte = boleto.codigo_barras_segunda_parte
        expect(segunda_parte.size).to eq(25)
        expect(segunda_parte[0, 12]).to eq('000000123456')
        expect(segunda_parte[12, 10]).to eq('0000000042')
        expect(segunda_parte[22, 2]).to eq('10')
        expect(segunda_parte[24]).to eq('3')
      end

      it 'nosso_numero_boleto inclui DV' do
        expect(boleto.nosso_numero_boleto).to match(/\A0000000042-\d\z/)
      end

      it 'agencia_conta_boleto no formato correto' do
        expect(boleto.agencia_conta_boleto).to eq('0001 / 000000123456')
      end

      it 'linha digitavel tem formato valido' do
        expect(boleto.linha_digitavel).to include('.')
        expect(boleto.linha_digitavel.gsub(/\D/, '').size).to eq(47)
      end

      it 'serializa para hash com dados corretos' do
        hash = boleto.to_hash
        expect(hash[:banco]).to eq('336')
        expect(hash[:carteira]).to eq('10')
        expect(hash[:valor]).to eq(250.00)
      end

      it 'serializa para JSON valido' do
        json = boleto.to_json
        parsed = JSON.parse(json)
        expect(parsed['banco']).to eq('336')
      end
    end

    context 'remessa CNAB 400' do
      let(:pagamento) { Brcobranca::Remessa::Pagamento.new(pagamento_attrs) }
      let(:remessa) do
        Brcobranca::Remessa::Cnab400::BancoC6.new(
          remessa_attrs.merge(carteira: '10', pagamentos: [pagamento])
        )
      end

      it 'gera remessa valida' do
        expect(remessa).to be_valid
      end

      it 'header tem 400 posicoes' do
        expect(remessa.monta_header.size).to eq(400)
      end

      it 'detalhe tem 400 posicoes' do
        expect(remessa.monta_detalhe(pagamento, 2).size).to eq(400)
      end

      it 'carteira 10: nosso numero em branco no detalhe' do
        detalhe = remessa.monta_detalhe(pagamento, 2)
        expect(detalhe[62..72].strip).to be_empty
        expect(detalhe[106..107]).to eq('10')
      end

      it 'arquivo completo: header + detalhe + trailer' do
        arquivo = remessa.gera_arquivo
        linhas = arquivo.split("\r\n").reject(&:empty?)
        expect(linhas.size).to eq(3)
        linhas.each { |l| expect(l.size).to eq(400) }
      end

      it 'multiplos pagamentos geram multiplas linhas' do
        remessa.pagamentos << Brcobranca::Remessa::Pagamento.new(pagamento_attrs)
        linhas = remessa.gera_arquivo.split("\r\n").reject(&:empty?)
        expect(linhas.size).to eq(4)
      end
    end
  end

  describe 'Carteira 20 — Emissao Cliente' do
    let(:boleto) { Brcobranca::Boleto::BancoC6.new(valid_boleto_attrs.merge(carteira: '20')) }

    context 'boleto' do
      it 'cria boleto valido' do
        expect(boleto).to be_valid
        expect(boleto.carteira).to eq('20')
      end

      it 'indicador de layout e 4 (Emissao Cliente)' do
        expect(boleto.indicador_layout).to eq('4')
        expect(boleto.codigo_barras_segunda_parte[-1]).to eq('4')
      end

      it 'campo livre usa carteira 20' do
        segunda_parte = boleto.codigo_barras_segunda_parte
        expect(segunda_parte[22, 2]).to eq('20')
      end

      it 'codigo de barras completo e valido' do
        codigo = boleto.codigo_barras
        expect(codigo.size).to eq(44)
        expect(codigo[0, 3]).to eq('336')
      end
    end

    context 'remessa CNAB 400' do
      let(:pagamento) { Brcobranca::Remessa::Pagamento.new(pagamento_attrs) }
      let(:remessa) do
        Brcobranca::Remessa::Cnab400::BancoC6.new(
          remessa_attrs.merge(carteira: '20', pagamentos: [pagamento])
        )
      end

      it 'gera remessa valida' do
        expect(remessa).to be_valid
      end

      it 'carteira 20: nosso numero preenchido no detalhe' do
        detalhe = remessa.monta_detalhe(pagamento, 2)
        expect(detalhe[62..72].strip).not_to be_empty
        expect(detalhe[73]).to match(/\d/)
        expect(detalhe[106..107]).to eq('20')
      end

      it 'arquivo completo valido' do
        arquivo = remessa.gera_arquivo
        linhas = arquivo.split("\r\n").reject(&:empty?)
        expect(linhas.size).to eq(3)
        linhas.each { |l| expect(l.size).to eq(400) }
      end
    end
  end

  describe 'Carteira invalida' do
    it 'rejeita carteira diferente de 10 e 20' do
      boleto = Brcobranca::Boleto::BancoC6.new(valid_boleto_attrs.merge(carteira: '30'))
      expect(boleto).not_to be_valid
    end

    it 'carteira vazia e invalida' do
      boleto = Brcobranca::Boleto::BancoC6.new(valid_boleto_attrs.merge(carteira: ''))
      expect(boleto).not_to be_valid
    end
  end

  describe 'Boleto com dados PIX' do
    let(:boleto) do
      Brcobranca::Boleto::BancoC6.new(
        valid_boleto_attrs.merge(
          carteira: '10',
          chave_pix: '12345678000100',
          tipo_chave_pix: 'cnpj',
          txid: 'TXID336C6BANK001'
        )
      )
    end

    it 'retorna dados_pix com campos preenchidos' do
      pix = boleto.dados_pix
      expect(pix[:chave_pix]).to eq('12345678000100')
      expect(pix[:tipo_chave_pix]).to eq('cnpj')
      expect(pix[:txid]).to eq('TXID336C6BANK001')
      expect(pix[:qrcode_disponivel]).to be false
    end

    it 'to_hash inclui campos PIX' do
      hash = boleto.to_hash
      expect(hash[:chave_pix]).to eq('12345678000100')
      expect(hash[:pix][:tipo_chave_pix]).to eq('cnpj')
    end

    it 'com EMV, qrcode_disponivel e true' do
      boleto.emv = '00020126580014br.gov.bcb.pix0136...'
      expect(boleto.dados_pix[:qrcode_disponivel]).to be true
    end
  end
end
