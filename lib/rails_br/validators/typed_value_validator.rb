# frozen_string_literal: true

module RailsBr
  # Base dos validadores de atributos que convertem texto (`br_currency` e
  # `br_date`). Quando a conversão falha, o atributo fica `nil`; por isso o
  # validador examina também o valor digitado, antes da conversão.
  #
  # As opções `allow_nil` e `allow_blank` não escondem texto inválido: valores
  # realmente em branco já são ignorados.
  #
  # @api private
  class TypedValueValidator < ActiveModel::EachValidator
    # @param record [ActiveModel::Validations] o objeto validado
    # @return [void]
    def validate(record)
      attributes.each do |attribute|
        validate_each(record, attribute, record.read_attribute_for_validation(attribute))
      end
    end

    # @param record [ActiveModel::Validations] o objeto validado
    # @param attribute [Symbol] o atributo
    # @param value [Object] o valor já convertido
    # @return [void]
    def validate_each(record, attribute, value)
      candidate = value.nil? ? raw_value(record, attribute) : value
      return if candidate.blank? || acceptable?(candidate, record, attribute)

      record.errors.add(attribute, error_key, **options, value: candidate)
    end

    private

    # O ActiveRecord (e o ActiveModel mais novo) expõe `*_before_type_cast`. No
    # ActiveModel::Attributes de versões antigas, o valor fica no AttributeSet.
    def raw_value(record, attribute)
      method = "#{attribute}_before_type_cast"
      return record.public_send(method) if record.respond_to?(method)

      attribute_set_value(record.instance_variable_get(:@attributes), attribute.to_s)
    end

    def attribute_set_value(set, name)
      return unless defined?(ActiveModel::AttributeSet) && set.is_a?(ActiveModel::AttributeSet)

      set[name].value_before_type_cast if set.key?(name)
    end
  end
end
