# frozen_string_literal: true

module RailsBr
  # Integração com o Rails. Só é carregada quando o Rails já está presente.
  class Railtie < ::Rails::Railtie
    initializer "rails_br.i18n" do
      RailsBr::Locale.install!
    end

    # Os validadores só são registrados se o ActiveModel estiver disponível.
    initializer "rails_br.validators" do
      require "rails_br/validators" if defined?(ActiveModel)
    end

    # Registra os tipos `:br_currency` e `:br_date`.
    initializer "rails_br.types" do
      require "rails_br/types" if defined?(ActiveModel)
    end

    # Mostra `:br_currency` e `:br_date` no padrão brasileiro nos formulários.
    initializer "rails_br.form_values" do
      ActiveSupport.on_load(:action_view) do
        require "rails_br/form_values"
        RailsBr::FormValues.install!
      end
    end
  end
end
