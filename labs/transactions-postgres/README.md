# Lesson 3 Lab — Transactions, Isolation, Locks, and Concurrency

This lab uses two interactive PostgreSQL sessions so you can observe snapshots, waiting, conflicts, deadlocks, and retries directly.

All questions are in:

```text
questions/lesson-03-transactions-isolation-locks-concurrency.md
```

Write answers in:

```text
labs/transactions-postgres/answers_lab03.md
```

## Requirements

- Docker Desktop or Docker Engine with Compose
- The existing `labs/docker-compose.yml`

## Start PostgreSQL

From the repository root:

```bash
cd labs
docker compose up -d postgres
docker compose ps
cd ..
```

## Initialize or reset the lab

```bash
docker exec -i ds_course_postgres \
  psql -U app -d system_design \
  < labs/transactions-postgres/01_setup.sql
```

Rerun that command between experiments when a clean state is needed.

## Open two sessions

Open two terminal windows. In each one run:

```bash
docker exec -it ds_course_postgres \
  psql -U app -d system_design
```

In Session A:

```sql
SET application_name = 'lesson3-session-a';
\pset pager off
```

In Session B:

```sql
SET application_name = 'lesson3-session-b';
\pset pager off
```

When PostgreSQL reports that a transaction is aborted, run:

```sql
ROLLBACK;
```

before continuing.

---

# Experiment 1 — Read Committed

Reset the lab.

## Session A

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;

SELECT balance
FROM accounts
WHERE account_id = 1;
```

Keep this transaction open.

## Session B

```sql
BEGIN;

UPDATE accounts
SET balance = 1200
WHERE account_id = 1;

COMMIT;
```

## Session A

```sql
SELECT balance
FROM accounts
WHERE account_id = 1;

COMMIT;
```

Record both values and the isolation level.

---

# Experiment 2 — Repeatable Read

Reset the lab.

## Session A

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT balance
FROM accounts
WHERE account_id = 1;
```

## Session B

```sql
BEGIN;

UPDATE accounts
SET balance = 1200
WHERE account_id = 1;

COMMIT;
```

## Session A

```sql
SELECT balance
FROM accounts
WHERE account_id = 1;

COMMIT;
```

---

# Experiment 3 — Ordinary SELECT does not row-lock

Reset the lab.

## Session A

```sql
BEGIN;

SELECT *
FROM accounts
WHERE account_id = 1;
```

Keep the transaction open.

## Session B

```sql
UPDATE accounts
SET balance = balance + 10
WHERE account_id = 1
RETURNING *;
```

## Session A

```sql
COMMIT;
```

---

# Experiment 4 — SELECT FOR UPDATE

Reset the lab.

## Session A

```sql
BEGIN;

SELECT *
FROM accounts
WHERE account_id = 1
FOR UPDATE;
```

Keep the transaction open.

## Session B

```sql
SET lock_timeout = '3s';

UPDATE accounts
SET balance = balance + 10
WHERE account_id = 1;

RESET lock_timeout;
```

The update should wait and then time out while Session A owns the conflicting row lock.

## Session A

```sql
COMMIT;
```

## Session B

After rolling back if necessary, retry:

```sql
ROLLBACK;
RESET lock_timeout;

UPDATE accounts
SET balance = balance + 10
WHERE account_id = 1
RETURNING *;
```

---

# Experiment 5 — SELECT FOR SHARE

Reset the lab.

## Session A

```sql
BEGIN;

SELECT *
FROM accounts
WHERE account_id = 1
FOR SHARE;
```

## Session B

A compatible shared lock:

```sql
BEGIN;

SELECT *
FROM accounts
WHERE account_id = 1
FOR SHARE;
```

End Session B's shared-lock transaction:

```sql
COMMIT;
```

Now try a conflicting update while Session A still holds its share lock:

```sql
SET lock_timeout = '3s';

UPDATE accounts
SET balance = balance + 10
WHERE account_id = 1;
```

Clean up:

```sql
ROLLBACK;
RESET lock_timeout;
```

## Session A

```sql
COMMIT;
```

---

# Inspect blocked sessions and locks

While Session B is blocked or waiting, use a third terminal from the repository root:

```bash
docker exec -i ds_course_postgres \
  psql -U app -d system_design \
  < labs/transactions-postgres/02_observe_locks.sql
```

The report includes:

- session PID and application name
- wait event
- blocking PIDs
- granted and ungranted locks
- relation and tuple metadata where exposed

---

# Experiment 6 — Lost update from stale application values

Reset the lab.

## Both sessions

```sql
SELECT stock, version
FROM inventory
WHERE product_id = 1;
```

Both clients have read `stock = 10` and independently calculate `9`.

## Session A

```sql
UPDATE inventory
SET stock = 9
WHERE product_id = 1;
```

