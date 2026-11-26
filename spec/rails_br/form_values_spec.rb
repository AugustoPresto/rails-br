# frozen_string_literal: true

begin
  require "active_record"
  require "sqlite3"
  require "action_view"
  require "rails_br/validators"
  require "rails_br/types"
  require "rails_br/form_values"
rescue LoadError
  nil
end

# Renderiza campos de formulário reais (gemfiles do Appraisal).
RSpec.describe "RailsBr::FormValues", if: defined?(ActionView) && defined?(SQLite3) do
  let(:model) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "orders"

      attribute :price, :br_currency
      attribute :unit_price, :br_currency, scale: 4
      attribute :born_on, :br_date

      validates :price, :unit_price, br_currency: true
      validates :born_on, br_date: true

      def self.name
        "Order"
      end
    end
  end

  let(:view) { Class.new { include ActionView::Helpers::FormHelper }.new }

  before do
    RailsBr::FormValues.install!
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Schema.verbose = false
    ActiveRecord::Schema.define do
      create_table :orders, force: true do |t|
        t.decimal :price, precision: 10, scale: 2
        t.decimal :unit_price, precision: 16, scale: 4
        t.decimal :plain, precision: 10, scale: 2
        t.date :born_on
        t.date :plain_on
      end
    end
  end

  after { ActiveRecord::Base.remove_connection }

  def saved_order
    id = model.create!(price: "1.234,50", unit_price: "10,1234", born_on: "05/01/2026",
                       plain: 1.5, plain_on: Date.new(2026, 1, 5)).id
    model.find(id)
  end

  def shown(record, attribute, helper = :text_field, **options)
    html = view.public_send(helper, :order, attribute, object: record, **options)
    html[/\svalue="([^"]*)"/, 1]
  end

  it "mostra os valores lidos do banco no padrão brasileiro" do
    order = saved_order

    expect(%i[price unit_price born_on].map { |a| shown(order, a) }).to eq(["1.234,50", "10,1234", "05/01/2026"])
  end

  it "aceita de volta, sem alterar o registro, o que o formulário mostrou", :aggregate_failures do
    order = saved_order
    params = %i[price unit_price born_on].to_h { |a| [a, shown(order, a)] }

    order.assign_attributes(params)

    expect(order).to be_valid
    expect(order).not_to be_changed
  end

  %i[hidden_field search_field telephone_field].each do |helper|
    it "formata também em #{helper}" do
      expect(shown(saved_order, :price, helper)).to eq("1.234,50")
    end
  end

  it "formata um BigDecimal, um Integer e um Date atribuídos pelo código", :aggregate_failures do
    order = model.new(price: 10, unit_price: BigDecimal("1.5"), born_on: Date.new(2026, 12, 31))

    expect(%i[price unit_price born_on].map { |a| shown(order, a) }).to eq(["10,00", "1,50", "31/12/2026"])
  end

  it "mostra todas as casas de um valor mais preciso que a escala, sem arredondar" do
    order = model.new(price: BigDecimal("10.1234"))

    expect(shown(order, :price)).to eq("10,1234")
  end

  it "formata até um valor com muitas casas" do
    order = model.new(price: BigDecimal("0.000000000000000000001"))

    expect(shown(order, :price)).to eq("0,000000000000000000001")
  end

  it "mantém o texto digitado quando ele é inválido", :aggregate_failures do
    order = model.new(price: "abc", born_on: "31/02/2026")

    expect(shown(order, :price)).to eq("abc")
    expect(shown(order, :born_on)).to eq("31/02/2026")
  end

  it "deixa o campo vazio quando não há valor" do
    expect(shown(model.new, :price)).to be_nil
  end

  it "respeita um value: informado" do
    expect(shown(saved_order, :price, value: "x")).to eq("x")
  end

  it "não altera campos numéricos e de data do navegador", :aggregate_failures do
    order = saved_order

    expect(shown(order, :price, :number_field)).to eq("1234.5")
    expect(shown(order, :born_on, :date_field)).to eq("2026-01-05")
  end

  it "não altera atributos de outros tipos", :aggregate_failures do
    order = saved_order

    expect(shown(order, :plain)).to eq("1.5")
    expect(shown(order, :plain_on)).to eq("2026-01-05")
  end

  it "não altera objetos sem tipos de atributo" do
    form = Struct.new(:price).new(BigDecimal("1.5"))

    expect(shown(form, :price)).to eq("1.5")
  end
end
