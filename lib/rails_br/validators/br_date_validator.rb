# frozen_string_literal: true

module ActiveModel
  module Validations
    # Valida uma data `dd/mm/aaaa`, em atributos `:br_date` ou de texto. Valores
    # em branco são ignorados; combine com `presence: true` para exigi-los.
    #
    # @example
    #   attribute :born_on, :br_date
    #   validates :born_on, br_date: true
    class BrDateValidator < RailsBr::TypedValueValidator
      private

      def error_key
        :invalid_br_date
      end

      def acceptable?(value)
        case value
        when String then !RailsBr::DateFormat.parse(value).nil?
        else value.is_a?(Date)
        end
      end
    end
  end
end