## Session B

```sql
UPDATE inventory
SET stock = 9
WHERE product_id = 1;
```

Inspect the final row:

```sql
SELECT *
FROM inventory
WHERE product_id = 1;
```

---

# Experiment 7 — Optimistic version column

Reset the lab.

## Both sessions

```sql
SELECT stock, version
FROM inventory
WHERE product_id = 1;
```

Both clients see version 0.

## Session A

```sql
UPDATE inventory
SET stock = stock - 1,
    version = version + 1
WHERE product_id = 1
  AND version = 0
  AND stock > 0
RETURNING product_id, stock, version;
```

## Session B

```sql
UPDATE inventory
SET stock = stock - 1,
    version = version + 1
WHERE product_id = 1
  AND version = 0
  AND stock > 0
RETURNING product_id, stock, version;
```

One statement should return a row; the other should report zero updated rows.

---

# Experiment 8 — Atomic conditional update

Reset the lab.

Run once in each session:

```sql
UPDATE inventory
SET stock = stock - 1
WHERE product_id = 1
  AND stock > 0
RETURNING product_id, stock;
```

Inspect the final value:

```sql
SELECT * FROM inventory WHERE product_id = 1;
```

---

# Experiment 9 — Phantom-style predicate change

Reset the lab.

## Read Committed

### Session A

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;

SELECT count(*)
FROM bookings
WHERE room_id = 101
  AND status = 'active'
  AND starts_at >= '2026-07-01 00:00:00+00'
  AND starts_at <  '2026-07-02 00:00:00+00';
```

### Session B

```sql
INSERT INTO bookings (
    room_id,
    starts_at,
    ends_at,
    status
)
VALUES (
    101,
    '2026-07-01 16:00:00+00',
    '2026-07-01 17:00:00+00',
    'active'
);
```

### Session A

Repeat the count, then:

```sql
COMMIT;
```

## PostgreSQL Repeatable Read

Reset the lab and repeat the same steps, but Session A begins with:

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
```

---

# Experiment 10 — Write skew under Repeatable Read

Reset the lab.

## Session A

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT count(*) AS on_call_count
FROM doctors
WHERE on_call;

UPDATE doctors
SET on_call = false
WHERE doctor_name = 'alice';
```

Do not commit yet.

## Session B

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT count(*) AS on_call_count
FROM doctors
WHERE on_call;

UPDATE doctors
SET on_call = false
WHERE doctor_name = 'bob';
```

## Commit both

Session A:

```sql
COMMIT;
```

Session B:

```sql
COMMIT;
```

Inspect:

```sql
SELECT * FROM doctors ORDER BY doctor_name;
```

---

# Experiment 11 — Repeat write skew at Serializable

Reset the lab.

Repeat Experiment 10, replacing both `BEGIN` commands with:

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
```

Commit Session A and then Session B. One transaction should be rejected with a serialization failure.

After a serialization failure:

```sql
ROLLBACK;
```

A real application would rerun the complete failed transaction against a new snapshot.

---

# Experiment 12 — Deadlock

Reset the lab.

## Session A

```sql
BEGIN;

UPDATE accounts
SET balance = balance - 10
WHERE account_id = 1;
```

## Session B

```sql
BEGIN;

UPDATE accounts
SET balance = balance - 20
WHERE account_id = 2;
```

## Session A

This waits for Session B:

```sql
UPDATE accounts
SET balance = balance + 10
WHERE account_id = 2;
```

## Session B

This completes the cycle:

```sql
UPDATE accounts
SET balance = balance + 20
WHERE account_id = 1;
```

PostgreSQL detects the deadlock and aborts one transaction.

Clean up both sessions with either `COMMIT;` or `ROLLBACK;` as appropriate.

---

# Experiment 13 — Queue workers with SKIP LOCKED (optional)

Reset the lab.

## Session A

```sql
BEGIN;

SELECT job_id, payload
FROM queue_jobs
WHERE status = 'ready'
ORDER BY job_id
FOR UPDATE SKIP LOCKED
LIMIT 1;
```

Keep the transaction open.

## Session B

```sql
BEGIN;

SELECT job_id, payload
FROM queue_jobs
WHERE status = 'ready'
ORDER BY job_id
FOR UPDATE SKIP LOCKED
LIMIT 1;
```

Each session should receive a different job.

In each session, replace `$JOB_ID` with the selected ID:

```sql
UPDATE queue_jobs
SET status = 'running',
    worker_name = current_setting('application_name'),
    claimed_at = now()
WHERE job_id = $JOB_ID;

COMMIT;
```

Inspect the queue:

```sql
SELECT * FROM queue_jobs ORDER BY job_id;
```

---

# Stop PostgreSQL

When finished:

```bash
cd labs
docker compose down
```
