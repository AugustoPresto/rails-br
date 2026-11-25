# frozen_string_literal: true

begin
  require "active_model"
  require "rails_br/validators"
rescue LoadError
  nil
end

# Roda apenas onde o ActiveModel está presente (gemfiles do Appraisal).
RSpec.describe "ActiveModel::Validations::PixKeyValidator", if: defined?(ActiveModel) do
  def build_model(validation = { pix_key: true })
    Class.new do
      include ActiveModel::Model

      attr_accessor :pix_key

      validates :pix_key, **validation

      def self.name
        "Payee"
      end
    end
  end

  def errors_for(value, model = build_model)
    record = model.new(pix_key: value)
    record.valid?
    record.errors[:pix_key]
  end

  it "aceita chaves de todos os tipos" do
    ["11144477735", "12ABC34501DE35", "+5561912345678", "pix@bcb.gov.br",
     "123e4567-e12b-12d1-a456-426655440000"].each do |key|
      expect(errors_for(key)).to be_empty
    end
  end

  it "ignora valores em branco (use presence: true para exigir)" do
    expect(errors_for(nil)).to be_empty
    expect(errors_for("")).to be_empty
  end

  it "rejeita uma chave inválida com a mensagem em inglês por padrão" do
    expect(errors_for("111.444.777-35")).to eq(["is not a valid Pix key"])
  end

  it "usa a mensagem em português no locale pt-BR" do
    I18n.with_locale(:"pt-BR") do
      expect(errors_for("Pix@bcb.gov.br")).to eq(["não é uma chave Pix válida"])
    end
  end

  it "aceita uma mensagem customizada" do
    expect(errors_for("lixo", build_model(pix_key: { message: "ruim" }))).to eq(["ruim"])
  end
end
