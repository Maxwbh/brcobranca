# frozen_string_literal: true

# @author Eduardo Reboucas
require 'brcobranca/util/errors'

module Brcobranca
  # Métodos auxiliares de validação para evitar ActiveSupport e ActiveModel com
  # mínimo de impacto nas definições das validações existentes

  module Validations
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_reader :presences, :lengths, :numericals, :inclusions, :eachs, :with_formats

      def validates_presence_of(*attr_names)
        @presences ||= []
        @presences = @presences << attr_names
      end

      def validates_length_of(*attr_names)
        @lengths ||= []
        @lengths = @lengths << attr_names
      end

      def validates_numericality_of(*attr_names)
        @numericals ||= []
        @numericals = @numericals << attr_names
      end

      def validates_inclusion_of(*attr_names)
        @inclusions ||= []
        @inclusions = @inclusions << attr_names
      end

      def validates_format_of(*attr_names)
        @with_formats ||= []
        @with_formats = @with_formats << attr_names
      end

      def validates_each(*attr_names, &block)
        @eachs ||= {}
        attr_names.each do |attr_name|
          @eachs[attr_name] = block
        end
      end

      # Permite aplicar opções comuns a múltiplas validações
      # Similar ao with_options do ActiveModel
      #
      # @param options [Hash] opções a serem aplicadas (ex: if:, unless:)
      # @yield [OptionsProxy] proxy que aplica as opções às validações
      #
      # @example
      #   with_options if: :usa_seu_numero? do |v|
      #     v.validates_length_of :seu_numero, maximum: 7, message: 'erro'
      #   end
      def with_options(options)
        yield OptionsProxy.new(self, options)
      end
    end

    # Proxy para aplicar opções comuns às validações
    class OptionsProxy
      def initialize(target, options)
        @target = target
        @options = options
      end

      def validates_presence_of(*attr_names)
        merged = merge_options(attr_names)
        @target.validates_presence_of(*merged)
      end

      def validates_length_of(*attr_names)
        merged = merge_options(attr_names)
        @target.validates_length_of(*merged)
      end

      def validates_numericality_of(*attr_names)
        merged = merge_options(attr_names)
        @target.validates_numericality_of(*merged)
      end

      def validates_inclusion_of(*attr_names)
        merged = merge_options(attr_names)
        @target.validates_inclusion_of(*merged)
      end

      def validates_format_of(*attr_names)
        merged = merge_options(attr_names)
        @target.validates_format_of(*merged)
      end

      private

      def merge_options(attr_names)
        if attr_names.last.is_a?(Hash)
          options = attr_names.pop
          attr_names << @options.merge(options)
        else
          attr_names << @options.dup
        end
        attr_names
      end
    end

    def errors
      @errors ||= Brcobranca::Util::Errors.new(self)
    end

    def valid?
      # puts "** #{self.class}"
      # puts "** #{self.class.superclass}"
      all_valid = true
      all_valid = false unless check_eachs
      all_valid = false unless check_presences
      all_valid = false unless check_numericals
      all_valid = false unless check_lengths
      all_valid = false unless check_inclusions
      all_valid = false unless check_with_formats
      all_valid
    end

    def invalid?
      !valid?
    end

    private

    # Coleta validações de um tipo específico da hierarquia de classes
    def collect_validations(type, default = [])
      result = default.dup
      [self.class.superclass.superclass, self.class.superclass, self.class].each do |klass|
        next unless klass.respond_to?(type) && (value = klass.send(type))
        result.is_a?(Hash) ? result.merge!(value) : result += value
      end
      result
    end

    def check_eachs
      eachs = collect_validations(:eachs, {})
      return true if eachs.empty?

      eachs.each do |attr_name, block|
        value = ''
        begin
          value = send(attr_name)
        rescue StandardError
        end
        block.call(self, attr_name, value)
      end
      errors.size.zero?
    end

    def check_presences
      presences = collect_validations(:presences)
      return true if presences.empty?

      all_present = true
      presences.each do |presence|
        presence.select { |p| p.is_a? Symbol }.each do |variable|
          next unless valid_condition?(presence[-1])

          if blank?(send(variable))
            all_present = false
            errors.add variable, presence[-1][:message]
          end
        end
      end
      all_present
    end

    def check_numericals
      numericals = collect_validations(:numericals)
      return true if numericals.empty?

      all_numerical = true
      numericals.each do |numerical|
        numerical.select { |p| p.is_a? Symbol }.each do |variable|
          next unless valid_condition?(numerical[-1])

          if respond_to?(variable) && send(variable) && (send(variable).to_s =~ /\A[+-]?\d+\z/).nil?
            all_numerical = false
            errors.add variable, numerical[-1][:message]
          end
        end
      end
      all_numerical
    end

    def check_lengths
      lengths = collect_validations(:lengths)
      return true if lengths.empty?

      all_checked = true
      lengths.each do |rule|
        variable = rule[0]
        next unless respond_to?(variable)
        next unless valid_condition?(rule[-1])

        value = send(variable)
        if rule[-1][:in]
          if !value
            all_checked = false
            errors.add variable, rule[-1][:message]
          elsif value.size < rule[-1][:in].first || value.size > rule[-1][:in].last
            all_checked = false
            errors.add variable, rule[-1][:message]
          end
        end
        if rule[-1][:is]
          if !value
            all_checked = false
            errors.add variable, rule[-1][:message]
          elsif value.to_s.size != rule[-1][:is]
            all_checked = false
            errors.add variable, rule[-1][:message]
          end
        end
        if rule[-1][:minimum] && rule[-1][:maximum]
          if !value || value.size < rule[-1][:minimum] || value.size > rule[-1][:maximum]
            all_checked = false
            errors.add variable, rule[-1][:message]
          end
        elsif rule[-1][:maximum]
          if value && value.size > rule[-1][:maximum]
            all_checked = false
            errors.add variable, rule[-1][:message]
          end
        end
      end
      all_checked
    end

    def check_inclusions
      inclusions = collect_validations(:inclusions)
      return true if inclusions.empty?

      all_checked = true
      inclusions.each do |rule|
        variable = rule[0]
        next unless respond_to?(variable)

        value = send(variable)
        next unless value

        next unless rule[-1][:in]
        next unless valid_condition?(rule[-1])

        unless rule[-1][:in].include?(value)
          all_checked = false
          errors.add variable, rule[-1][:message]
        end
      end
      all_checked
    end

    def check_with_formats
      with_formats = collect_validations(:with_formats)
      return true if with_formats.empty?

      all_checked = true
      with_formats.each do |rule|
        variable = rule[0]
        next unless respond_to?(variable)

        value = send(variable)
        next unless value

        next unless rule[-1][:with]
        next unless valid_condition?(rule[-1])

        unless value&.match?(rule[-1][:with])
          all_checked = false
          errors.add variable, rule[-1][:message]
        end
      end
      all_checked
    end

    def variable_name(symbol)
      symbol.to_s.tr('_', ' ').capitalize
    end

    def blank?(obj)
      return obj !~ /\S/ if obj.is_a? String

      obj.respond_to?(:empty?) ? obj.empty? : !obj
    end

    def valid_condition?(rule)
      return true unless rule[:if]

      if rule[:if].is_a?(Symbol)
        send(rule[:if])
      elsif rule[:if].is_a?(Proc)
        rule[:if].call(self)
      else
        raise ArgumentError, 'Condition must be a symbol or a proc'
      end
    end
  end
end
