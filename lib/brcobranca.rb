# frozen_string_literal: true

require 'brcobranca/util/calculo'
require 'brcobranca/util/limpeza'
require 'brcobranca/util/formatacao'
require 'brcobranca/util/formatacao_string'
require 'brcobranca/util/calculo_data'
require 'brcobranca/util/currency'
require 'brcobranca/util/validations'
require 'brcobranca/util/date'
require 'fast_blank'

module Brcobranca
  # Exception lançada quando algum tipo de boleto soicitado ainda não tiver sido implementado.
  class NaoImplementado < RuntimeError
  end

  class ValorInvalido < StandardError
  end

  # Exception lançada quando os dados informados para o boleto estão inválidos.
  #
  # Você pode usar assim na sua aplicação:
  #   rescue Brcobranca::BoletoInvalido => invalido
  #   puts invalido.errors
  class BoletoInvalido < StandardError
    # Atribui o objeto boleto e pega seus erros de validação
    def initialize(boleto)
      errors = boleto.errors.full_messages.join(', ')
      super(errors)
    end
  end

  # Exception lançada quando os dados informados para o arquivo remessa estão inválidos.
  #
  # Você pode usar assim na sua aplicação:
  #   rescue Brcobranca::RemessaInvalida => invalido
  #   puts invalido.errors
  class RemessaInvalida < StandardError
    # Atribui o objeto boleto e pega seus erros de validação
    def initialize(remessa)
      errors = remessa.errors.full_messages.join(', ')
      super(errors)
    end
  end

  # Configurações do Brcobranca.
  #
  # Para mudar as configurações padrão, você pode fazer assim:
  # config/environments/test.rb:
  #
  #     Brcobranca.setup do |config|
  #       config.formato = :gif
  #     end
  #
  # Ou colocar em um arquivo na pasta initializer do rails.
  class Configuration
    # Gerador de arquivo de boleto.
    # @return [Symbol]
    # @param  [Symbol] (Padrão: :rghost)
    attr_accessor :gerador
    # Formato do arquivo de boleto a ser gerado.
    # @return [Symbol]
    # @param  [Symbol] (Padrão: :pdf)
    # @see http://wiki.github.com/shairontoledo/rghost/supported-devices-drivers-and-formats Veja mais formatos na documentação do rghost.
    attr_accessor :formato

    # Resolução em pixels do arquivo gerado.
    # @return [Integer]
    # @param  [Integer] (Padrão: 150)
    attr_accessor :resolucao

    # Ajusta o encoding do texto do boleto enviado para o GhostScript
    # O valor 'ascii-8bit' evita problemas com acentos e cedilha
    # @return [String]
    # @param  [String] (Padrão: nil)
    attr_accessor :external_encoding

    # Label exibido ao lado do QR Code PIX no boleto híbrido (Bolepix).
    # Pode ser sobrescrito por boleto via `boleto.pix_label`.
    # @return [String]
    # @param  [String] (Padrão: "Pague com PIX")
    attr_accessor :pix_label

    # Atribui valores padrões de configuração
    def initialize
      self.gerador = :rghost
      self.formato = :pdf
      self.resolucao = 150
      self.external_encoding = 'ascii-8bit'
      self.pix_label = 'Pague com PIX'
    end
  end

  # Atribui os valores customizados para as configurações.
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Bloco para realizar configurações customizadas.
  def self.setup
    yield(configuration)
  end

  # Módulo para classes de boletos
  module Boleto
    autoload :Base,          'brcobranca/boleto/base'
    autoload :BancoNordeste, 'brcobranca/boleto/banco_nordeste'
    autoload :BancoBrasil,   'brcobranca/boleto/banco_brasil'
    autoload :BancoBrasilia, 'brcobranca/boleto/banco_brasilia'
    autoload :Itau,          'brcobranca/boleto/itau'
    autoload :Hsbc,          'brcobranca/boleto/hsbc'
    autoload :Bradesco,      'brcobranca/boleto/bradesco'
    autoload :Caixa,         'brcobranca/boleto/caixa'
    autoload :Sicoob,        'brcobranca/boleto/sicoob'
    autoload :Sicredi,       'brcobranca/boleto/sicredi'
    autoload :Unicred,       'brcobranca/boleto/unicred'
    autoload :Santander,     'brcobranca/boleto/santander'
    autoload :Banestes,      'brcobranca/boleto/banestes'
    autoload :Banrisul,      'brcobranca/boleto/banrisul'
    autoload :Credisis,      'brcobranca/boleto/credisis'
    autoload :Safra,         'brcobranca/boleto/safra'
    autoload :Citibank,      'brcobranca/boleto/citibank'
    autoload :Ailos,         'brcobranca/boleto/ailos'
    autoload :BancoC6,       'brcobranca/boleto/banco_c6'

    # Módulos para classes de template
    module Template
      autoload :Base,        'brcobranca/boleto/template/base'
      autoload :Rghost,      'brcobranca/boleto/template/rghost'
      autoload :Rghost2,     'brcobranca/boleto/template/rghost2'
      autoload :RghostCarne, 'brcobranca/boleto/template/rghost_carne'
      autoload :RghostBolepix, 'brcobranca/boleto/template/rghost_bolepix'
      autoload :PrawnBolepix, 'brcobranca/boleto/template/prawn_bolepix'
    end
  end

  # Módulos para classes de retorno bancário
  module Retorno
    autoload :Base,            'brcobranca/retorno/base'
    autoload :RetornoCbr643,   'brcobranca/retorno/retorno_cbr643'
    autoload :RetornoCnab240,  'brcobranca/retorno/retorno_cnab240'
    autoload :RetornoCnab400,  'brcobranca/retorno/retorno_cnab400' # DEPRECATED

    # Lista de formatos suportados
    FORMATOS = %i[cnab240 cnab400 cbr643].freeze

    # Factory method para processar arquivos de retorno
    #
    # @param arquivo [String, File, IO] arquivo de retorno (path ou objeto)
    # @param options [Hash] opções
    # @option options [Symbol] :formato formato do arquivo (:cnab240, :cnab400, :cbr643), auto-detecta se não informado
    # @option options [String] :banco código do banco (auto-detectado se não informado)
    #
    # @return [Hash] dados do retorno processado
    #
    # @example Processamento com auto-detecção
    #   resultado = Brcobranca::Retorno.parse('retorno.ret')
    #   #=> { formato: :cnab400, banco: '237', total_registros: 10, registros: [...] }
    #
    # @example Com formato explícito
    #   resultado = Brcobranca::Retorno.parse('retorno.ret', formato: :cnab400)
    def self.parse(arquivo, options = {})
      formato = options[:formato]&.to_sym || detectar_formato(arquivo)

      registros = case formato
                  when :cnab240
                    Cnab240::Base.load_lines(arquivo, options)
                  when :cnab400
                    Cnab400::Base.load_lines(arquivo, options)
                  when :cbr643
                    RetornoCbr643.load_lines(arquivo, options)
                  else
                    raise ArgumentError, "Formato '#{formato}' não suportado. Use: #{FORMATOS.join(', ')}"
                  end

      registros ||= []

      {
        formato: formato,
        banco: detectar_banco(arquivo, formato),
        total_registros: registros.size,
        registros: registros.map(&:to_hash)
      }
    end

    # Processa arquivo e retorna registros como objetos (não serializado)
    #
    # @param arquivo [String, File, IO] arquivo de retorno
    # @param options [Hash] opções
    # @return [Array<Base>] array de registros
    def self.load_lines(arquivo, options = {})
      formato = options[:formato]&.to_sym || detectar_formato(arquivo)

      case formato
      when :cnab240
        Cnab240::Base.load_lines(arquivo, options)
      when :cnab400
        Cnab400::Base.load_lines(arquivo, options)
      when :cbr643
        RetornoCbr643.load_lines(arquivo, options)
      else
        raise ArgumentError, "Formato '#{formato}' não suportado"
      end
    end

    # Detecta formato do arquivo automaticamente
    #
    # @param arquivo [String, File, IO] arquivo de retorno
    # @return [Symbol] formato detectado (:cnab240, :cnab400, :cbr643)
    # @raise [ArgumentError] se formato não reconhecido
    def self.detectar_formato(arquivo)
      primeira_linha = ler_primeira_linha(arquivo)
      return nil if primeira_linha.nil?

      tamanho = primeira_linha.chomp.size

      case tamanho
      when 240
        :cnab240
      when 400
        :cnab400
      when 643, 644, 645
        :cbr643
      else
        raise ArgumentError, "Formato não reconhecido. Tamanho da linha: #{tamanho}. Esperado: 240, 400 ou 643"
      end
    end

    # Detecta o banco do arquivo
    #
    # @param arquivo [String, File, IO] arquivo de retorno
    # @param formato [Symbol] formato do arquivo
    # @return [String, nil] código do banco
    def self.detectar_banco(arquivo, formato = nil)
      primeira_linha = ler_primeira_linha(arquivo)
      return nil if primeira_linha.nil?

      formato ||= detectar_formato(arquivo)

      case formato
      when :cnab240
        primeira_linha[0..2] # Posições 1-3 no CNAB240
      when :cnab400
        primeira_linha[76..78] # Posições 77-79 no CNAB400
      when :cbr643
        '001' # CBR643 é específico do Banco do Brasil
      end
    end

    # Verifica se arquivo é de formato suportado
    #
    # @param arquivo [String, File, IO] arquivo de retorno
    # @return [Boolean]
    def self.formato_valido?(arquivo)
      detectar_formato(arquivo)
      true
    rescue ArgumentError
      false
    end

    # Lê primeira linha do arquivo
    #
    # @param arquivo [String, File, IO] arquivo
    # @return [String, nil]
    def self.ler_primeira_linha(arquivo)
      case arquivo
      when String
        return nil unless File.exist?(arquivo)

        File.open(arquivo, 'r', &:gets)
      when File, IO
        arquivo.rewind if arquivo.respond_to?(:rewind)
        linha = arquivo.gets
        arquivo.rewind if arquivo.respond_to?(:rewind)
        linha
      else
        raise ArgumentError, 'Arquivo deve ser path (String), File ou IO'
      end
    end

    private_class_method :ler_primeira_linha

    module Cnab400
      autoload :Base,          'brcobranca/retorno/cnab400/base'
      autoload :Bradesco,      'brcobranca/retorno/cnab400/bradesco'
      autoload :Banrisul,      'brcobranca/retorno/cnab400/banrisul'
      autoload :Itau,          'brcobranca/retorno/cnab400/itau'
      autoload :BancoNordeste, 'brcobranca/retorno/cnab400/banco_nordeste'
      autoload :BancoBrasilia, 'brcobranca/retorno/cnab400/banco_brasilia'
      autoload :Unicred,       'brcobranca/retorno/cnab400/unicred'
      autoload :Credisis,      'brcobranca/retorno/cnab400/credisis'
      autoload :Santander,     'brcobranca/retorno/cnab400/santander'
      autoload :BancoBrasil,   'brcobranca/retorno/cnab400/banco_brasil'
      autoload :BancoC6,       'brcobranca/retorno/cnab400/banco_c6'
    end

    module Cnab240
      autoload :Base,          'brcobranca/retorno/cnab240/base'
      autoload :Santander,     'brcobranca/retorno/cnab240/santander'
      autoload :Sicredi,       'brcobranca/retorno/cnab240/sicredi'
      autoload :Sicoob,        'brcobranca/retorno/cnab240/sicoob'
      autoload :Caixa,         'brcobranca/retorno/cnab240/caixa'
      autoload :Ailos,         'brcobranca/retorno/cnab240/ailos'
    end
  end

  # Módulos para as classes que geram os arquivos remessa
  module Remessa
    autoload :Base,            'brcobranca/remessa/base'
    autoload :Pagamento,       'brcobranca/remessa/pagamento'
    autoload :PagamentoPix,    'brcobranca/remessa/pagamento_pix'

    # Mapeamento de bancos para classes de remessa
    BANCOS = {
      '001' => { cnab240: 'BancoBrasil', cnab400: 'BancoBrasil' },
      'banco_brasil' => { cnab240: 'BancoBrasil', cnab400: 'BancoBrasil' },
      '033' => { cnab240: 'Santander', cnab400: 'Santander' },
      'santander' => { cnab240: 'Santander', cnab400: 'Santander' },
      '041' => { cnab400: 'Banrisul' },
      'banrisul' => { cnab400: 'Banrisul' },
      '104' => { cnab240: 'Caixa' },
      'caixa' => { cnab240: 'Caixa' },
      '237' => { cnab400: 'Bradesco' },
      'bradesco' => { cnab400: 'Bradesco' },
      '341' => { cnab240: nil, cnab400: 'Itau', cnab444: 'Itau' },
      'itau' => { cnab400: 'Itau', cnab444: 'Itau' },
      '399' => { cnab400: 'Citibank' },
      'citibank' => { cnab400: 'Citibank' },
      '748' => { cnab240: 'Sicredi' },
      'sicredi' => { cnab240: 'Sicredi' },
      '756' => { cnab240: 'Sicoob', cnab400: 'Sicoob' },
      'sicoob' => { cnab240: 'Sicoob', cnab400: 'Sicoob' },
      '085' => { cnab240: 'Ailos' },
      'ailos' => { cnab240: 'Ailos' },
      '136' => { cnab240: 'Unicred', cnab400: 'Unicred' },
      'unicred' => { cnab240: 'Unicred', cnab400: 'Unicred' },
      '004' => { cnab400: 'BancoNordeste' },
      'banco_nordeste' => { cnab400: 'BancoNordeste' },
      '070' => { cnab400: 'BancoBrasilia' },
      'banco_brasilia' => { cnab400: 'BancoBrasilia' },
      '097' => { cnab400: 'Credisis' },
      'credisis' => { cnab400: 'Credisis' },
      '336' => { cnab400: 'BancoC6' },
      'banco_c6' => { cnab400: 'BancoC6' },
      'c6' => { cnab400: 'BancoC6' }
    }.freeze

    # Lista de formatos suportados
    FORMATOS = %i[cnab240 cnab400 cnab444].freeze

    # Factory method para criar remessas
    #
    # @param banco [String, Symbol] código ou nome do banco (ex: '756', :sicoob)
    # @param formato [Symbol] formato do arquivo (:cnab240, :cnab400, :cnab444)
    # @param params [Hash] parâmetros para a remessa
    #
    # @return [Remessa::Base] instância da remessa apropriada
    #
    # @raise [ArgumentError] se banco ou formato não suportado
    #
    # @example
    #   Brcobranca::Remessa.criar(
    #     banco: '756',
    #     formato: :cnab400,
    #     empresa_mae: 'Empresa LTDA',
    #     agencia: '1234',
    #     conta_corrente: '12345',
    #     pagamentos: [pagamento1, pagamento2]
    #   )
    #
    # @example Com símbolo
    #   Brcobranca::Remessa.criar(banco: :sicoob, formato: :cnab240, **params)
    def self.criar(banco:, formato:, **params)
      banco_key = banco.to_s.downcase
      formato_sym = formato.to_sym

      unless FORMATOS.include?(formato_sym)
        raise ArgumentError, "Formato '#{formato}' não suportado. Use: #{FORMATOS.join(', ')}"
      end

      banco_config = BANCOS[banco_key]
      raise ArgumentError, "Banco '#{banco}' não encontrado" unless banco_config

      classe_nome = banco_config[formato_sym]
      unless classe_nome
        formatos_disponiveis = banco_config.keys.join(', ')
        raise ArgumentError, "Banco '#{banco}' não suporta formato '#{formato}'. Formatos disponíveis: #{formatos_disponiveis}"
      end

      modulo = case formato_sym
               when :cnab240 then Cnab240
               when :cnab400 then Cnab400
               when :cnab444 then Cnab444
               end

      classe = modulo.const_get(classe_nome)
      classe.new(params)
    end

    # Lista bancos disponíveis
    #
    # @return [Array<String>] lista de códigos e nomes de bancos
    def self.bancos_disponiveis
      BANCOS.keys.uniq.sort
    end

    # Verifica se banco suporta formato
    #
    # @param banco [String, Symbol] código ou nome do banco
    # @param formato [Symbol] formato do arquivo
    # @return [Boolean]
    def self.suporta?(banco:, formato:)
      banco_config = BANCOS[banco.to_s.downcase]
      return false unless banco_config

      !banco_config[formato.to_sym].nil?
    end

    module Cnab400
      autoload :Base,          'brcobranca/remessa/cnab400/base'
      autoload :PixMixin,      'brcobranca/remessa/cnab400/pix_mixin'
      autoload :BancoBrasil,   'brcobranca/remessa/cnab400/banco_brasil'
      autoload :Banrisul,      'brcobranca/remessa/cnab400/banrisul'
      autoload :Bradesco,      'brcobranca/remessa/cnab400/bradesco'
      autoload :BradescoPix,   'brcobranca/remessa/cnab400/bradesco_pix'
      autoload :Itau,          'brcobranca/remessa/cnab400/itau'
      autoload :ItauPix,       'brcobranca/remessa/cnab400/itau_pix'
      autoload :Citibank,      'brcobranca/remessa/cnab400/citibank'
      autoload :Santander,     'brcobranca/remessa/cnab400/santander'
      autoload :SantanderPix,  'brcobranca/remessa/cnab400/santander_pix'
      autoload :Sicoob,        'brcobranca/remessa/cnab400/sicoob'
      autoload :BancoNordeste, 'brcobranca/remessa/cnab400/banco_nordeste'
      autoload :BancoBrasilia, 'brcobranca/remessa/cnab400/banco_brasilia'
      autoload :Unicred,       'brcobranca/remessa/cnab400/unicred'
      autoload :Credisis,      'brcobranca/remessa/cnab400/credisis'
      autoload :BancoC6,       'brcobranca/remessa/cnab400/banco_c6'
      autoload :BancoC6Pix,    'brcobranca/remessa/cnab400/banco_c6_pix'
    end

    module Cnab444
      autoload :Itau,          'brcobranca/remessa/cnab444/itau'
    end

    module Cnab240
      autoload :Base,               'brcobranca/remessa/cnab240/base'
      autoload :BaseCorrespondente, 'brcobranca/remessa/cnab240/base_correspondente'
      autoload :PixMixin,           'brcobranca/remessa/cnab240/pix_mixin'
      autoload :Caixa,              'brcobranca/remessa/cnab240/caixa'
      autoload :CaixaPix,           'brcobranca/remessa/cnab240/caixa_pix'
      autoload :BancoBrasil,        'brcobranca/remessa/cnab240/banco_brasil'
      autoload :BancoBrasilPix,     'brcobranca/remessa/cnab240/banco_brasil_pix'
      autoload :Santander,          'brcobranca/remessa/cnab240/santander'
      autoload :Sicoob,             'brcobranca/remessa/cnab240/sicoob'
      autoload :SicoobPix,          'brcobranca/remessa/cnab240/sicoob_pix'
      autoload :SicoobBancoBrasil,  'brcobranca/remessa/cnab240/sicoob_banco_brasil'
      autoload :Sicredi,            'brcobranca/remessa/cnab240/sicredi'
      autoload :Unicred,            'brcobranca/remessa/cnab240/unicred'
      autoload :Ailos,              'brcobranca/remessa/cnab240/ailos'
    end
  end

  # Módulos para classes de utilidades
  module Util
    autoload :Empresa, 'brcobranca/util/empresa'
    autoload :Errors, 'brcobranca/util/errors'
    autoload :FormatacaoCampos, 'brcobranca/util/formatacao_campos'
  end

  # Registry de bancos suportados e suas capacidades
  autoload :Bancos, 'brcobranca/bancos'
end
