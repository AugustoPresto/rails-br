# frozen_string_literal: true

begin
  require "active_model"
  require "rails_br/validators"
rescue LoadError
  nil
end

# Roda apenas onde o ActiveModel está presente (gemfiles do Appraisal).
RSpec.describe "ActiveModel::Validations::CnpjValidator", if: defined?(ActiveModel) do
  let(:customer_model) do
    Class.new do
      include ActiveModel::Model

      attr_accessor :cpf, :cnpj

      validates :cpf, cpf: true
      validates :cnpj, cnpj: true

      def self.name
        "Customer"
      end
    end
  end

  def build_model(validation = { cnpj: true })
    Class.new do
      include ActiveModel::Model

      attr_accessor :cnpj

      validates :cnpj, **validation

      def self.name
        "Company"
      end
    end
  end

  def errors_for(value, model = build_model)
    record = model.new(cnpj: value)
    record.valid?
    record.errors[:cnpj]
  end

  it "aceita CNPJs numéricos e alfanuméricos válidos" do
    expect(errors_for("11.222.333/0001-81")).to be_empty
    expect(errors_for("12.ABC.345/01DE-35")).to be_empty
  end

  it "ignora valores em branco (use presence: true para exigir)" do
    expect(errors_for(nil)).to be_empty
    expect(errors_for("")).to be_empty
  end

  it "rejeita um CNPJ inválido com a mensagem em inglês por padrão" do
    expect(errors_for("11.222.333/0001-82")).to eq(["is not a valid CNPJ"])
  end

  it "usa a mensagem em português no locale pt-BR" do
    I18n.with_locale(:"pt-BR") do
      expect(errors_for("00.000.000/0000-00")).to eq(["não é um CNPJ válido"])
    end
  end

  it "aceita uma mensagem customizada" do
    expect(errors_for("123", build_model(cnpj: { message: "ruim" }))).to eq(["ruim"])
  end

  it "convive com o validador de CPF no mesmo model" do
    record = customer_model.new(cpf: "111.444.777-35", cnpj: "123")
    record.valid?

    expect(record.errors[:cpf]).to be_empty
    expect(record.errors[:cnpj]).to eq(["is not a valid CNPJ"])
  end
end
