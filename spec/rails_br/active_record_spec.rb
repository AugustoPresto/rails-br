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
        t.decimal :unit_price, precision: 16, scale: 4
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

  describe "coluna com mais de 2 casas decimais" do
    let(:plain_scale) do
      Class.new(model) do
        attribute :unit_price, :br_currency
        validates :unit_price, br_currency: true
      end
    end
    let(:four_places) do
      Class.new(model) do
        attribute :unit_price, :br_currency, scale: 4
        validates :unit_price, br_currency: true
      end
    end

    def stored_id
      model.connection.insert("INSERT INTO orders (unit_price) VALUES (10.1234)")
    end

    it "não bloqueia a atualização de um registro por causa do valor já gravado", :aggregate_failures do
      order = plain_scale.find(stored_id)

      expect(order).to be_valid
      expect(order.update(born_on: "01/01/2026")).to be(true)
    end

    it "continua acusando um valor novo com casas demais", :aggregate_failures do
      order = plain_scale.find(stored_id)
      order.unit_price = BigDecimal("1.005")

      expect(order).not_to be_valid
    end

    it "lê, grava e consulta com a escala declarada", :aggregate_failures do
      order = four_places.create!(unit_price: "R$ 10,1234")

      expect(four_places.find(order.id).unit_price).to eq(BigDecimal("10.1234"))
      expect(four_places.where(unit_price: "10,1234").to_a).to eq([order])
    end

    it "acusa mais casas que a escala declarada", :aggregate_failures do
      expect(four_places.new(unit_price: "1,00001")).not_to be_valid
      expect(four_places.new(unit_price: BigDecimal("1.00001"))).not_to be_valid
      expect(four_places.new(unit_price: BigDecimal("1.0001"))).to be_valid
    end
  end
end
