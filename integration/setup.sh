#!/usr/bin/env bash
# Gera um app Rails novo, como um usuário faria, e instala a rails-br publicada.
set -euo pipefail

older_than() { [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ] && [ "$1" != "$2" ]; }

# Bundler atual compatível com Rubies antigos.
if older_than "$(ruby -e 'print RUBY_VERSION')" "3.1.0"; then
  gem install bundler -v 2.4.22 --no-document
fi

# O Rails é instalado pelo Bundler, que escolhe dependências compatíveis com o
# Ruby em uso (o `gem install` puro falha em Rubies antigos).
mkdir /bootstrap
{
  echo "source 'https://rubygems.org'"
  echo "gem 'rails', '~> ${RAILS_VERSION}.0'"
  # concurrent-ruby 1.3.5+ quebra o Rails < 7.1, com ou sem a rails-br.
  if older_than "${RAILS_VERSION}" "7.1"; then echo "gem 'concurrent-ruby', '< 1.3.5'"; fi
} > /bootstrap/Gemfile
BUNDLE_GEMFILE=/bootstrap/Gemfile bundle install --jobs 4

cd /
BUNDLE_GEMFILE=/bootstrap/Gemfile bundle exec rails new app --database=postgresql --skip-bundle --skip-git --skip-javascript --skip-spring \
  --skip-bootsnap --skip-listen --skip-sprockets --skip-asset-pipeline --skip-hotwire \
  --skip-action-mailer --skip-action-mailbox --skip-action-text --skip-active-storage \
  --skip-action-cable --skip-webpack-install --skip-kamal --skip-solid --skip-thruster \
  --skip-ci --skip-brakeman --skip-rubocop

cd /app
{
  echo "gem 'rails-br', '${RAILS_BR_VERSION}'"
  echo "gem 'mysql2'"
  if older_than "${RAILS_VERSION}" "7.1"; then echo "gem 'concurrent-ruby', '< 1.3.5'"; fi
  # O minitest 6 é incompatível com o Rails < 7.2.
  if older_than "${RAILS_VERSION}" "7.2"; then echo "gem 'minitest', '< 6'"; fi
} >> Gemfile

bundle install --jobs 4

# O teste de produção roda em HTTP simples dentro do container.
sed -i 's/^\( *\)config\.force_ssl = true/\1config.force_ssl = false/; s/^\( *\)config\.assume_ssl = true/\1config.assume_ssl = false/' \
  config/environments/production.rb
