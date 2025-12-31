#!/usr/bin/env ruby
# frozen_string_literal: true

# Exemplo de uso da API de retorno de dados do boleto
# Execute: ruby examples/api_boleto_example.rb

require 'bundler/setup'
require 'brcobranca'
require 'json'

puts '=' * 60
puts 'BRCobranca - Exemplo de API de Retorno de Dados'
puts '=' * 60

# Criar um boleto Sicoob
boleto = Brcobranca::Boleto::Sicoob.new(
  data_documento: Date.today,
  data_vencimento: Date.today + 30,
  valor: 150.00,
  cedente: 'Empresa Exemplo LTDA',
  documento_cedente: '12.345.678/0001-90',
  sacado: 'Cliente Teste',
  sacado_documento: '123.456.789-00',
  sacado_endereco: 'Rua Exemplo, 123 - Centro - Cidade/UF',
  agencia: '4327',
  conta_corrente: '417270',
  convenio: '229385',
  nosso_numero: '123'
)

puts "\n1. DADOS DE ENTRADA (informados pelo usuário)"
puts '-' * 60
dados_entrada = boleto.dados_entrada
puts "Cedente: #{dados_entrada[:cedente]}"
puts "Sacado: #{dados_entrada[:sacado]}"
puts "Valor: R$ #{format('%.2f', dados_entrada[:valor])}"
puts "Vencimento: #{dados_entrada[:data_vencimento]}"
puts "Nosso Número: #{dados_entrada[:nosso_numero]}"

puts "\n2. DADOS CALCULADOS (gerados automaticamente)"
puts '-' * 60
dados_calculados = boleto.dados_calculados
puts "Banco: #{dados_calculados[:banco]} - #{dados_calculados[:banco_nome]}"
puts "Código de Barras: #{dados_calculados[:codigo_barras]}"
puts "Linha Digitável: #{dados_calculados[:linha_digitavel]}"
puts "Nosso Número Boleto: #{dados_calculados[:nosso_numero_boleto]}"
puts "Agência/Conta: #{dados_calculados[:agencia_conta_boleto]}"
puts "Fator Vencimento: #{dados_calculados[:fator_vencimento]}"
puts "Valor Documento: R$ #{format('%.2f', dados_calculados[:valor_documento])}"

puts "\n3. TO_HASH - Todos os dados"
puts '-' * 60
hash_completo = boleto.to_hash
puts "Chaves disponíveis: #{hash_completo.keys.count}"
puts hash_completo.keys.join(', ')

puts "\n4. TO_HASH (somente_calculados: true)"
puts '-' * 60
hash_calculados = boleto.to_hash(somente_calculados: true)
puts "Chaves disponíveis: #{hash_calculados.keys.count}"
puts hash_calculados.keys.join(', ')

puts "\n5. AS_JSON - Para APIs REST"
puts '-' * 60
json_hash = boleto.as_json(somente_calculados: true)
puts "Tipo das chaves: #{json_hash.keys.first.class}"
puts JSON.pretty_generate(json_hash)

puts "\n6. TO_JSON - String JSON"
puts '-' * 60
json_string = boleto.to_json(somente_calculados: true)
puts json_string[0..100] + '...'

puts "\n7. EXEMPLO COM PIX"
puts '-' * 60
boleto_pix = Brcobranca::Boleto::Sicoob.new(
  data_documento: Date.today,
  data_vencimento: Date.today + 30,
  valor: 150.00,
  cedente: 'Empresa Exemplo LTDA',
  documento_cedente: '12345678000190',
  sacado: 'Cliente Teste',
  sacado_documento: '12345678900',
  agencia: '4327',
  conta_corrente: '417270',
  convenio: '229385',
  nosso_numero: '123',
  emv: '00020126580014br.gov.bcb.pix0136123e4567-e89b-12d3-a456-426614174000'
)

pix_data = boleto_pix.dados_pix
if pix_data
  puts "PIX disponível: #{pix_data[:qrcode_disponivel]}"
  puts "EMV: #{pix_data[:emv][0..50]}..."
else
  puts 'PIX não configurado'
end

puts "\n8. USO EM RAILS CONTROLLER"
puts '-' * 60
puts <<~RUBY
  # app/controllers/boletos_controller.rb
  class BoletosController < ApplicationController
    def show
      @boleto = criar_boleto(params[:id])
      render json: @boleto.as_json(somente_calculados: true)
    end

    def dados_completos
      @boleto = criar_boleto(params[:id])
      render json: @boleto.to_hash
    end
  end
RUBY

puts "\n9. USO PARA CNAB"
puts '-' * 60
puts <<~RUBY
  # Obtendo dados para montar arquivo CNAB
  boleto = Brcobranca::Boleto::Sicoob.new(params)
  dados = boleto.to_hash(somente_calculados: true)

  # Usar os dados calculados no CNAB
  nosso_numero_formatado = dados[:nosso_numero_boleto]
  codigo_barras = dados[:codigo_barras]
  linha_digitavel = dados[:linha_digitavel]
RUBY

puts "\n" + '=' * 60
puts 'Exemplo concluído!'
puts '=' * 60
