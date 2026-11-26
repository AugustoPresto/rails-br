# frozen_string_literal: true

require "active_model"
require_relative "../rails_br"
require_relative "locale"

RailsBr::Locale.install!

require_relative "validators/cpf_validator"
require_relative "validators/cnpj_validator"
require_relative "validators/pix_key_validator"
require_relative "validators/typed_value_validator"
require_relative "validators/br_currency_validator"
require_relative "validators/br_date_validator"
