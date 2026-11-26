# frozen_string_literal: true

# Roda apenas nos gemfiles do Appraisal, onde o Rails está presente.
RSpec.describe "RailsBr::Railtie", if: defined?(Rails::Railtie) do
  def initializer(name)
    RailsBr::Railtie.initializers.find { |init| init.name == name }
  end

  it "registra os initializers de I18n e validadores" do
    expect(initializer("rails_br.i18n")).not_to be_nil
    expect(initializer("rails_br.validators")).not_to be_nil
  end

  it "registra as traduções da gem no I18n" do
    initializer("rails_br.i18n").run(Object.new)

    expect(I18n.load_path).to include(*RailsBr::Locale::PATHS)
    expect(RailsBr::Locale::PATHS.map { |p| File.basename(p) }).to contain_exactly("en.yml", "pt-BR.yml")
  end

  it "é idempotente" do
    expect do
      2.times { initializer("rails_br.i18n").run(Object.new) }
    end.not_to(change { I18n.load_path.size })
  end

  it "registra os tipos br_currency e br_date" do
    require "active_model"
    initializer("rails_br.types").run(Object.new)

    expect(ActiveModel::Type.lookup(:br_date)).to be_a(RailsBr::Types::BrDate)
  end

  it "instala a formatação dos formulários quando o ActionView carrega" do
    require "action_view"
    initializer("rails_br.form_values").run(Object.new)
    ActionView::Base # rubocop:disable Lint/Void -- dispara o hook

    expect(ActionView::Helpers::Tags::TextField.ancestors).to include(RailsBr::FormValues::TextField)
  end

  it "carrega os validadores quando o ActiveModel está presente" do
    require "active_model"
    initializer("rails_br.validators").run(Object.new)

    expect(defined?(ActiveModel::Validations::CpfValidator)).to be_truthy
  end
end
