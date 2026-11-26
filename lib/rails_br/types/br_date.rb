# frozen_string_literal: true

require "active_model"
require "date"
require_relative "../date_format"

module RailsBr
  module Types
    # Tipo de atributo que lê datas `dd/mm/aaaa` como `Date`. Texto inválido e
    # `Time` viram `nil`; use o validador `br_date: true` para acusar o erro.
    #
    # O texto digitado é sempre lido no padrão brasileiro, inclusive em
    # consultas. Valores vindos do banco de dados são lidos no formato do banco.
    #
    # @example
    #   attribute :born_on, :br_date
    class BrDate < ActiveModel::Type::Value
      # @return [Symbol] `:date`, como o tipo de data do Rails
      def type
        :date
      end

      # Converte o valor lido do banco de dados.
      #
      # @param value [Object, nil]
      # @return [Date, nil]
      def deserialize(value)
        ActiveModel::Type::Date.new.deserialize(value)
      end

      # Converte o valor a gravar ou a usar em consultas.
      #
      # @param value [Object, nil]
      # @return [Date, nil]
      def serialize(value)
        cast(value)
      end

      private

      def cast_value(value)
        case value
        when String then DateFormat.parse(value)
        when DateTime then value.to_date
        when Date then value
        end
      end
    end
  end
end
