class Order < ApplicationRecord
  belongs_to :customer, optional: true

  attribute :amount, :br_currency
  attribute :due_on, :br_date

  validates :amount, br_currency: true
  validates :due_on, br_date: true
end
