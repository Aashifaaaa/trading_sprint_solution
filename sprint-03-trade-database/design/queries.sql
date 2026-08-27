-- Sprint 3 named queries
-- Run against the loaded PostgreSQL database.

-- Q1: all open orders for one account, newest first
SELECT o.id, i.symbol, o.side, o.quantity, o.price, o.status, o.placed_at
FROM orders o
JOIN instruments i ON i.id = o.instrument_id
WHERE o.account_id = 1 AND o.status = 'NEW'
ORDER BY o.placed_at DESC;

-- Q2: last 50 orders for one account in any state, newest first
SELECT o.id, i.symbol, o.side, o.quantity, o.price, o.status, o.placed_at
FROM orders o
JOIN instruments i ON i.id = o.instrument_id
WHERE o.account_id = 1
ORDER BY o.placed_at DESC
LIMIT 50;

-- Q3: everything one account currently holds
SELECT p.instrument_id, i.symbol, i.instrument_name,
       p.quantity, p.average_price, p.last_traded_at
FROM positions p
JOIN instruments i ON i.id = p.instrument_id
WHERE p.account_id = 1
ORDER BY i.symbol;

-- Q4: every order created since a timestamp
SELECT o.id, o.account_id, o.instrument_id, o.side,
       o.quantity, o.price, o.status, o.placed_at
FROM orders o
WHERE o.placed_at >= TIMESTAMPTZ '2026-07-01T00:00:00Z'
ORDER BY o.placed_at;

-- Q5: resolve an account from the customer-facing account reference
SELECT a.id, a.account_number, a.holder_name,
       a.cash_balance, a.status, a.version, c.id AS client_id
FROM accounts a
JOIN clients c ON c.id = a.client_id
WHERE a.account_number = 'ACC-000001';

-- Q6: filled orders oldest first, running trade value and rank by instrument
WITH filled AS (
    SELECT
        o.*,
        (o.quantity * o.executed_price)::DECIMAL(19,4) AS trade_value
    FROM orders o
    WHERE o.account_id = 1
      AND o.status = 'FILLED'
)
SELECT
    id,
    instrument_id,
    side,
    quantity,
    executed_price,
    trade_value,
    placed_at,
    SUM(trade_value) OVER (
        ORDER BY placed_at, id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_trade_value,
    RANK() OVER (
        PARTITION BY instrument_id
        ORDER BY trade_value DESC
    ) AS value_rank_within_instrument
FROM filled
ORDER BY placed_at, id;
