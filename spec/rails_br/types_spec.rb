# frozen_string_literal: true

begin
  require "active_model"
  require "rails_br/validators"
  require "rails_br/types"
rescue LoadError
  nil
end

# Roda apenas onde o ActiveModel está presente (gemfiles do Appraisal).
RSpec.describe "RailsBr::Types", if: defined?(ActiveModel) do
  let(:model) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :price, :br_currency
      attribute :born_on, :br_date

      validates :price, br_currency: true
      validates :born_on, br_date: true

      def self.name
        "Order"
      end
    end
  end

  def errors_for(attribute, value)
    record = model.new(attribute => value)
    record.valid?
    record.errors[attribute]
  end

  describe ":br_currency" do
    {
      "R$ 1.234,56" => "1234.56",
      "10,5" => "10.5",
      10 => "10",
      BigDecimal("7.25") => "7.25"
    }.each do |input, expected|
      it "converte #{input.inspect} para #{expected}", :aggregate_failures do
        record = model.new(price: input)

        expect(record.price).to eq(BigDecimal(expected))
        expect(record.price).to be_a(BigDecimal)
        expect(record).to be_valid
      end
    end

    {
      "texto" => "abc",
      "formato americano" => "1234.56",
      "Float" => 10.5,
      "símbolo" => :dez
    }.each do |description, input|
      it "deixa nil e acusa o erro para #{description}", :aggregate_failures do
        expect(model.new(price: input).price).to be_nil
        expect(errors_for(:price, input)).to eq(["is not a valid amount in Brazilian reais"])
      end
    end

    it "acusa um BigDecimal com mais de 2 casas" do
      expect(errors_for(:price, BigDecimal("1.005"))).not_to be_empty
    end

    it "acusa um BigDecimal não finito" do
      expect(errors_for(:price, BigDecimal("NaN"))).not_to be_empty
    end

    [nil, "", "   "].each do |blank|
      it "ignora o valor em branco #{blank.inspect}" do
        expect(errors_for(:price, blank)).to be_empty
      end
    end

    it "deixa de acusar o erro quando o valor é corrigido", :aggregate_failures do
      record = model.new(price: "abc")
      expect(record).not_to be_valid

      record.price = "R$ 2,00"
      expect(record).to be_valid
    end
  end

  describe ":br_currency com escala" do
    let(:scaled) { Class.new(model) { attribute :price, :br_currency, scale: 4 } }

    it "aceita texto e BigDecimal até a escala", :aggregate_failures do
      expect(scaled.new(price: "1,2345").price).to eq(BigDecimal("1.2345"))
      expect(scaled.new(price: "1,2345")).to be_valid
      expect(scaled.new(price: BigDecimal("1.2345"))).to be_valid
    end

    it "rejeita casas além da escala", :aggregate_failures do
      expect(scaled.new(price: "1,23456").price).to be_nil
      expect(scaled.new(price: "1,23456")).not_to be_valid
    end
  end

  describe ":br_date" do
    {
      "texto brasileiro" => "31/12/2026",
      "Date" => Date.new(2026, 12, 31),
      "DateTime" => DateTime.new(2026, 12, 31, 23, 0)
    }.each do |description, input|
      it "converte #{description} para Date", :aggregate_failures do
        record = model.new(born_on: input)

        expect(record.born_on).to eq(Date.new(2026, 12, 31))
        expect(record.born_on.class).to eq(Date)
        expect(record).to be_valid
      end
    end

    {
      "data inexistente" => "31/02/2026",
      "formato ISO" => "2026-12-31",
      "Time" => Time.utc(2026, 12, 31),
      "Integer" => 31_122_026
    }.each do |description, input|
      it "deixa nil e acusa o erro para #{description}", :aggregate_failures do
        expect(model.new(born_on: input).born_on).to be_nil
        expect(errors_for(:born_on, input)).to eq(["is not a valid date (dd/mm/yyyy)"])
      end
    end

    it "ignora o valor em branco" do
      expect(errors_for(:born_on, "")).to be_empty
    end
  end

  describe "mensagens e opções" do
    it "usa as mensagens em português no locale pt-BR", :aggregate_failures do
      I18n.with_locale(:"pt-BR") do
        expect(errors_for(:price, "abc")).to eq(["não é um valor em reais válido"])
        expect(errors_for(:born_on, "abc")).to eq(["não é uma data válida (dd/mm/aaaa)"])
      end
    end

    it "não deixa allow_blank ou allow_nil esconder texto inválido" do
      lenient = Class.new(model) do
        validates :price, br_currency: { allow_blank: true, allow_nil: true, message: "ruim" }
      end

      record = lenient.new(price: "abc")
      record.valid?

      expect(record.errors[:price]).to include("ruim")
    end

    it "respeita if:" do
      conditional = Class.new(model) do
        attribute :check, :boolean
        clear_validators!
        validates :price, br_currency: true, if: :check
      end

      expect(conditional.new(price: "abc", check: false)).to be_valid
    end

    it "aceita um valor padrão em texto" do
      with_default = Class.new(model) { attribute :price, :br_currency, default: "R$ 5,00" }

      expect(with_default.new.price).to eq(BigDecimal("5"))
    end
  end

  describe "validadores em atributos de texto" do
    let(:plain_model) do
      Class.new do
        include ActiveModel::Model

        attr_accessor :price, :born_on

        validates :price, br_currency: true
        validates :born_on, br_date: true

        def self.name
          "Form"
        end
      end
    end

    it "aceita textos válidos" do
      expect(plain_model.new(price: "R$ 1,00", born_on: "01/01/2026")).to be_valid
    end

    it "acusa textos inválidos" do
      record = plain_model.new(price: "1.00", born_on: "31/02/2026")
      record.valid?

      expect([record.errors[:price], record.errors[:born_on]]).to all(be_any)
    end

    it "aceita um Integer como valor em reais" do
      expect(plain_model.new(price: 10)).to be_valid
    end

    it "ignora nil" do
      expect(plain_model.new).to be_valid
    end
  end

  describe "conversão do banco de dados" do
    let(:currency) { RailsBr::Types::BrCurrency.new }
    let(:date) { RailsBr::Types::BrDate.new }

    it "lê valores decimais, inclusive os que o SQLite devolve como Float", :aggregate_failures do
      expect(currency.deserialize(1234.56)).to eq(BigDecimal("1234.56"))
      expect(currency.deserialize(BigDecimal("1.5"))).to eq(BigDecimal("1.5"))
      expect(currency.deserialize(nil)).to be_nil
    end

    it "lê datas no formato do banco", :aggregate_failures do
      expect(date.deserialize("2026-12-31")).to eq(Date.new(2026, 12, 31))
      expect(date.deserialize(nil)).to be_nil
    end

    it "converte texto brasileiro ao gravar", :aggregate_failures do
      expect(currency.serialize("R$ 1,50")).to eq(BigDecimal("1.5"))
      expect(date.serialize("31/12/2026")).to eq(Date.new(2026, 12, 31))
    end

    it "informa o tipo equivalente do Rails" do
      expect([currency.type, date.type]).to eq(%i[decimal date])
    end
  end
end
