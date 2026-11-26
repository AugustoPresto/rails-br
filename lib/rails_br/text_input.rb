# frozen_string_literal: true

module RailsBr
  # Checagem comum dos leitores de texto ({Currency} e {DateFormat}).
  #
  # @api private
  module TextInput
    # Só `String` em codificação compatível com ASCII e com bytes válidos pode
    # ser lida: aplicar uma expressão regular a outros valores levanta erro.
    #
    # @param value [Object]
    # @return [Boolean]
    def self.readable?(value)
      value.is_a?(String) && value.encoding.ascii_compatible? && value.valid_encoding?
    end
  end
end
