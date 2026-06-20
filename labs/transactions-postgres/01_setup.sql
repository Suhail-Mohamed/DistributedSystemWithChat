-- Lesson 3 setup: transactions, isolation, locks, and concurrent access.
-- Safe to rerun in the local system_design database.

\timing on
\set ON_ERROR_STOP on

DROP TABLE IF EXISTS queue_jobs CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS doctors CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;

CREATE TABLE accounts (
    account_id integer PRIMARY KEY,
    owner_name text NOT NULL,
    balance integer NOT NULL CHECK (balance >= 0),
    version integer NOT NULL DEFAULT 0
);

INSERT INTO accounts (account_id, owner_name, balance)
VALUES
    (1, 'alice', 1000),
    (2, 'bob',   1000);

CREATE TABLE inventory (
    product_id integer PRIMARY KEY,
    product_name text NOT NULL,
    stock integer NOT NULL CHECK (stock >= 0),
    version integer NOT NULL DEFAULT 0
);

INSERT INTO inventory (product_id, product_name, stock, version)
VALUES (1, 'concert-ticket', 10, 0);

CREATE TABLE doctors (
    doctor_name text PRIMARY KEY,
    on_call boolean NOT NULL
);

INSERT INTO doctors (doctor_name, on_call)
VALUES
    ('alice', true),
    ('bob',   true);

CREATE TABLE bookings (
    booking_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_id integer NOT NULL,
    starts_at timestamptz NOT NULL,
    ends_at timestamptz NOT NULL,
    status text NOT NULL CHECK (status IN ('active', 'cancelled')),
    CHECK (ends_at > starts_at)
);

INSERT INTO bookings (room_id, starts_at, ends_at, status)
VALUES
    (101, '2026-07-01 10:00:00+00', '2026-07-01 11:00:00+00', 'active'),
    (101, '2026-07-01 13:00:00+00', '2026-07-01 14:00:00+00', 'active'),
    (202, '2026-07-01 10:00:00+00', '2026-07-01 11:00:00+00', 'active');

CREATE INDEX bookings_room_time_idx
ON bookings (room_id, starts_at, ends_at)
WHERE status = 'active';

CREATE TABLE queue_jobs (
    job_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payload text NOT NULL,
    status text NOT NULL DEFAULT 'ready'
        CHECK (status IN ('ready', 'running', 'done')),
    worker_name text,
    claimed_at timestamptz
);

INSERT INTO queue_jobs (payload)
SELECT 'job-' || gs
FROM generate_series(1, 8) AS gs;

ANALYZE accounts;
ANALYZE inventory;
ANALYZE doctors;
ANALYZE bookings;
ANALYZE queue_jobs;

SELECT 'accounts' AS table_name, count(*) AS rows FROM accounts
UNION ALL
SELECT 'inventory', count(*) FROM inventory
UNION ALL
SELECT 'doctors', count(*) FROM doctors
UNION ALL
SELECT 'bookings', count(*) FROM bookings
UNION ALL
SELECT 'queue_jobs', count(*) FROM queue_jobs;

SELECT * FROM accounts ORDER BY account_id;
SELECT * FROM inventory ORDER BY product_id;
SELECT * FROM doctors ORDER BY doctor_name;
SELECT * FROM queue_jobs ORDER BY job_id;
