#!/usr/bin/env bash
# Uso: entrypoint.sh [suite|scale]
set -uo pipefail

mode="${1:-suite}"
label="ruby$(ruby -e 'print RUBY_VERSION[/\A\d+\.\d+/]')-rails${RAILS_VERSION}-${DATABASE_URL%%:*}"
export SECRET_KEY_BASE="e2e-$(ruby -rsecurerandom -e 'print SecureRandom.hex(64)')"
export PARALLEL_WORKERS=1 RAILS_LOG_TO_STDOUT=
status=0

step() {
  name="$1"; shift
  if "$@" > "/tmp/${name}.log" 2>&1; then
    echo "PASS ${name}"
  else
    echo "FAIL ${name}"; tail -60 "/tmp/${name}.log"; status=1
  fi
}

ruby -e 'puts "ambiente: ruby #{RUBY_VERSION}"'
bundle exec ruby -e 'require "rails/version"; puts "rails #{Rails.version}"; puts "rails-br #{Gem.loaded_specs["rails-br"]&.version || Bundler.load.specs.find { |s| s.name == "rails-br" }.version}"'

if [ "$mode" = "scale" ]; then
  export RAILS_ENV=production
  step prepare bin/rails db:drop db:create db:migrate DISABLE_DATABASE_ENVIRONMENT_CHECK=1
  step scale bin/rails runner script/scale.rb "/results/scale-${label}.json"
  cat /tmp/scale.log
  exit $status
fi

# 1. Testes do app (models, formulários HTTP e consultas).
export RAILS_ENV=test
step prepare bin/rails db:drop db:create db:migrate DISABLE_DATABASE_ENVIRONMENT_CHECK=1
step tests bin/rails test test/e2e
grep -E "runs, .* assertions" /tmp/tests.log | tail -1

# 2. Sondagem de comportamentos de risco (registra o que acontece).
step probes bin/rails runner script/probes.rb "/results/probes-${label}.json"

# 3. Produção: eager_load, Puma com várias threads e requisições concorrentes.
export RAILS_ENV=production RAILS_MAX_THREADS=16
export DATABASE_URL="${DATABASE_URL}_prod?pool=20"
step prod_prepare bin/rails db:drop db:create db:migrate DISABLE_DATABASE_ENVIRONMENT_CHECK=1
bundle exec puma -e production -t 16:16 -b tcp://127.0.0.1:3000 > /tmp/puma.log 2>&1 &
puma_pid=$!
step concurrency ruby script/concurrency.rb
grep -E "^requisições" /tmp/concurrency.log
kill "$puma_pid" 2>/dev/null; wait "$puma_pid" 2>/dev/null
if [ "$status" -ne 0 ]; then tail -30 /tmp/puma.log; fi

exit $status
