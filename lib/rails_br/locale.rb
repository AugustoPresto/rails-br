# frozen_string_literal: true

module RailsBr
  # Registro das traduções da gem (pt-BR e en) no I18n.
  #
  # O Railtie faz isso automaticamente no Rails; fora dele, `require
  # "rails_br/validators"` também registra os arquivos.
  module Locale
    # Arquivos de tradução incluídos na gem (`pt-BR` e `en`).
    PATHS = Dir[File.expand_path("../../config/locales/*.yml", __dir__)].sort.freeze

    # Idempotente.
    def self.install!
      ::I18n.load_path |= PATHS
    end
  end
end
