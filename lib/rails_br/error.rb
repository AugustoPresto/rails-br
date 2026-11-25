# frozen_string_literal: true

module RailsBr
  # Erro base de todas as exceções levantadas pela gem.
  class Error < StandardError; end

  # Levantado quando um valor tem formato ou dígito verificador inválido.
  class InvalidValueError < Error; end
end
