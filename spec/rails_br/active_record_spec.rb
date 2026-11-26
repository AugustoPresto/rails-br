# frozen_string_literal: true

begin
  require "active_record"
  require "sqlite3"
  require "rails_br/validators"
  require "rails_br/types"
rescue LoadError
  nil
end

# Integração com um banco SQLite em memória (gemfiles do Appraisal).
RSpec.describe "RailsBr::Types::ActiveRecord", if: defined?(ActiveRecord) && defined?(SQLite3) do
  let(:model) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "orders"

      attribute :price, :br_currency
      attribute :born_on, :br_date

      validates :price, br_currency: true
      validates :born_on, br_date: true

      def self.name
        "Order"
      end
    end
  end

  before do
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Schema.verbose = false
    ActiveRecord::Schema.define do
      create_table :orders, force: true do |t|
        t.decimal :price, precision: 10, scale: 2
        t.date :born_on
      end
    end
  end

  after { ActiveRecord::Base.remove_connection }

  def saved_order
    model.create!(price: "R$ 1.234,56", born_on: "31/12/2026")
  end

  it "grava e lê de volta como BigDecimal e Date" do
    order = model.find(saved_order.id)

    expect([order.price, order.born_on]).to eq([BigDecimal("1234.56"), Date.new(2026, 12, 31)])
  end

  it "considera válido um registro lido do banco" do
    expect(model.find(saved_order.id)).to be_valid
  end

  it "não marca como alterado um registro recém-lido ou reatribuído com o mesmo valor", :aggregate_failures do
    order = model.find(saved_order.id)
    expect(order).not_to be_changed

    order.assign_attributes(price: "1.234,56", born_on: "31/12/2026")
    expect(order).not_to be_changed
  end

  it "consulta com texto brasileiro e com Date", :aggregate_failures do
    order = saved_order

    expect(model.where(price: "R$ 1.234,56").to_a).to eq([order])
    expect(model.where(born_on: "31/12/2026").to_a).to eq([order])
    expect(model.where(born_on: Date.new(2026, 12, 31)).to_a).to eq([order])
  end

  it "não grava texto inválido", :aggregate_failures do
    order = model.new(price: "abc", born_on: "31/02/2026")

    expect(order.save).to be(false)
    expect(order.errors.messages.keys).to contain_exactly(:price, :born_on)
    expect(model.count).to eq(0)
  end
end
