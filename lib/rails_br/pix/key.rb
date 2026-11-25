# frozen_string_literal: true

require_relative "../document"
require_relative "../cpf"
require_relative "../cnpj"

module RailsBr
  module Pix
    # Chave Pix: detecta o tipo e valida o formato.
    #
    # As regras seguem os manuais do Banco Central: Manual Operacional do DICT
    # (v8.5, seção 1), especificação da API do DICT (v2.13.0, tabela de chaves)
    # e Manual de Padrões para Iniciação do Pix (v2.10.0, seção 2.5.1).
    #
    # A validação é **estrita**, como o DICT: a chave não é normalizada. CPF e
    # CNPJ vão sem máscara; o e-mail e a chave aleatória, em minúsculas; o
    # telefone no formato internacional E.164 (`+5561912345678`). Espaços nas
    # pontas tornam a chave inválida.
    #
    # | Tipo     | Formato                                                  |
    # |----------|----------------------------------------------------------|
    # | `:cpf`   | 11 dígitos, com dígitos verificadores corretos           |
    # | `:cnpj`  | 14 caracteres (numérico ou alfanumérico), DV correto     |
    # | `:phone` | `+` e 2 a 15 dígitos, o primeiro de 1 a 9 (E.164)        |
    # | `:email` | até 77 caracteres, minúsculo, regex da API do DICT       |
    # | `:evp`   | UUID com hífens, em minúsculas (chave aleatória)         |
    #
    # O `+55` não é exigido pela especificação, que adota E.164 de forma geral.
    #
    # @example
    #   key = RailsBr::Pix::Key.new("+5561912345678")
    #   key.valid?  # => true
    #   key.type    # => :phone
    #   RailsBr::Pix::Key.new("111.444.777-35").valid? # => false (use só dígitos)
    class Key < Document
      TYPES = %i[cpf cnpj phone email evp].freeze
      MAX_LENGTH = 77

      CPF_FORMAT = /\A\d{11}\z/.freeze
      CNPJ_FORMAT = /\A[0-9A-Z]{12}\d{2}\z/.freeze
      PHONE_FORMAT = /\A\+[1-9]\d{1,14}\z/.freeze
      EVP_FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/.freeze
      # Expressão regular da API do DICT para e-mail (somente minúsculas).
      EMAIL_FORMAT = %r{
        \A[a-z0-9.!\#$'*+/=?^_`{|}~-]+
        @[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?
        (?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)*\z
      }x.freeze

      # @param value [#to_s, nil]
      # @return [Symbol, nil] o tipo da chave, ou `nil` se for inválida
      def self.type_of(value)
        new(value).type
      end

      def self.invalid_message(value)
        "Chave Pix inválida: #{value.inspect}"
      end

      # @return [Symbol, nil] um de {TYPES}, ou `nil` se a chave for inválida
      def type
        return if value.empty? || value.length > MAX_LENGTH

        TYPES.find { |candidate| send(:"#{candidate}?") }
      end

      # @return [Boolean]
      def valid?
        !type.nil?
      end

      private

      # A chave é validada exatamente como recebida.
      def normalize(string)
        string
      end

      def cpf?
        value.match?(CPF_FORMAT) && CPF.valid?(value)
      end

      def cnpj?
        value.match?(CNPJ_FORMAT) && CNPJ.valid?(value)
      end

      def phone?
        value.match?(PHONE_FORMAT)
      end

      def email?
        value.match?(EMAIL_FORMAT)
      end

      def evp?
        value.match?(EVP_FORMAT)
      end
    end
  end
end
