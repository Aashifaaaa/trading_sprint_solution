# Sprint 3 data dictionary

| Entity | Important columns | Purpose |
|---|---|---|
| clients | id, email, username, password_hash | Customer identity and authentication-owned data |
| accounts | id, client_id, account_number, cash_balance, status, version | Trading account and current cash/state |
| instruments | id, isin, symbol, asset_class, tradable | Stable instrument reference data; retired instruments remain queryable |
| orders | id, account_id, instrument_id, idempotency_key, side, quantity, price, status | Order received by the trading platform |
| positions | account_id, instrument_id, quantity, average_price | Current holding per account/instrument |

## Key decisions

- Internal foreign keys use numeric IDs rather than repeating customer-facing strings.
- `account_number` is the customer-facing account reference used by the REST API.
- `isin` and `symbol` are unique instrument business identifiers.
- Money uses `DECIMAL(19,4)`, not floating point.
- `password_hash` is stored instead of a plaintext password.
- `version` supports optimistic concurrency on account balance updates.
- `tradable=false` plus `retired_on` retires an instrument without deleting historical reference data.
