-- 001_initial_schema.sql
-- Sprint 3: normalized operational trading schema.
-- Core model follows the team's ERD: Client -> Account -> Order/Position,
-- with Instrument referenced by Order/Position.
-- Trade and PriceHistory are intentionally design-only in Sprint 3; see DESIGN.md.
-- PostgreSQL 16.

BEGIN;

CREATE TYPE account_status AS ENUM ('ACTIVE', 'SUSPENDED', 'CLOSED');
CREATE TYPE asset_class AS ENUM ('EQUITY', 'ETF', 'MUTUAL_FUND', 'BOND', 'FUTURE', 'OPTION', 'CRYPTO', 'FX');
CREATE TYPE order_side AS ENUM ('BUY', 'SELL');
CREATE TYPE order_status AS ENUM ('NEW', 'FILLED', 'REJECTED', 'CANCELLED');

CREATE TABLE clients (
    id                  BIGINT PRIMARY KEY,
    name                VARCHAR(255) NOT NULL,
    phone_number        VARCHAR(30),
    email               VARCHAR(320) NOT NULL UNIQUE,
    username            VARCHAR(100) NOT NULL UNIQUE,
    password_hash       VARCHAR(255) NOT NULL,
    bank_account_ref    VARCHAR(34),
    created_on          TIMESTAMPTZ NOT NULL,
    updated_on          TIMESTAMPTZ NOT NULL,
    CONSTRAINT ck_clients_email CHECK (position('@' IN email) > 1),
    CONSTRAINT ck_clients_dates CHECK (updated_on >= created_on)
);

CREATE TABLE accounts (
    id              BIGINT PRIMARY KEY,
    client_id       BIGINT NOT NULL,
    account_number  VARCHAR(32) NOT NULL UNIQUE,
    holder_name     VARCHAR(255) NOT NULL,
    cash_balance    DECIMAL(19,4) NOT NULL DEFAULT 0,
    status          account_status NOT NULL,
    version         INTEGER NOT NULL DEFAULT 1,
    currency        CHAR(3) NOT NULL DEFAULT 'INR',
    opened_on       TIMESTAMPTZ NOT NULL,
    suspended_on    TIMESTAMPTZ,
    closed_on       TIMESTAMPTZ,
    created_on      TIMESTAMPTZ NOT NULL,
    updated_on      TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_accounts_client FOREIGN KEY (client_id) REFERENCES clients(id),
    CONSTRAINT ck_accounts_cash_nonnegative CHECK (cash_balance >= 0),
    CONSTRAINT ck_accounts_version_positive CHECK (version >= 1),
    CONSTRAINT ck_accounts_state_dates CHECK (
        (status = 'ACTIVE' AND suspended_on IS NULL AND closed_on IS NULL)
        OR
        (status = 'SUSPENDED' AND suspended_on IS NOT NULL AND closed_on IS NULL)
        OR
        (status = 'CLOSED' AND closed_on IS NOT NULL)
    ),
    CONSTRAINT ck_accounts_currency CHECK (currency ~ '^[A-Z]{3}$'),
    CONSTRAINT ck_accounts_dates CHECK (updated_on >= created_on AND opened_on <= created_on)
);

CREATE TABLE instruments (
    id              BIGINT PRIMARY KEY,
    isin            VARCHAR(12) NOT NULL UNIQUE,
    symbol          VARCHAR(20) NOT NULL UNIQUE,
    instrument_name VARCHAR(255) NOT NULL,
    asset_class     asset_class NOT NULL,
    currency        CHAR(3) NOT NULL,
    exchange        VARCHAR(20) NOT NULL,
    tradable        BOOLEAN NOT NULL DEFAULT TRUE,
    created_on      TIMESTAMPTZ NOT NULL,
    retired_on      TIMESTAMPTZ,

    CONSTRAINT ck_instruments_currency CHECK (currency ~ '^[A-Z]{3}$'),
    CONSTRAINT ck_instruments_trading_state CHECK (
        (tradable = TRUE AND retired_on IS NULL)
        OR
        (tradable = FALSE AND retired_on IS NOT NULL)
    )
);

CREATE TABLE orders (
    id              UUID PRIMARY KEY,
    account_id      BIGINT NOT NULL,
    instrument_id   BIGINT NOT NULL,
    idempotency_key VARCHAR(128) NOT NULL UNIQUE,
    side            order_side NOT NULL,
    quantity        INTEGER NOT NULL,
    price           DECIMAL(19,4) NOT NULL,
    executed_price  DECIMAL(19,4),
    status          order_status NOT NULL,
    placed_at       TIMESTAMPTZ NOT NULL,
    updated_on      TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_orders_account FOREIGN KEY (account_id) REFERENCES accounts(id),
    CONSTRAINT fk_orders_instrument FOREIGN KEY (instrument_id) REFERENCES instruments(id),
    CONSTRAINT ck_orders_quantity_positive CHECK (quantity > 0),
    CONSTRAINT ck_orders_price_positive CHECK (price > 0),
    CONSTRAINT ck_orders_terminal_execution CHECK (
        (status = 'FILLED' AND executed_price IS NOT NULL AND executed_price > 0)
        OR
        (status IN ('NEW', 'REJECTED', 'CANCELLED') AND executed_price IS NULL)
    ),
    CONSTRAINT ck_orders_dates CHECK (updated_on >= placed_at)
);

CREATE TABLE positions (
    account_id      BIGINT NOT NULL,
    instrument_id   BIGINT NOT NULL,
    quantity        INTEGER NOT NULL DEFAULT 0,
    average_price   DECIMAL(19,4) NOT NULL DEFAULT 0,
    last_traded_at  TIMESTAMPTZ,
    updated_on      TIMESTAMPTZ NOT NULL,

    PRIMARY KEY (account_id, instrument_id),
    CONSTRAINT fk_positions_account FOREIGN KEY (account_id) REFERENCES accounts(id),
    CONSTRAINT fk_positions_instrument FOREIGN KEY (instrument_id) REFERENCES instruments(id),
    CONSTRAINT ck_positions_quantity_nonnegative CHECK (quantity >= 0),
    CONSTRAINT ck_positions_average_price_nonnegative CHECK (average_price >= 0)
);

-- Query-driven indexes. Primary/unique indexes already cover account_number,
-- client email/username and FK target keys.
CREATE INDEX ix_orders_open_account_placed
    ON orders (account_id, placed_at DESC)
    WHERE status = 'NEW';

CREATE INDEX ix_orders_account_placed
    ON orders (account_id, placed_at DESC);

CREATE INDEX ix_orders_placed_at
    ON orders (placed_at);

CREATE INDEX ix_positions_account
    ON positions (account_id);

COMMIT;
