#!/usr/bin/env bash
set -euo pipefail

readonly migration_dir="supabase/migrations"
migrations=()
while IFS= read -r migration; do
  migrations+=("$migration")
done < <(find "$migration_dir" -maxdepth 1 -type f -name '*.sql' -exec basename {} \; | LC_ALL=C sort)

test "${#migrations[@]}" -gt 0 || {
  echo "No Supabase migrations found." >&2
  exit 1
}

previous_version=""
for migration in "${migrations[@]}"; do
  if [[ ! "$migration" =~ ^[0-9]{14}_[a-z0-9_]+\.sql$ ]]; then
    echo "Invalid migration filename: $migration" >&2
    exit 1
  fi
  version="${migration%%_*}"
  if [[ "$version" == "$previous_version" ]]; then
    echo "Duplicate migration version: $version" >&2
    exit 1
  fi
  previous_version="$version"
done

echo "Validated ${#migrations[@]} ordered migration filenames."
