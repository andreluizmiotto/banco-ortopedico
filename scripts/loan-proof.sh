#!/usr/bin/env bash
# C1-C56: run one pgTAP file and assert that one named assertion passed.
#
# `supabase test db --debug` prints every pgTAP line; a failing assertion prints
# `not ok`, which the `^ok` filter does not match, and the file result must still
# be PASS. The exit code is the proof.
set -euo pipefail

usage() {
  echo "usage: loan-proof.sh <test file> --only C12" >&2
  exit 2
}

file="${1:-}"
[[ -n "$file" ]] || usage
[[ "${2:-}" == "--only" ]] || usage
only="${3:-}"
[[ -n "$only" ]] || usage

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

out="$(npx --yes supabase@latest test db "$file" --debug 2>&1)"
echo "$out" | grep -q "Result: PASS" || {
  echo "$out" | tail -20 >&2
  echo "the test file did not pass" >&2
  exit 1
}
echo "$out" | grep -e "^ok [0-9]* - $only" >/dev/null || {
  echo "assertion $only did not pass" >&2
  exit 1
}
