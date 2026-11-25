# frozen_string_literal: true

require_relative "error"

module RailsBr
  # Base dos documentos brasileiros ({CPF}, {CNPJ}): value objects imutáveis
  # com entrada tolerante a máscara.
  #
  # As subclasses definem a constante `SEPARATORS` (caracteres de máscara a
  # remover) e implementam `#valid?`.
  #
  # @abstract
  class Document
    # @param value [#to_s, nil]
    # @return [Boolean]
    def self.valid?(value)
      new(value).valid?
    end

    # Como {.new}, mas levanta {InvalidValueError} se o documento for inválido.
    #
    # @param value [#to_s, nil]
    # @return [Document]
    # @raise [InvalidValueError]
    def self.parse!(value)
      document = new(value)
      raise InvalidValueError, invalid_message(value) unless document.valid?

      document
    end

    # Mensagem do erro levantado por {.parse!}. As subclasses podem sobrescrever.
    #
    # @param value [#to_s, nil]
    # @return [String]
    def self.invalid_message(value)
      "#{name.split('::').last} inválido: #{value.inspect}"
    end

    # @return [String] o valor sem máscara (e, no CNPJ, em maiúsculas)
    attr_reader :value

    # @param value [#to_s, nil]
    def initialize(value)
      @value = normalize(value.to_s).freeze
      freeze
    end

    # @return [String]
    def to_s
      value
    end

    def ==(other)
      other.is_a?(self.class) && value == other.value
    end
    alias eql? ==

    def hash
      [self.class, value].hash
    end

    private

    def normalize(string)
      string.gsub(self.class::SEPARATORS, "")
    end
  end
end
