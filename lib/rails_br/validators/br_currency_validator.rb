# frozen_string_literal: true

module ActiveModel
  module Validations
    # Valida um valor em reais, em atributos `:br_currency` ou de texto. Valores
    # em branco são ignorados; combine com `presence: true` para exigi-los.
    #
    # @example
    #   attribute :price, :br_currency
    #   validates :price, br_currency: true
    class BrCurrencyValidator < RailsBr::TypedValueValidator
      private

      def error_key
        :invalid_br_currency
      end

      def acceptable?(value)
        case value
        when String then !RailsBr::Currency.parse(value).nil?
        when Integer then true
        when BigDecimal then value.finite? && value.round(2) == value
        else false
        end
      end
    end
  end
end
