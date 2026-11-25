# frozen_string_literal: true

require_relative "document"

module RailsBr
  # Value object imutável para o CPF (Cadastro de Pessoas Físicas).
  #
  # A entrada é tolerante: aceita máscara (`111.444.777-35`), espaços nas
  # pontas e valores `nil`. Apenas `.`, `-` e espaços são removidos; qualquer
  # outro caractere torna o CPF inválido.
  #
  # @example
  #   cpf = RailsBr::CPF.new("111.444.777-35")
  #   cpf.valid?     # => true
  #   cpf.digits     # => "11144477735"
  #   cpf.formatted  # => "111.444.777-35"
  #   RailsBr::CPF.valid?("111.111.111-11") # => false
  class CPF < Document
    # Tamanho do CPF sem máscara.
    LENGTH = 11
    # Caracteres de máscara removidos na entrada.
    SEPARATORS = /[.\-\s]/.freeze
    # Formato aceito depois de remover a máscara: exatamente 11 dígitos.
    DIGITS_ONLY = /\A\d{#{LENGTH}}\z/.freeze

    # @return [String] os dígitos, sem máscara
    alias digits value

    # Um CPF é válido quando tem 11 dígitos, não é uma sequência repetida
    # (como 111.111.111-11) e os dois dígitos verificadores conferem.
    #
    # @return [Boolean]
    def valid?
      return false unless digits.match?(DIGITS_ONLY)
      return false if digits.squeeze.length == 1

      digits[9, 2] == check_digits
    end

    # @return [String, nil] `"111.444.777-35"`, ou `nil` se o CPF for inválido
    def formatted
      return unless valid?

      "#{digits[0, 3]}.#{digits[3, 3]}.#{digits[6, 3]}-#{digits[9, 2]}"
    end

    private

    # Módulo 11: pesos decrescentes a partir de 10 (1º dígito) e 11 (2º dígito).
    def check_digits
      first = check_digit(digits[0, 9], 10)
      second = check_digit("#{digits[0, 9]}#{first}", 11)
      "#{first}#{second}"
    end

    def check_digit(base, initial_weight)
      sum = base.each_char.with_index.sum { |char, i| char.to_i * (initial_weight - i) }
      remainder = sum % 11
      remainder < 2 ? 0 : 11 - remainder
    end
  end
end
