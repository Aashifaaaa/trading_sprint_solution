# Index justifications

| Index | Supports | Why |
|---|---|---|
| `ix_orders_open_account_placed` | Q1 | Q1 filters by `account_id` and `status='NEW'`, then sorts newest first. The partial index contains only open orders and is ordered by `placed_at DESC`. |
| `ix_orders_account_placed` | Q2 | Q2 filters by account and requests the newest 50 rows. The composite ordering lets PostgreSQL avoid a full account scan and sort as the order table grows. |
| `ix_orders_placed_at` | Q4 / incremental extraction | Q4 and the Sprint 7 incremental extract filter orders by creation/placement timestamp. |

## Existing indexes that already serve a query

- `accounts.account_number UNIQUE` supports Q5; no extra index is necessary.
- `clients.email UNIQUE` and `clients.username UNIQUE` support identity lookups.
- Primary keys support joins from foreign keys to parent rows.

## Write cost

Every additional B-tree index consumes storage and must be maintained on inserts and relevant updates. Orders are the write-heavy table, so indexes are deliberately limited to the three query-driven indexes above plus the required unique/primary-key indexes.

## EXPLAIN ANALYZE review commands

Run these against the seeded database:

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT o.id, i.symbol, o.side, o.quantity, o.price, o.status, o.placed_at
FROM orders o JOIN instruments i ON i.id=o.instrument_id
WHERE o.account_id=1 AND o.status='NEW' ORDER BY o.placed_at DESC;

EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders
WHERE account_id=1 ORDER BY placed_at DESC LIMIT 50;

EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders
WHERE placed_at >= TIMESTAMPTZ '2026-07-01T00:00:00Z' ORDER BY placed_at;
```

For the tiny seed set PostgreSQL may still choose a sequential scan because it is cheaper. That is not a failed justification: explain that the index is intended for the production-sized write-heavy orders table and that the planner's choice on a 10-row fixture is expected.
