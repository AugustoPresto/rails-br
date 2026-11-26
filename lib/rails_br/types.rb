# frozen_string_literal: true

require "active_model"
require_relative "../rails_br"
require_relative "types/br_currency"
require_relative "types/br_date"

module RailsBr
  # Tipos de atributo do ActiveModel e do ActiveRecord.
  #
  # `require "rails_br/types"` registra `:br_currency` e `:br_date`. No Rails, o
  # Railtie faz isso automaticamente.
  module Types
    # Nomes com que os tipos são registrados.
    REGISTRY = { br_currency: BrCurrency, br_date: BrDate }.freeze

    REGISTRY.each { |name, type| ActiveModel::Type.register(name, type) }

    # O ActiveRecord tem um registro próprio; o hook roda quando ele é carregado.
    ActiveSupport.on_load(:active_record) do
      RailsBr::Types::REGISTRY.each { |name, type| ActiveRecord::Type.register(name, type) }
    end
  end
end
