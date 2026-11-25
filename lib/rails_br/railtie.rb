# frozen_string_literal: true

module RailsBr
  # Integração com o Rails. Só é carregada quando o Rails já está presente.
  class Railtie < ::Rails::Railtie
    initializer "rails_br.i18n" do
      locales = Dir[File.expand_path("../../config/locales/*.yml", __dir__)]
      ::I18n.load_path.concat(locales)
    end
  end
end
