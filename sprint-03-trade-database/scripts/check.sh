#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPRINT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${SPRINT_DIR}/.." && pwd)"

if [[ -f "${REPO_ROOT}/.env" ]]; then
  set -a
  source "${REPO_ROOT}/.env"
  set +a
fi

DB_NAME="${TARGET_DATABASE:-${POSTGRES_DB:-trading}}"
DB_HOST="${POSTGRES_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_USER="${POSTGRES_USER:-postgres}"

PSQL=(psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1)

echo "== Tables =="
PGPASSWORD="${POSTGRES_PASSWORD:-}" "${PSQL[@]}" -c "\dt"

echo "== Row counts =="
PGPASSWORD="${POSTGRES_PASSWORD:-}" "${PSQL[@]}" -c "
SELECT 'clients' AS table_name, count(*) FROM clients
UNION ALL SELECT 'accounts', count(*) FROM accounts
UNION ALL SELECT 'instruments', count(*) FROM instruments
UNION ALL SELECT 'orders', count(*) FROM orders
UNION ALL SELECT 'positions', count(*) FROM positions;
"

echo "== Account states =="
PGPASSWORD="${POSTGRES_PASSWORD:-}" "${PSQL[@]}" -c "
SELECT status, count(*) FROM accounts GROUP BY status ORDER BY status;
"

echo "== Order states =="
PGPASSWORD="${POSTGRES_PASSWORD:-}" "${PSQL[@]}" -c "
SELECT status, count(*) FROM orders GROUP BY status ORDER BY status;
"

echo "== Q1-Q6 =="
PGPASSWORD="${POSTGRES_PASSWORD:-}" "${PSQL[@]}" -f "${SPRINT_DIR}/design/queries.sql" >/dev/null

echo "== Constraint rejection: duplicate idempotency key (expected SQLSTATE 23505) =="
set +e
DUP_OUT=$(PGPASSWORD="${POSTGRES_PASSWORD:-}" "${PSQL[@]}" -c "
INSERT INTO orders
(id, account_id, instrument_id, idempotency_key, side, quantity, price, status, placed_at, updated_on)
VALUES
('ffffffff-ffff-4fff-8fff-ffffffffffff', 1, 101, 'idem-0001', 'BUY', 1, 1.00, 'NEW',
 now(), now());
" 2>&1)
DUP_CODE=$?
set -e
echo "${DUP_OUT}"
[[ ${DUP_CODE} -ne 0 ]]
grep -q "duplicate key" <<<"${DUP_OUT}"

echo "== Constraint rejection: missing parent (expected SQLSTATE 23503) =="
set +e
FK_OUT=$(PGPASSWORD="${POSTGRES_PASSWORD:-}" "${PSQL[@]}" -c "
INSERT INTO orders
(id, account_id, instrument_id, idempotency_key, side, quantity, price, status, placed_at, updated_on)
VALUES
('ffffffff-ffff-4fff-8fff-ffffffffffff', 999999, 101, 'probe-fk-999', 'BUY', 1, 1.00, 'NEW',
 now(), now());
" 2>&1)
FK_CODE=$?
set -e
echo "${FK_OUT}"
[[ ${FK_CODE} -ne 0 ]]
grep -q "foreign key constraint" <<<"${FK_OUT}"

echo "Sprint 3 checks completed."
