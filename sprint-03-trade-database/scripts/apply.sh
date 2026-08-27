#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPRINT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${SPRINT_DIR}/.." && pwd)"

# Load root .env only for local defaults. TARGET_DATABASE has priority.
if [[ -f "${REPO_ROOT}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${REPO_ROOT}/.env"
  set +a
fi

DB_NAME="${TARGET_DATABASE:-${POSTGRES_DB:-trading}}"
DB_HOST="${POSTGRES_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_USER="${POSTGRES_USER:-postgres}"

echo "Applying Sprint 3 migrations to ${DB_NAME} at ${DB_HOST}:${DB_PORT}..."
for file in "${SPRINT_DIR}"/migrations/*.sql; do
  echo "  -> ${file##*/}"
  PGPASSWORD="${POSTGRES_PASSWORD:-}" psql     -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}"     -v ON_ERROR_STOP=1 -f "${file}"
done

echo "Loading seed files..."
for file in "${SPRINT_DIR}"/seed/*.sql; do
  echo "  -> ${file##*/}"
  PGPASSWORD="${POSTGRES_PASSWORD:-}" psql     -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}"     -v ON_ERROR_STOP=1 -f "${file}"
done

echo "Sprint 3 database is migrated and seeded."
