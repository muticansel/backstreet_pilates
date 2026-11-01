#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

shopt -s nullglob
checks=(supabase/tests/*_checks.sql)
test "${#checks[@]}" -gt 0 || {
  echo "No SQL checks found." >&2
  exit 1
}

for check in "${checks[@]}"; do
  echo "Running $check"
  psql "$DATABASE_URL" --set ON_ERROR_STOP=1 --file "$check"
done
