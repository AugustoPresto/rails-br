class Customer < ApplicationRecord
  has_many :orders

  attribute :birth_on, :br_date
  attribute :credit_limit, :br_currency

  validates :name, presence: true
  validates :cpf, cpf: true
  validates :cnpj, cnpj: true
  validates :pix_key, pix_key: true
  validates :birth_on, br_date: true
  validates :credit_limit, br_currency: true
end
