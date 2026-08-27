# Sprint 3 ER diagram

This ERD intentionally follows the team's proposed model while keeping the
transactional schema normalized.

```mermaid
erDiagram
    CLIENT ||--o{ ACCOUNT : owns
    ACCOUNT ||--o{ ORDER : places
    INSTRUMENT ||--o{ ORDER : referenced_by
    ACCOUNT ||--o{ POSITION : holds
    INSTRUMENT ||--o{ POSITION : held_as

    CLIENT {
        bigint id PK
        varchar name
        varchar phone_number
        varchar email UK
        varchar username UK
        varchar password_hash
        varchar bank_account_ref
    }

    ACCOUNT {
        bigint id PK
        bigint client_id FK
        varchar account_number UK
        varchar holder_name
        decimal cash_balance
        account_status status
        integer version
        char currency
        timestamptz opened_on
        timestamptz suspended_on
        timestamptz closed_on
    }

    INSTRUMENT {
        bigint id PK
        varchar isin UK
        varchar symbol UK
        varchar instrument_name
        asset_class asset_class
        char currency
        varchar exchange
        boolean tradable
        timestamptz retired_on
    }

    ORDER {
        uuid id PK
        bigint account_id FK
        bigint instrument_id FK
        varchar idempotency_key UK
        order_side side
        integer quantity
        decimal price
        decimal executed_price
        order_status status
        timestamptz placed_at
        timestamptz updated_on
    }

    POSITION {
        bigint account_id PK,FK
        bigint instrument_id PK,FK
        integer quantity
        decimal average_price
        timestamptz last_traded_at
        timestamptz updated_on
    }
```

## How this maps to the team's screenshot

- **Client** is the customer identity/credential owner. Passwords are stored as `password_hash`, never as a plaintext `password`.
- **Account** belongs to exactly one Client; a Client may own multiple Accounts.
- **Order** belongs to one Account and one Instrument.
- **Position** is the current holding for one Account + Instrument pair, so that pair is its composite primary key.
- **Instrument** is identified internally by `id`; `isin` and `symbol` are business/reference identifiers.

### Deliberate 3NF correction

The screenshot repeats `productType` on Order and Position. The database does **not** store that duplicate value. Product/asset class is a property of the Instrument, so Order and Position reach it through `instrument_id`. This avoids update anomalies and is the cleaner 3NF model.

### Trade and PriceHistory in the screenshot

They are useful concepts, but Sprint 3's brief explicitly makes historical trade data a **design-only deliverable** rather than a built table. Therefore this Sprint 3 database does not create `trade` or `price_history` tables. Their retention grain, population, incremental extraction and growth strategy are documented in `DESIGN.md`. They can be added in a later migration when the relevant sprint requires them.
