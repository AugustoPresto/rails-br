# frozen_string_literal: true

require "bigdecimal"
require_relative "error"

module RailsBr
  # Leitura e formatação de valores em reais (`R$ 1.234,56`).
  #
  # Dinheiro é sempre `BigDecimal`: `Float` nunca é aceito nem devolvido.
  #
  # @example
  #   RailsBr::Currency.parse("R$ 1.234,56")           # => BigDecimal("1234.56")
  #   RailsBr::Currency.parse("1234.56")               # => nil (formato americano)
  #   RailsBr::Currency.format(BigDecimal("1234.5"))   # => "R$ 1.234,50"
  module Currency
    # Símbolo do real.
    SYMBOL = "R$"

    # Texto aceito por {.parse}: `R$` e sinal negativo opcionais (antes ou depois
    # do símbolo), milhares agrupados com ponto ou sem agrupamento, e até 2
    # casas decimais após a vírgula. `[[:space:]]` inclui o espaço não separável.
    FORMAT = /
      \A[[:space:]]*
      (?<leading_sign>-)?[[:space:]]*
      (?:R\$[[:space:]]*)?
      (?<inner_sign>-)?[[:space:]]*
      (?<integer>[1-9]\d{0,2}(?:\.\d{3})+|\d+)
      (?:,(?<cents>\d{1,2}))?
      [[:space:]]*\z
    /x.freeze

    # Lê um valor escrito no padrão brasileiro.
    #
    # Não adivinha nem arredonda: o formato americano (`1234.56`), o milhar mal
    # agrupado (`1.23,4`), mais de 2 casas decimais e dois sinais são rejeitados.
    # Um ponto seguido de 3 dígitos é sempre separador de milhar (`1.234` é mil
    # duzentos e trinta e quatro).
    #
    # @param value [String] só `String` é lida; qualquer outro tipo (inclusive
    #   `Float`) resulta em `nil`
    # @return [BigDecimal, nil] o valor, ou `nil` se o texto for inválido
    def self.parse(value)
      match = FORMAT.match(value) if readable?(value)
      match && signed_amount(match)
    end

    # Como {.parse}, mas levanta {InvalidValueError} se o texto for inválido.
    #
    # @param value [String]
    # @return [BigDecimal]
    # @raise [InvalidValueError]
    def self.parse!(value)
      parse(value) || raise(InvalidValueError, "valor monetário inválido: #{value.inspect}")
    end

    # Formata um valor em reais. Não arredonda: arredonde antes, escolhendo a
    # regra adequada ao seu caso (por exemplo `value.round(2, :banker)`).
    #
    # @param value [BigDecimal, Integer] com no máximo 2 casas decimais
    # @param symbol [Boolean] se inclui o `R$`
    # @return [String] como `"R$ 1.234,56"` ou `"-R$ 1,00"`
    # @raise [InvalidValueError] para `Float` e outros tipos, valores não finitos
    #   ou com mais de 2 casas decimais
    def self.format(value, symbol: true)
      amount = to_amount(value)
      integer, cents = amount.abs.to_s("F").split(".")
      number = "#{group_thousands(integer)},#{cents.to_s.ljust(2, '0')}"
      number = "#{SYMBOL} #{number}" if symbol

      amount.negative? && !amount.zero? ? "-#{number}" : number
    end

    def self.readable?(value)
      value.is_a?(String) && value.encoding.ascii_compatible? && value.valid_encoding?
    end

    # Devolve `nil` quando há sinal antes e depois do símbolo.
    def self.signed_amount(match)
      signs = [match[:leading_sign], match[:inner_sign]].compact
      return if signs.length > 1

      amount = BigDecimal("#{match[:integer].delete('.')}.#{match[:cents] || 0}")
      signs.empty? || amount.zero? ? amount : -amount
    end

    def self.to_amount(value)
      unless value.is_a?(BigDecimal) || value.is_a?(Integer)
        raise InvalidValueError, "o valor deve ser BigDecimal ou Integer (nunca Float): #{value.inspect}"
      end

      amount = BigDecimal(value.to_s)
      return amount if amount.finite? && amount.round(2) == amount

      raise InvalidValueError, "o valor deve ser finito e ter no máximo 2 casas decimais: #{value.inspect}"
    end

    def self.group_thousands(integer)
      integer.reverse.scan(/\d{1,3}/).join(".").reverse
    end
    private_class_method :readable?, :signed_amount, :to_amount, :group_thousands
  end
end
