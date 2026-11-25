# frozen_string_literal: true

require_relative "document"

module RailsBr
  # Value object imutável para o CNPJ, no formato numérico tradicional e no
  # alfanumérico adotado pela Receita Federal.
  #
  # No formato alfanumérico, as 12 primeiras posições (raiz, ordem) aceitam
  # dígitos e letras maiúsculas; os 2 últimos caracteres (dígitos
  # verificadores) são sempre numéricos.
  #
  # A entrada é tolerante: aceita máscara (`12.ABC.345/01DE-35`), espaços nas
  # pontas, letras minúsculas (convertidas para maiúsculas) e `nil`. Apenas
  # `.`, `-`, `/` e espaços são removidos.
  #
  # O dígito verificador usa módulo 11 com pesos de 2 a 9 (cíclicos, da direita
  # para a esquerda) sobre o valor ASCII de cada caractere menos 48, conforme
  # a Receita Federal (Nota Técnica Conjunta 2025.001 e FAQ do CNPJ
  # alfanumérico). Nos CNPJs numéricos isso equivale ao cálculo tradicional.
  #
  # @example
  #   cnpj = RailsBr::CNPJ.new("12.ABC.345/01DE-35")
  #   cnpj.valid?         # => true
  #   cnpj.alphanumeric?  # => true
  #   cnpj.formatted      # => "12.ABC.345/01DE-35"
  #   RailsBr::CNPJ.valid?("11.222.333/0001-81") # => true
  class CNPJ < Document
    LENGTH = 14
    BASE_LENGTH = 12
    SEPARATORS = %r{[./\-\s]}.freeze
    # 12 posições alfanuméricas + 2 dígitos verificadores numéricos.
    FORMAT = /\A[0-9A-Z]{#{BASE_LENGTH}}\d{2}\z/.freeze
    ASCII_OFFSET = 48
    WEIGHTS = (2..9).to_a.freeze

    # @return [Boolean] se há letras na raiz ou na ordem (formato alfanumérico)
    def alphanumeric?
      value[0, BASE_LENGTH].match?(/[A-Z]/)
    end

    # @return [Boolean]
    def valid?
      return false unless value.match?(FORMAT)
      return false if value.squeeze.length == 1

      value[BASE_LENGTH, 2] == check_digits
    end

    # @return [String, nil] `"12.ABC.345/01DE-35"`, ou `nil` se for inválido
    def formatted
      return unless valid?

      "#{value[0, 2]}.#{value[2, 3]}.#{value[5, 3]}/#{value[8, 4]}-#{value[12, 2]}"
    end

    private

    # Maiúsculas apenas ASCII, para não transformar letras como "ß" em "SS".
    def normalize(string)
      super.upcase(:ascii)
    end

    def check_digits
      first = check_digit(value[0, BASE_LENGTH])
      second = check_digit("#{value[0, BASE_LENGTH]}#{first}")
      "#{first}#{second}"
    end

    def check_digit(base)
      sum = base.reverse.each_char.with_index.sum do |char, i|
        (char.ord - ASCII_OFFSET) * WEIGHTS[i % WEIGHTS.length]
      end
      remainder = sum % 11
      remainder < 2 ? 0 : 11 - remainder
    end
  end
end
