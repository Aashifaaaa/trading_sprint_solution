# START HERE — Sprint 3 + Sprint 4

This package is a working starting point for the Enterprise Trading Platform capstone.

## 0. What was changed to match the team's ERD

The Sprint 3 operational model now follows the ERD you supplied:

`CLIENT -> ACCOUNT -> ORDER`

and

`ACCOUNT + INSTRUMENT -> POSITION`

The database also keeps `INSTRUMENT` as the stable reference for ISIN, symbol and asset class.

Two ERD entities are intentionally **design-only** for Sprint 3:

- `Trade`: future execution history.
- `PriceHistory`: future/reference-market history.

The Sprint 3 brief makes historical trade data a documented design rather than a built table, so adding those two tables now would be unnecessary scope.

The screenshot's repeated `productType` on Order and Position is also intentionally not duplicated in the database. Asset class belongs to Instrument and is reached through the foreign key. That is the normalization/3NF decision to explain during review.

## 1. Configure the environment

Copy `.env.example` to `.env` if `.env` is missing. Then set:

```env
FAUXNANCE_API_KEY=YOUR_REAL_KEY
```

Never commit `.env` or paste the real key into source code.

## 2. Start PostgreSQL — NO DOCKER REQUIRED

For Sprint 3 and Sprint 4, Docker is not required. The sprint acceptance criteria require PostgreSQL 16 at `localhost:5432`; Docker itself is not an acceptance criterion. If your VM cannot provide hardware virtualization, install PostgreSQL 16 directly inside the VM.

Verify:

```powershell
psql --version
```

Create the database if needed:

```powershell
createdb -U postgres trading
```

Or:

```powershell
psql -U postgres -c "CREATE DATABASE trading;"
```

Set the PostgreSQL password you chose during installation in `.env`:

```env
POSTGRES_DB=trading
POSTGRES_USER=postgres
POSTGRES_PASSWORD=YOUR_POSTGRES_PASSWORD
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
```

Test:

```powershell
psql -h localhost -p 5432 -U postgres -d trading -c "SELECT version();"
```

The Docker compose file is retained only as an optional future setup; do not run it for this VM-based workflow.

## 3. Apply Sprint 3

From PowerShell:

```powershell
cd sprint-03-trade-database
powershell -ExecutionPolicy Bypass -File scripts/apply.ps1
powershell -ExecutionPolicy Bypass -File scripts/check.ps1
```

The scripts read the repository `.env`, use `TARGET_DATABASE` when set and otherwise fall back to `POSTGRES_DB`, apply migrations in filename order, then load seed files with `ON_ERROR_STOP=1`.

The original Bash scripts remain available for Git Bash/WSL.

## 4. What the seed data covers

The generated seed contains:

- clients;
- accounts in ACTIVE, SUSPENDED and CLOSED states;
- an account with low cash;
- several NSE/BSE instruments;
- a retired instrument that remains in the database;
- NEW, FILLED, REJECTED and CANCELLED orders;
- positions derived from filled orders;
- timestamps spread across multiple months.

## 5. Sprint 3 files to present

- `migrations/001_initial_schema.sql` — DDL, keys and constraints.
- `seed/001_seed.sql` — fixture data.
- `design/er-diagram.md` — Mermaid ERD matching the team's conceptual model.
- `design/data-dictionary.md` — columns and decisions.
- `design/queries.sql` — six named queries.
- `design/indexes.md` — index justification and EXPLAIN commands.
- `DESIGN.md` — historical trade data design.
- `manifest.env` — harness names.
- `scripts/apply.sh` — one-command rebuild + seed.
- `scripts/check.sh` — acceptance probes.

## 6. Sprint 4 setup

From repository root:

```powershell
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install -e ".\sprint-04-analytics-etl[dev]"
.\.venv\Scripts\python.exe -m pytest ".\sprint-04-analytics-etl"
```

The transform tests use local fixtures and never call the network.

## 7. Sprint 4 pipeline

The code is split into:

- `src/trading_analytics/extract.py` — API and raw-response caching.
- `src/trading_analytics/transform.py` — validation, typing and cleaning.
- `src/trading_analytics/load.py` — analytical store writes.
- `src/trading_analytics/pipeline.py` — orchestration only.

Run the pipeline after setting the API key:

```powershell
.\.venv\Scripts\trading-etl.exe
```

The first run calls Fauxnance. Raw responses are cached under `.cache/`, so rerunning the same symbol/range should not spend another API request.

## 8. Fixtures and malformed data

`fixtures/candles-malformed.json` contains six defects:

1. duplicate date;
2. missing close;
3. non-numeric price;
4. high below low;
5. negative volume;
6. non-ISO date.

The transform rejects/quarantines invalid rows rather than loading invalid market data.

Run the malformed-input test directly:

```powershell
.\.venv\Scripts\python.exe -m pytest ".\sprint-04-analytics-etl\tests\test_transform.py::test_rejects_a_high_below_a_low"
```

## 9. Analytics star schema

The analytical contract contains:

`DIM_ACCOUNT`, `DIM_INSTRUMENT`, `DIM_DATE`, `FACT_TRADES`.

The fact grain is one order/trade source row at the level specified by the analytical contract. Dimensions are loaded before facts.

The package includes `load_sample_star.py` for a local DuckDB smoke test once the Python dependencies are installed.

## 10. Charts and claims

`artefacts/` contains three chart files and `claims.md` contains business claims supported by them.

## 11. Suggested review explanation

Say this:

> Client is the customer identity, Account is the trading relationship, Instrument is stable reference data, Order records what the customer requested, and Position records the current net holding for an account and instrument. Orders and positions reference Instrument rather than duplicating product type, which keeps the model normalized. Idempotency is enforced by a unique database constraint, account version supports optimistic concurrency, retired instruments remain for historical references, and money uses DECIMAL rather than floating point.

For the historical design:

> Trade and PriceHistory are shown as conceptual/future entities but are not built in Sprint 3 because historical trade data is a documented design deliverable. The design specifies retention grain, population, incremental extraction, growth, partitioning and archival decisions.
