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
    # São aceitas 2 casas decimais; para colunas mais precisas, informe `scale:`.
    #
    # @example
    #   attribute :price, :br_currency
    #   attribute :unit_price, :br_currency, scale: 4
    class BrCurrency < ActiveModel::Type::Value
      # @return [Symbol] `:decimal`, como o tipo decimal do Rails
      def type
        :decimal
      end

      # @return [Integer] máximo de casas decimais aceitas na entrada
      def decimal_places
        scale || Currency::SCALE
      end

      # Texto de um campo de formulário. Só valores já convertidos são
      # formatados, com todas as casas (nada é arredondado); texto digitado e
      # outros objetos voltam como estão.
      #
      # @param value [Object, nil]
      # @return [Object] como `"1.234,56"`
      def format_input(value)
        return value unless value.is_a?(Integer) || (value.is_a?(BigDecimal) && value.finite?)

        # O comprimento do número por extenso é um limite folgado para as casas.
        Currency.format(value, symbol: false, scale: BigDecimal(value.to_s).to_s("F").length)
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
        when String then Currency.parse(value, scale: decimal_places)
        when BigDecimal then value
        when Integer then BigDecimal(value)
        end
      end
    end
  end
end
