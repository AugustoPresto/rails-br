class Entry < ApplicationRecord
  attribute :amount, :br_currency

  validates :amount, br_currency: true
end
