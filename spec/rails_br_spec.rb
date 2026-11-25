# frozen_string_literal: true

RSpec.describe RailsBr do
  it "tem uma versão semântica" do
    expect(RailsBr::VERSION).to match(/\A\d+\.\d+\.\d+(\.\w+)?\z/)
  end

  it "define uma hierarquia de erros própria" do
    expect(RailsBr::InvalidValueError.ancestors).to include(RailsBr::Error, StandardError)
  end

  it "não altera classes nativas (sem monkey patching)" do
    expect(String.instance_methods).not_to include(:to_cpf, :to_cnpj, :to_extenso)
    expect(Numeric.instance_methods).not_to include(:to_currency, :por_extenso)
  end

  it "só carrega o Railtie quando o Rails está presente" do
    if defined?(Rails::Railtie)
      expect(RailsBr::Railtie.ancestors).to include(Rails::Railtie)
    else
      expect(defined?(RailsBr::Railtie)).to be_nil
    end
  end
end
