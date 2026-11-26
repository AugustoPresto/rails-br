# frozen_string_literal: true

require "date"
require_relative "error"
require_relative "text_input"

module RailsBr
  # Leitura e formatação de datas no padrão brasileiro, `dd/mm/aaaa`.
  #
  # @example
  #   RailsBr::DateFormat.parse("31/12/2026")            # => #<Date 2026-12-31>
  #   RailsBr::DateFormat.parse("31/02/2026")            # => nil (data inexistente)
  #   RailsBr::DateFormat.format(Date.new(2026, 1, 5))   # => "05/01/2026"
  module DateFormat
    # Texto aceito por {.parse}: dia e mês com 1 ou 2 dígitos, ano com 4,
    # separados por `/`. Espaços nas pontas são ignorados.
    FORMAT = %r{\A[[:space:]]*(?<day>\d{1,2})/(?<month>\d{1,2})/(?<year>\d{4})[[:space:]]*\z}.freeze
    # Máscara usada por {.format}.
    OUTPUT = "%d/%m/%Y"
    # Anos que podem ser escritos com 4 dígitos.
    YEARS = (1..9999).freeze

    # Lê uma data `dd/mm/aaaa`. A leitura é estrita: ano com 2 dígitos (o século
    # é ambíguo), outros separadores, hora e texto sobrando são rejeitados, assim
    # como datas que não existem no calendário.
    #
    # @param value [String] só `String` é lida; qualquer outro tipo resulta em `nil`
    # @return [Date, nil] a data, ou `nil` se o texto for inválido
    def self.parse(value)
      match = FORMAT.match(value) if TextInput.readable?(value)
      match && build_date(match)
    end

    # Como {.parse}, mas levanta {InvalidValueError} se o texto for inválido.
    #
    # @param value [String]
    # @return [Date]
    # @raise [InvalidValueError]
    def self.parse!(value)
      parse(value) || raise(InvalidValueError, "data inválida: #{value.inspect}")
    end

    # Formata uma data como `dd/mm/aaaa`.
    #
    # @param value [Date] um `Date` (ou `DateTime`, do qual só a data é usada).
    #   `Time` não é aceito: converta com `to_date`, escolhendo o fuso antes
    # @return [String]
    # @raise [InvalidValueError] para outros tipos ou anos fora de {YEARS}
    def self.format(value)
      unless value.is_a?(Date) && YEARS.cover?(value.year)
        raise InvalidValueError, "o valor deve ser um Date com ano entre 1 e 9999: #{value.inspect}"
      end

      value.strftime(OUTPUT)
    end

    def self.build_date(match)
      year, month, day = match.values_at(:year, :month, :day).map(&:to_i)
      return unless YEARS.cover?(year) && Date.valid_date?(year, month, day)

      Date.new(year, month, day)
    end
    private_class_method :build_date
  end
end
