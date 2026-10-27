#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

files=(
  supabase/migrations/20261028000000_acervo_unidades_fisicas.sql
  supabase/seed.sql
  supabase/tests/acervo-unidades-fisicas.test.sql
  supabase/config.toml
)

hash="$(shasum -a 256 "${files[@]}" | shasum -a 256 | cut -d' ' -f1)"
marker="${TMPDIR:-/tmp}/acervo-proof-db-${hash}"

if [[ ! -f "$marker" ]]; then
  npx --yes supabase@latest db reset --local --yes >/dev/null
  touch "$marker"
fi

npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql
