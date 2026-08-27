# Seed data

`001_seed.sql` is the generated fixture set for this cohort workspace.

It covers:

- clients and accounts in ACTIVE, SUSPENDED and CLOSED states;
- an account with low cash;
- multiple instruments and asset classes;
- a retired instrument that remains referenced by historical orders/positions;
- orders in NEW, FILLED, REJECTED and CANCELLED states;
- positions that reconcile with the filled orders used to create them;
- timestamps spread across multiple months for query and incremental-extract testing.

The seed is loaded only after migrations and is intended for an empty database.
