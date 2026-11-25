# frozen_string_literal: true

module ActiveModel
  module Validations
    # Valida uma chave Pix (CPF, CNPJ, telefone, e-mail ou chave aleatória).
    # A validação é estrita: veja {RailsBr::Pix::Key}. Valores em branco são
    # ignorados; combine com `presence: true` para torná-la obrigatória.
    #
    # @example
    #   validates :pix_key, pix_key: true
    class PixKeyValidator < EachValidator
      def validate_each(record, attribute, value)
        return if value.blank?
        return if RailsBr::Pix::Key.valid?(value)

        record.errors.add(attribute, :invalid_pix_key, **options, value: value)
      end
    end
  end
end
