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
  end
end
