# frozen_string_literal: true

module ActiveModel
  module Validations
    # Valida um CNPJ, numérico ou alfanumérico. Valores em branco são
    # ignorados; combine com `presence: true` para torná-lo obrigatório.
    #
    # @example
    #   validates :cnpj, cnpj: true
    #   validates :cnpj, cnpj: { message: "inválido" }
    class CnpjValidator < EachValidator
      # @param record [ActiveModel::Validations] o objeto validado
      # @param attribute [Symbol] o atributo
      # @param value [Object] o valor do atributo
      # @return [void]
      def validate_each(record, attribute, value)
        return if value.blank?
        return if RailsBr::CNPJ.valid?(value)

        record.errors.add(attribute, :invalid_cnpj, **options, value: value)
      end
    end
  end
end
