# frozen_string_literal: true

require "action_view"
require_relative "types"

module RailsBr
  # Faz os campos de texto do Rails mostrarem no padrão brasileiro os atributos
  # `:br_currency` e `:br_date`. Sem isso, um registro salvo apareceria como
  # `1234.5` ou `2026-01-05`, que os próprios tipos rejeitam no reenvio.
  #
  # No Rails, o Railtie instala automaticamente. Valem para `text_field`,
  # `search_field`, `telephone_field` e `hidden_field`; `number_field` e
  # `date_field` seguem o formato exigido pelo navegador.
  module FormValues
    # Tipos de `<input>` em que o valor é texto livre.
    INPUT_TYPES = %w[text search tel hidden].freeze

    # Instala a formatação nos campos de formulário. Pode ser chamado mais de
    # uma vez.
    #
    # @return [void]
    def self.install!
      ActionView::Helpers::Tags::TextField.prepend(TextField)
    end

    # Estende `ActionView::Helpers::Tags::TextField`. O método redefinido é
    # interno do Rails, igual nas versões 6.0 a 8.0 e coberto pelos testes.
    #
    # @api private
    module TextField
      private

      def value_before_type_cast
        current = super
        return current unless INPUT_TYPES.include?(field_type) && object.class.respond_to?(:attribute_types)

        type = object.class.attribute_types[@method_name]
        type.respond_to?(:format_input) ? type.format_input(current) : current
      end
    end
  end
end
