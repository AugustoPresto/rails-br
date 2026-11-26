# frozen_string_literal: true

module ActiveModel
  module Validations
    # Valida um valor em reais, em atributos `:br_currency` ou de texto. Valores
    # em branco são ignorados; combine com `presence: true` para exigi-los.
    #
    # O limite de casas decimais é 2, ou a `scale:` do atributo `:br_currency`.
    # Um valor lido do banco e não alterado não é acusado por ter mais casas:
    # ele não pode impedir a atualização do restante do registro.
    #
    # @example
    #   attribute :price, :br_currency
    #   validates :price, br_currency: true
    class BrCurrencyValidator < RailsBr::TypedValueValidator
      private

      def error_key
        :invalid_br_currency
      end

      def acceptable?(value, record, attribute)
        case value
        when String then !RailsBr::Currency.parse(value, scale: decimal_places(record, attribute)).nil?
        when Integer then true
        when BigDecimal then acceptable_decimal?(value, record, attribute)
        else false
        end
      end

      def acceptable_decimal?(value, record, attribute)
        return false unless value.finite?

        stored?(record, attribute) || value.round(decimal_places(record, attribute)) == value
      end

      def decimal_places(record, attribute)
        model = record.class
        type = model.attribute_types[attribute.to_s] if model.respond_to?(:attribute_types)
        type.respond_to?(:decimal_places) ? type.decimal_places : RailsBr::Currency::SCALE
      end

      # Só o ActiveRecord informa se o valor veio do banco (ou do padrão do
      # atributo) em vez de uma atribuição.
      def stored?(record, attribute)
        method = "#{attribute}_came_from_user?"
        record.respond_to?(method) && !record.public_send(method)
      end
    end
  end
end
