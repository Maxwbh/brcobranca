# frozen_string_literal: true

module Brcobranca
  # Registry of supported banks and their capabilities.
  #
  # Provides a single source of truth for which banks, CNAB formats,
  # boleto classes, remessa/retorno classes, and PIX support are
  # available in this version of brcobranca.
  #
  # @example List all banks
  #   Brcobranca::Bancos.todos
  #
  # @example Find a specific bank
  #   Brcobranca::Bancos.find("756")
  #   #=> { codigo: "756", nome: "Sicoob", ... }
  #
  # @example Banks with PIX support
  #   Brcobranca::Bancos.com_pix
  #
  # @example Summary for API responses
  #   Brcobranca::Bancos.as_json
  module Bancos
    REGISTRO = [
      {
        codigo: "001",
        nome: "Banco do Brasil",
        boleto: "BancoBrasil",
        cnab: {
          "240" => { remessa: "Cnab240::BancoBrasil", retorno: nil },
          "400" => { remessa: "Cnab400::BancoBrasil", retorno: "Cnab400::BancoBrasil" }
        },
        pix: { "240" => "Cnab240::BancoBrasilPix" },
        carteiras: %w[11 12 15 16 17 18 31 51]
      },
      {
        codigo: "004",
        nome: "Banco do Nordeste",
        boleto: "BancoNordeste",
        cnab: {
          "400" => { remessa: "Cnab400::BancoNordeste", retorno: "Cnab400::BancoNordeste" }
        },
        pix: {},
        carteiras: %w[21 41]
      },
      {
        codigo: "021",
        nome: "Banestes",
        boleto: "Banestes",
        cnab: {},
        pix: {},
        carteiras: %w[11]
      },
      {
        codigo: "033",
        nome: "Santander",
        boleto: "Santander",
        cnab: {
          "240" => { remessa: "Cnab240::Santander", retorno: "Cnab240::Santander" },
          "400" => { remessa: "Cnab400::Santander", retorno: "Cnab400::Santander" }
        },
        pix: { "400" => "Cnab400::SantanderPix" },
        carteiras: %w[101 102 201]
      },
      {
        codigo: "041",
        nome: "Banrisul",
        boleto: "Banrisul",
        cnab: {
          "400" => { remessa: "Cnab400::Banrisul", retorno: "Cnab400::Banrisul" }
        },
        pix: {},
        carteiras: %w[1 2]
      },
      {
        codigo: "070",
        nome: "Banco de Brasilia",
        boleto: "BancoBrasilia",
        cnab: {
          "400" => { remessa: "Cnab400::BancoBrasilia", retorno: "Cnab400::BancoBrasilia" }
        },
        pix: {},
        carteiras: %w[1 2]
      },
      {
        codigo: "085",
        nome: "AILOS",
        boleto: "Ailos",
        cnab: {
          "240" => { remessa: "Cnab240::Ailos", retorno: "Cnab240::Ailos" }
        },
        pix: {},
        carteiras: %w[1]
      },
      {
        codigo: "097",
        nome: "CREDISIS",
        boleto: "Credisis",
        cnab: {
          "400" => { remessa: "Cnab400::Credisis", retorno: "Cnab400::Credisis" }
        },
        pix: {},
        carteiras: %w[18]
      },
      {
        codigo: "104",
        nome: "Caixa Economica",
        boleto: "Caixa",
        cnab: {
          "240" => { remessa: "Cnab240::Caixa", retorno: "Cnab240::Caixa" }
        },
        pix: { "240" => "Cnab240::CaixaPix" },
        carteiras: %w[1 2]
      },
      {
        codigo: "136",
        nome: "Unicred",
        boleto: "Unicred",
        cnab: {
          "240" => { remessa: "Cnab240::Unicred", retorno: nil },
          "400" => { remessa: "Cnab400::Unicred", retorno: "Cnab400::Unicred" }
        },
        pix: {},
        carteiras: %w[21]
      },
      {
        codigo: "237",
        nome: "Bradesco",
        boleto: "Bradesco",
        cnab: {
          "400" => { remessa: "Cnab400::Bradesco", retorno: "Cnab400::Bradesco" }
        },
        pix: { "400" => "Cnab400::BradescoPix" },
        carteiras: %w[06 09 19 21 22]
      },
      {
        codigo: "336",
        nome: "C6 Bank",
        boleto: "BancoC6",
        cnab: {
          "400" => { remessa: "Cnab400::BancoC6", retorno: "Cnab400::BancoC6" }
        },
        pix: { "400" => "Cnab400::BancoC6Pix" },
        carteiras: %w[10 20]
      },
      {
        codigo: "341",
        nome: "Itau",
        boleto: "Itau",
        cnab: {
          "400" => { remessa: "Cnab400::Itau", retorno: "Cnab400::Itau" },
          "444" => { remessa: "Cnab444::Itau", retorno: nil }
        },
        pix: { "400" => "Cnab400::ItauPix" },
        carteiras: %w[104 108 109 112 115 121 147 150 175 176 196]
      },
      {
        codigo: "399",
        nome: "HSBC",
        boleto: "Hsbc",
        cnab: {},
        pix: {},
        carteiras: %w[CNR CSB]
      },
      {
        codigo: "422",
        nome: "Safra",
        boleto: "Safra",
        cnab: {},
        pix: {},
        carteiras: %w[1 2]
      },
      {
        codigo: "745",
        nome: "Citibank",
        boleto: "Citibank",
        cnab: {
          "400" => { remessa: "Cnab400::Citibank", retorno: nil }
        },
        pix: {},
        carteiras: %w[1 2 3]
      },
      {
        codigo: "748",
        nome: "Sicredi",
        boleto: "Sicredi",
        cnab: {
          "240" => { remessa: "Cnab240::Sicredi", retorno: "Cnab240::Sicredi" }
        },
        pix: {},
        carteiras: %w[1 3]
      },
      {
        codigo: "756",
        nome: "Sicoob",
        boleto: "Sicoob",
        cnab: {
          "240" => { remessa: "Cnab240::Sicoob", retorno: "Cnab240::Sicoob" },
          "400" => { remessa: "Cnab400::Sicoob", retorno: nil }
        },
        pix: { "240" => "Cnab240::SicoobPix" },
        carteiras: %w[1 3 9],
        extras: {
          carteira_9: "Usa numero_contrato no codigo de barras",
          layout_810: "Versao alternativa CNAB 240 (cliente calcula DV)"
        }
      }
    ].freeze

    class << self
      # All supported banks.
      # @return [Array<Hash>]
      def todos
        REGISTRO
      end

      # Find bank by code.
      # @param codigo [String] bank code (e.g. "756")
      # @return [Hash, nil]
      def find(codigo)
        REGISTRO.find { |b| b[:codigo] == codigo.to_s }
      end

      # Bank codes only.
      # @return [Array<String>]
      def codigos
        REGISTRO.map { |b| b[:codigo] }
      end

      # Banks that support boleto generation.
      # @return [Array<Hash>]
      def com_boleto
        REGISTRO.select { |b| b[:boleto] }
      end

      # Banks that have CNAB remessa support.
      # @param formato [String, nil] "240", "400", "444" or nil for any
      # @return [Array<Hash>]
      def com_remessa(formato = nil)
        REGISTRO.select do |b|
          if formato
            b[:cnab].key?(formato.to_s)
          else
            b[:cnab].any?
          end
        end
      end

      # Banks that have CNAB retorno support.
      # @param formato [String, nil] "240", "400" or nil for any
      # @return [Array<Hash>]
      def com_retorno(formato = nil)
        REGISTRO.select do |b|
          if formato
            b[:cnab].dig(formato.to_s, :retorno)
          else
            b[:cnab].any? { |_, v| v[:retorno] }
          end
        end
      end

      # Banks that support PIX in remessa files.
      # @return [Array<Hash>]
      def com_pix
        REGISTRO.select { |b| b[:pix].any? }
      end

      # CNAB formats supported across all banks.
      # @return [Array<String>]
      def formatos_cnab
        REGISTRO.flat_map { |b| b[:cnab].keys }.uniq.sort
      end

      # Full summary as a hash (for API responses).
      # @return [Hash]
      def as_json
        {
          total_bancos: REGISTRO.size,
          total_com_remessa: com_remessa.size,
          total_com_retorno: com_retorno.size,
          total_com_pix: com_pix.size,
          formatos_cnab: formatos_cnab,
          bancos: REGISTRO.map { |b| banco_as_json(b) }
        }
      end

      # JSON string.
      # @return [String]
      def to_json
        require "json"
        as_json.to_json
      end

      private

      def banco_as_json(banco)
        cnab_formatos = banco[:cnab].map do |fmt, cap|
          {
            formato: fmt,
            remessa: !cap[:remessa].nil?,
            retorno: !cap[:retorno].nil?
          }
        end

        pix_formatos = banco[:pix].map do |fmt, _klass|
          { formato: fmt }
        end

        {
          codigo: banco[:codigo],
          nome: banco[:nome],
          boleto: !banco[:boleto].nil?,
          cnab: cnab_formatos,
          pix: pix_formatos,
          carteiras: banco[:carteiras],
          extras: banco[:extras]
        }.compact
      end
    end
  end
end
