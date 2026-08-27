# Sprint 4 — Analytics ETL

## What this project does

1. **Extract** calls Fauxnance and caches raw JSON responses by symbol/range.
2. **Transform** validates and cleans candles without network, environment or file I/O.
3. **Load/report** creates local DuckDB reporting output and the repository also contains the binding analytical star schema.
4. **Charts** are static PNG files, so they open without a network connection or build step.
5. **Tests** use only the provided fixtures and never call the API.

## Symbols

- INFY.NS — Infosys, NSE
- RELIANCE.NS — Reliance Industries, NSE
- TATASTEEL.BO — Tata Steel, BSE

## Commands

From the repository root:

```bash
python -m venv .venv
# Windows PowerShell:
.\.venv\Scripts\python.exe -m pip install -e .\sprint-04-analytics-etl[dev]
.\.venv\Scripts\python.exe -m pytest .\sprint-04-analytics-etl

# Linux/macOS:
.venv/bin/python -m pip install -e 'sprint-04-analytics-etl[dev]'
.venv/bin/python -m pytest sprint-04-analytics-etl
```

Set the real `FAUXNANCE_API_KEY` only in the ignored root `.env`, then:

```bash
trading-etl
```

The first run consumes API quota. Re-running the same symbol/range uses `.cache/` and should make no API request.

Before troubleshooting the API, check:

```text
GET /health    # no key
GET /usage     # key required
```

The code exposes `check_health()` and `check_usage()` for this.

## Analytical star schema

`../contracts/analytics-schema.sql` is the supplied binding schema. Its grain is one order per `fact_trades` row. Dimensions are loaded first, then facts resolve surrogate keys. The supplied contract uses a Type 2 `dim_account`, a Type 1 `dim_instrument`, a calendar `dim_date`, and `fact_trades`.
