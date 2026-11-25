# frozen_string_literal: true

require_relative "rails_br/version"
require_relative "rails_br/error"

# Helpers brasileiros para Ruby e Rails.
#
# O núcleo é Ruby puro e não altera classes nativas (sem monkey patching).
# Cada módulo (CPF, CNPJ, Pix, ...) é carregado sob demanda, por exemplo
# `require "rails_br/cpf"`.
module RailsBr
end

require_relative "rails_br/railtie" if defined?(Rails::Railtie)
