# frozen_string_literal: true

require_relative "../error"

module RailsBr
  module Pix
    # Leitura de objetos TLV (ID, tamanho, valor) do padrão EMV QRCPS-MPM,
    # usado pelo BR Code. Cada objeto tem 2 dígitos de ID, 2 dígitos de tamanho
    # (em caracteres) e o valor.
    #
    # @example
    #   RailsBr::Pix::TLV.parse("000201010211")
    #   # => [["00", "01"], ["01", "11"]]
    module TLV
      # Tamanho do cabeçalho de cada objeto (2 dígitos de ID e 2 de tamanho).
      HEADER_LENGTH = 4
      # Dois dígitos, usado no ID e no tamanho.
      DIGITS = /\A\d{2}\z/.freeze

      # @param string [String]
      # @return [Array<Array(String, String)>] os pares `[id, valor]`, em ordem
      # @raise [InvalidValueError] se a sequência estiver truncada ou malformada
      def self.parse(string)
        pairs = []
        position = 0

        while position < string.length
          id, value = read_object(string, position)
          pairs << [id, value]
          position += HEADER_LENGTH + value.length
        end

        pairs
      end

      def self.read_object(string, position)
        id = string[position, 2]
        size = string[position + 2, 2]
        unless id.match?(DIGITS) && size.match?(DIGITS)
          raise InvalidValueError, "objeto TLV malformado na posição #{position}"
        end

        value = string[position + HEADER_LENGTH, size.to_i]
        raise InvalidValueError, "objeto #{id} truncado na posição #{position}" if value.length < size.to_i

        [id, value]
      end
      private_class_method :read_object
    end
  end
end
