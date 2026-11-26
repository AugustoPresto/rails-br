#!/usr/bin/env bash
# Testa a rails-br publicada em aplicações Rails reais.
#
#   ./run.sh              matriz completa (PostgreSQL, MySQL e Ruby sem Rails)
#   ./run.sh 3.4 8.0      uma combinação, com PostgreSQL
#   ./run.sh 3.4 8.0 mysql
#   ./run.sh scale 3.4 8.0   carga de 1 milhão de registros
set -uo pipefail
cd "$(dirname "$0")"
mkdir -p results

VERSION="${RAILS_BR_VERSION:-0.3.0}"
POSTGRES_MATRIX=("2.7 6.0" "2.7 6.1" "2.7 7.0" "2.7 7.1" "3.0 6.1" "3.0 7.0" "3.1 7.0" "3.1 7.1"
  "3.1 7.2" "3.2 7.1" "3.2 7.2" "3.2 8.0" "3.3 7.2" "3.3 8.0" "3.4 7.2" "3.4 8.0")
MYSQL_MATRIX=("2.7 6.0" "3.1 7.0" "3.4 8.0")
PURE_RUBIES=(2.7 3.0 3.1 3.2 3.3 3.4)
summary="results/summary.txt"
failed=0

record() {
  echo "$1" | tee -a "$summary"
  case "$1" in FAIL*) failed=1 ;; esac
}

run_combo() {
  local ruby="$1" rails="$2" db="$3" mode="${4:-suite}"
  local id="${ruby/./}_${rails/./}" log="results/${mode}-ruby${ruby}-rails${rails}-${db}.log" url
  export RUBY_VERSION="$ruby" RAILS_VERSION="$rails" RAILS_BR_VERSION="$VERSION"

  if [ "$db" = "mysql" ]; then
    url="mysql2://root:root@mysql:3306/e2e_${id}"
  else
    url="postgres://postgres:postgres@postgres:5432/e2e_${id}"
  fi

  docker compose up -d --wait "$db" > "$log" 2>&1 || { record "FAIL ruby $ruby rails $rails $db: banco"; return; }
  docker compose build app >> "$log" 2>&1 || { record "FAIL ruby $ruby rails $rails $db: build"; return; }
  if docker compose run --rm -T -e DATABASE_URL="$url" app "$mode" >> "$log" 2>&1; then
    record "PASS ruby $ruby rails $rails $db: $(grep -E 'runs, .* assertions|^requisições' "$log" | tr '\n' ' ')"
  else
    record "FAIL ruby $ruby rails $rails $db: $(grep -E '^FAIL|runs, .* assertions' "$log" | tr '\n' ' ')"
  fi
}

run_pure() {
  local ruby="$1" log="results/pure-ruby$1.log"
  if docker run --rm -v "$PWD/smoke.rb:/smoke.rb:ro" "ruby:$ruby" \
    bash -c "gem install rails-br -v $VERSION --no-document && ruby /smoke.rb" > "$log" 2>&1; then
    record "PASS sem Rails: $(grep '^OK' "$log")"
  else
    record "FAIL sem Rails ruby $ruby"
  fi
}

if [ "${1:-}" = "scale" ]; then
  run_combo "$2" "$3" "${4:-postgres}" scale
elif [ "$#" -ge 2 ]; then
  run_combo "$1" "$2" "${3:-postgres}"
else
  : > "$summary"
  for combo in "${POSTGRES_MATRIX[@]}"; do run_combo $combo postgres; done
  for combo in "${MYSQL_MATRIX[@]}"; do run_combo $combo mysql; done
  for ruby in "${PURE_RUBIES[@]}"; do run_pure "$ruby"; done
  echo "fim da matriz" | tee -a "$summary"
fi

exit $failed
