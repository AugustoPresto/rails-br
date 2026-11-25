# frozen_string_literal: true

begin
  require "active_model"
  require "rails_br/validators"
rescue LoadError
  nil
end

# Roda apenas onde o ActiveModel está presente (gemfiles do Appraisal).
RSpec.describe "ActiveModel::Validations::CpfValidator", if: defined?(ActiveModel) do
  # Constrói um model com `validates :cpf, **validation`. O nome é necessário
  # para o ActiveModel gerar as mensagens de erro.
  def build_model(validation = { cpf: true })
    Class.new do
      include ActiveModel::Model

      attr_accessor :cpf, :check

      validates :cpf, **validation

      def self.name
        "Person"
      end
    end
  end

  def errors_for(value, model = build_model)
    record = model.new(cpf: value)
    record.valid?
    record.errors[:cpf]
  end

  it "aceita um CPF válido, com ou sem máscara" do
    expect(errors_for("111.444.777-35")).to be_empty
    expect(errors_for("11144477735")).to be_empty
  end

  it "ignora valores em branco (use presence: true para exigir)" do
    expect(errors_for(nil)).to be_empty
    expect(errors_for("")).to be_empty
  end

  it "rejeita um CPF inválido com a mensagem em inglês por padrão" do
    expect(errors_for("111.444.777-36")).to eq(["is not a valid CPF"])
  end

  it "usa a mensagem em português no locale pt-BR" do
    I18n.with_locale(:"pt-BR") do
      expect(errors_for("111.111.111-11")).to eq(["não é um CPF válido"])
    end
  end

  it "aceita uma mensagem customizada" do
    model = build_model(cpf: { message: "ruim" })

    expect(errors_for("123", model)).to eq(["ruim"])
  end

  it "respeita opções padrão como if:" do
    model = build_model(cpf: true, if: :check)

    expect(model.new(cpf: "123", check: false)).to be_valid
    expect(model.new(cpf: "123", check: true)).not_to be_valid
  end
end
