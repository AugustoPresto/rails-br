# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "appraisal", "~> 2.5"
gem "rake", "~> 13.0"
gem "rspec", "~> 3.13"
gem "simplecov", "~> 0.22", require: false # 1.x exige Ruby >= 3.3

# As versões atuais do RuboCop exigem Ruby >= 3.x. O lint roda só no Ruby
# mais recente, então nos Rubies antigos (2.7) o grupo nem entra na resolução.
if RUBY_VERSION >= "3.3"
  group :lint do
    gem "rubocop", require: false
    gem "rubocop-rake", require: false
    gem "rubocop-rspec", require: false
  end
end
