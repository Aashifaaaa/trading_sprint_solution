-- Sprint 3 seed data.
-- Covers all required business/error paths and is intentionally deterministic.

BEGIN;

INSERT INTO clients (id, name, phone_number, email, username, password_hash, bank_account_ref, created_on, updated_on) VALUES
(1, 'Aarav Kumar', '+91-9000000001', 'aarav@example.com', 'aarav', '$2b$12$examplehashaarav', 'BANK-REF-0001', '2026-01-02T09:00:00Z', '2026-01-02T09:00:00Z'),
(2, 'Meera Shah', '+91-9000000002', 'meera@example.com', 'meera', '$2b$12$examplehashmeera', 'BANK-REF-0002', '2026-01-15T09:00:00Z', '2026-01-15T09:00:00Z'),
(3, 'Rohan Iyer', '+91-9000000003', 'rohan@example.com', 'rohan', '$2b$12$examplehashrohan', 'BANK-REF-0003', '2026-02-01T09:00:00Z', '2026-02-01T09:00:00Z'),
(4, 'Sara Khan', '+91-9000000004', 'sara@example.com', 'sara', '$2b$12$examplehashsara', 'BANK-REF-0004', '2026-02-20T09:00:00Z', '2026-02-20T09:00:00Z');

INSERT INTO accounts (id, client_id, account_number, holder_name, cash_balance, status, version, currency, opened_on, suspended_on, closed_on, created_on, updated_on) VALUES
(1, 1, 'ACC-000001', 'Aarav Kumar', 250000.0000, 'ACTIVE', 4, 'INR', '2026-01-02T09:00:00Z', NULL, NULL, '2026-01-02T09:00:00Z', '2026-07-15T10:00:00Z'),
(2, 2, 'ACC-000002', 'Meera Shah', 15000.0000, 'ACTIVE', 2, 'INR', '2026-01-15T09:00:00Z', NULL, NULL, '2026-01-15T09:00:00Z', '2026-07-05T10:00:00Z'),
(3, 3, 'ACC-000003', 'Rohan Iyer', 50000.0000, 'SUSPENDED', 3, 'INR', '2026-02-01T09:00:00Z', '2026-06-15T10:00:00Z', NULL, '2026-02-01T09:00:00Z', '2026-06-15T10:00:00Z'),
(4, 4, 'ACC-000004', 'Sara Khan', 0.0000, 'CLOSED', 5, 'INR', '2026-02-20T09:00:00Z', NULL, '2026-07-20T16:00:00Z', '2026-02-20T09:00:00Z', '2026-07-20T16:00:00Z');

INSERT INTO instruments (id, isin, symbol, instrument_name, asset_class, currency, exchange, tradable, created_on, retired_on) VALUES
(101, 'INE009A01021', 'INFY.NS', 'Infosys Limited', 'EQUITY', 'INR', 'NSE', TRUE, '2026-01-01T09:00:00Z', NULL),
(102, 'INE002A01018', 'RELIANCE.NS', 'Reliance Industries Limited', 'EQUITY', 'INR', 'NSE', TRUE, '2026-01-01T09:00:00Z', NULL),
(103, 'INE081A01012', 'TATASTEEL.BO', 'Tata Steel Limited', 'EQUITY', 'INR', 'BSE', TRUE, '2026-01-01T09:00:00Z', NULL),
(104, 'INF109KC1KT0', 'NIFTYBEES.NS', 'Nippon India ETF Nifty BeES', 'ETF', 'INR', 'NSE', TRUE, '2026-01-01T09:00:00Z', NULL),
(105, 'IN9999999999', 'OLDCO.BO', 'OldCo Limited (Retired)', 'EQUITY', 'INR', 'BSE', FALSE, '2026-01-01T09:00:00Z', '2026-05-31T16:00:00Z');

INSERT INTO orders (id, account_id, instrument_id, idempotency_key, side, quantity, price, executed_price, status, placed_at, updated_on) VALUES
('00000000-0000-0000-0000-000000000001', 1, 101, 'idem-0001', 'BUY', 20, 1580.0000, 1582.5000, 'FILLED', '2026-03-10T10:00:00Z', '2026-03-10T10:01:00Z'),
('00000000-0000-0000-0000-000000000002', 1, 101, 'idem-0002', 'BUY', 10, 1600.0000, 1598.0000, 'FILLED', '2026-04-12T10:00:00Z', '2026-04-12T10:01:00Z'),
('00000000-0000-0000-0000-000000000003', 1, 101, 'idem-0003', 'SELL', 5, 1620.0000, 1615.0000, 'FILLED', '2026-05-20T10:00:00Z', '2026-05-20T10:01:00Z'),
('00000000-0000-0000-0000-000000000004', 1, 102, 'idem-0004', 'BUY', 15, 2800.0000, 2810.0000, 'FILLED', '2026-06-03T10:00:00Z', '2026-06-03T10:01:00Z'),
('00000000-0000-0000-0000-000000000005', 1, 103, 'idem-0005', 'BUY', 100, 170.0000, NULL, 'NEW', '2026-07-02T10:00:00Z', '2026-07-02T10:00:00Z'),
('00000000-0000-0000-0000-000000000006', 1, 104, 'idem-0006', 'BUY', 40, 250.0000, NULL, 'CANCELLED', '2026-07-03T10:00:00Z', '2026-07-03T10:05:00Z'),
('00000000-0000-0000-0000-000000000007', 2, 101, 'idem-0007', 'BUY', 20, 1590.0000, NULL, 'REJECTED', '2026-07-04T10:00:00Z', '2026-07-04T10:00:30Z'),
('00000000-0000-0000-0000-000000000008', 3, 102, 'idem-0008', 'BUY', 5, 2800.0000, NULL, 'REJECTED', '2026-07-05T10:00:00Z', '2026-07-05T10:00:30Z'),
('00000000-0000-0000-0000-000000000009', 4, 103, 'idem-0009', 'BUY', 1, 170.0000, NULL, 'REJECTED', '2026-07-06T10:00:00Z', '2026-07-06T10:00:30Z'),
('00000000-0000-0000-0000-000000000010', 1, 105, 'idem-0010', 'BUY', 10, 100.0000, 99.0000, 'FILLED', '2026-07-10T10:00:00Z', '2026-07-10T10:01:00Z');

INSERT INTO positions (account_id, instrument_id, quantity, average_price, last_traded_at, updated_on) VALUES
(1, 101, 25, 1587.6667, '2026-05-20T10:01:00Z', '2026-05-20T10:01:00Z'),
(1, 102, 15, 2810.0000, '2026-06-03T10:01:00Z', '2026-06-03T10:01:00Z'),
(1, 105, 10, 99.0000, '2026-07-10T10:01:00Z', '2026-07-10T10:01:00Z');

COMMIT;
