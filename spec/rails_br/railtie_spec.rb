# frozen_string_literal: true

# Roda apenas nos gemfiles do Appraisal, onde o Rails está presente.
RSpec.describe "RailsBr::Railtie", if: defined?(Rails::Railtie) do
  let(:initializer) do
    RailsBr::Railtie.initializers.find { |init| init.name == "rails_br.i18n" }
  end

  it "registra o initializer de I18n" do
    expect(initializer).not_to be_nil
  end

  it "executa o initializer sem alterar o load_path quando não há locales" do
    expect { initializer.run(Object.new) }.not_to(change { I18n.load_path.size })
  end
end
