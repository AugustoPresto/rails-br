# frozen_string_literal: true

require_relative "lib/rails_br/version"

Gem::Specification.new do |spec|
  spec.name = "rails-br"
  spec.version = RailsBr::VERSION
  spec.authors = ["Augusto Souza"]

  spec.summary = "Helpers brasileiros para Ruby e Rails: CPF, CNPJ (inclusive alfanumérico), Pix, moeda e data."
  spec.description = "Sucessora moderna da Brazilian Rails. Núcleo em Ruby puro, sem monkey patching, " \
                     "com integração opcional ao Rails (ActiveModel, I18n) a partir do Rails 6.0."
  spec.homepage = "https://github.com/AugustoPresto/rails-br"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*", "config/**/*", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  # O Rails (activemodel) é opcional e só é integrado quando já estiver presente
  # na aplicação. BigDecimal é gem padrão do Ruby, mas virou bundled gem no 3.4,
  # então precisa ser declarada para funcionar sob o Bundler.
  spec.add_dependency "bigdecimal", ">= 2.0"
end
