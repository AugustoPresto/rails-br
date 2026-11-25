# frozen_string_literal: true

# Uma entrada por versão suportada do Rails (6.0+). Regenere os gemfiles com:
#   bundle exec appraisal generate
%w[6.0 6.1 7.0 7.1 7.2 8.0].each do |version|
  appraise "rails-#{version.tr('.', '-')}" do
    gem "railties", "~> #{version}.0"
    gem "activemodel", "~> #{version}.0"

    # concurrent-ruby 1.3.5 quebrou o Rails < 7.1 (Logger não é carregado).
    gem "concurrent-ruby", "< 1.3.5" if version.to_f < 7.1
  end
end
