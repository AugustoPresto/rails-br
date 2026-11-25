# frozen_string_literal: true

require_relative "rails_br/version"
require_relative "rails_br/error"

# Helpers brasileiros para Ruby e Rails.
#
# O núcleo é Ruby puro e não altera classes nativas (sem monkey patching).
# Cada módulo é carregado sob demanda: `RailsBr::CPF` só é lido do disco no
# primeiro uso, ou explicitamente com `require "rails_br/cpf"`.
module RailsBr
  autoload :Document, "rails_br/document"
  autoload :CPF, "rails_br/cpf"
  autoload :CNPJ, "rails_br/cnpj"
  autoload :Locale, "rails_br/locale"
end

require_relative "rails_br/railtie" if defined?(Rails::Railtie)
