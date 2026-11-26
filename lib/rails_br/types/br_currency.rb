# frozen_string_literal: true

require "active_model"
require "bigdecimal"
require_relative "../currency"

module RailsBr
  module Types
    # Tipo de atributo que lê valores em reais (`"R$ 1.234,56"`) como
    # `BigDecimal`. Texto inválido e `Float` viram `nil`; use o validador
    # `br_currency: true` para acusar o erro.
    #
    # @example
    #   attribute :price, :br_currency
    class BrCurrency < ActiveModel::Type::Value
      # @return [Symbol] `:decimal`, como o tipo decimal do Rails
      def type
        :decimal
      end

      # Converte o valor lido do banco de dados.
      #
      # @param value [Object, nil]
      # @return [BigDecimal, nil]
      def deserialize(value)
        BigDecimal(value.to_s) unless value.nil?
      end

      # Converte o valor a gravar ou a usar em consultas.
      #
      # @param value [Object, nil]
      # @return [BigDecimal, nil]
      def serialize(value)
        cast(value)
      end

      private

      def cast_value(value)
        case value
        when String then Currency.parse(value)
        when BigDecimal then value
        when Integer then BigDecimal(value)
        end
      end
    end
  end
end
