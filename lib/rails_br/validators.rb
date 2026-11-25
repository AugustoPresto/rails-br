# frozen_string_literal: true

require "active_model"
require_relative "../rails_br"
require_relative "locale"

RailsBr::Locale.install!

require_relative "validators/cpf_validator"
