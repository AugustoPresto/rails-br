# frozen_string_literal: true

# Extensões do ActiveModel fornecidas pela gem rails-br.
module ActiveModel
  # Validadores: `cpf`, `cnpj` e `pix_key`.
  module Validations
    # Valida um CPF. Valores em branco são ignorados; combine com
    # `presence: true` para torná-lo obrigatório.
    #
    # @example
    #   validates :cpf, cpf: true
    #   validates :cpf, cpf: { message: "inválido" }
    #   validates :cpf, cpf: true, allow_nil: true
    class CpfValidator < EachValidator
      # @param record [ActiveModel::Validations] o objeto validado
      # @param attribute [Symbol] o atributo
      # @param value [Object] o valor do atributo
      # @return [void]
      def validate_each(record, attribute, value)
        return if value.blank?
        return if RailsBr::CPF.valid?(value)

        record.errors.add(attribute, :invalid_cpf, **options, value: value)
      end
    end
  end
end
