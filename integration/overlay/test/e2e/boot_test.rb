require_relative "support"

class BootTest < ActiveSupport::TestCase
  test "o Railtie registra validadores, tipos e traduções sem require manual" do
    assert defined?(ActiveModel::Validations::CpfValidator)
    assert defined?(ActiveModel::Validations::BrDateValidator)
    assert_instance_of RailsBr::Types::BrCurrency, ActiveRecord::Type.lookup(:br_currency)
    assert_equal "não é um CPF válido", I18n.t("errors.messages.invalid_cpf", locale: :"pt-BR")
  end

  test "o eager_load da aplicação funciona com a gem" do
    assert_nothing_raised { Rails.application.eager_load! }
  end

  test "a gem não reabre classes nativas" do
    refute String.method_defined?(:to_cpf)
    assert_equal "05/01/2026", RailsBr::DateFormat.format(Date.new(2026, 1, 5))
    assert_equal Date.new(2026, 1, 5), Date.parse("2026-01-05")
  end
end
