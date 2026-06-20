# Lesson 3 Questions — Transactions, Isolation, Locks, and Concurrency

Answer in:

```text
labs/transactions-postgres/answers_lab03.md
```

Preserve your predictions before running the experiments. You do not need to answer every optional question immediately.

---

## Part 1 — Mental model

### 1. Concurrent access

In your own words, explain the roles of:

- MVCC / row versions
- transaction snapshots
- the lock manager
- commit and rollback
- application retry logic

### 2. Locks vs latches

Distinguish a transaction lock from an internal database latch/mutex.

### 3. Isolation vs durability

Explain why stronger durability does not prevent concurrency anomalies, and why stronger isolation does not by itself guarantee crash durability.

### 4. Read and write locks

Explain the generic difference between a shared/read lock and an exclusive/write lock.

Then explain why an ordinary PostgreSQL `SELECT` is not the same as `SELECT ... FOR SHARE`.

### 5. Prediction: compatibility

Predict the result of each pair on the same row:

1. ordinary `SELECT` + `UPDATE`
2. `SELECT FOR SHARE` + another `SELECT FOR SHARE`
3. `SELECT FOR SHARE` + `UPDATE`
4. `SELECT FOR UPDATE` + `UPDATE`
5. `SELECT FOR UPDATE` + another `SELECT FOR UPDATE NOWAIT`

Use: proceeds, waits, or fails immediately.

---

## Part 2 — Isolation-level predictions

### 6. Read Committed

Session A reads one account balance. Session B updates and commits. Session A reads again in the same transaction.

Predict what Session A sees and explain the snapshot boundary.

### 7. Repeatable Read

Repeat the scenario at PostgreSQL Repeatable Read.

Predict the second value Session A sees.

### 8. Phantom prediction

Session A counts active bookings matching a date range. Session B inserts a matching booking and commits.

Predict the second count under:

- Read Committed
- PostgreSQL Repeatable Read

### 9. PostgreSQL-specific behavior

Why should you avoid assuming that an isolation-level name has exactly the same behavior in every database product?

---

## Part 3 — Run the snapshot and phantom labs

Follow the commands in:

```text
labs/transactions-postgres/README.md
```

### 10. Read Committed result

Record both values observed by Session A.

Explain whether this was a dirty read, nonrepeatable read, phantom, or none of those.

### 11. Repeatable Read result

Record both values observed by Session A.

Explain what changed relative to Read Committed.

### 12. Phantom result

Record the booking counts at both isolation levels.

State whether your predictions matched PostgreSQL’s behavior.

---

## Part 4 — Locking reads

### 13. Ordinary SELECT

Record whether Session B’s update was blocked while Session A held an open transaction after an ordinary `SELECT`.

Explain why.

### 14. FOR UPDATE

Record the outcome of Session B’s update while Session A held `SELECT ... FOR UPDATE`.

Include the lock-timeout behavior.

### 15. FOR SHARE

Record whether:

- another `FOR SHARE` succeeded
- an `UPDATE` succeeded, waited, or timed out

### 16. Lock inspection

Run `02_observe_locks.sql` while one session is blocked.

Record:

- blocked session/application name
- wait event
- whether its requested lock was granted
- blocking process ID(s)

### 17. Product choice

Give one workflow where a locking read is appropriate and one where it would be unnecessary or harmful.

---

## Part 5 — Lost updates and optimistic concurrency

### 18. Stale read-modify-write

Two clients read stock = 10, both calculate 9, and both later write 9.

Explain why this is a lost update even though the database never exposed uncommitted data.

### 19. Version-column result

Run the optimistic update from both sessions using `WHERE version = 0`.

Record:

- which update affected a row
- which update affected zero rows
- what the losing client should do next

### 20. Atomic SQL

Compare:

```sql
SELECT stock;
-- application calculates a value
UPDATE inventory SET stock = 9;
```

with:

```sql
UPDATE inventory
SET stock = stock - 1
WHERE stock > 0
RETURNING stock;
```

Explain why the second form closes an application-side race window.

### 21. Optimistic vs pessimistic

Choose one for each scenario and justify briefly:

1. editing a user profile
2. buying the last ticket
3. updating a rarely contested document
4. reserving scarce inventory during a traffic spike

---

## Part 6 — Write skew and Serializable

### 22. Repeatable Read write skew

Record the final on-call state after Alice and Bob each disable themselves in separate Repeatable Read transactions.

Explain why row-level write conflict detection did not protect the multi-row invariant.

### 23. Serializable result

Repeat at Serializable.

Record which transaction committed and which received a serialization failure.

### 24. Retry boundary

Explain why the application must retry the entire failed transaction rather than only its final `UPDATE` or `COMMIT` statement.

### 25. Alternative invariant designs

Give two other ways the “at least one doctor remains on call” rule might be protected besides Serializable.

Do not assume every alternative is equally convenient or scalable.

---

## Part 7 — Deadlocks

### 26. Deadlock trace

Record the sequence of locks/waits in the account-transfer deadlock.

Identify the cycle.

### 27. Database response

Record which session PostgreSQL aborted and what happened to the other session.

### 28. Lock ordering

Rewrite the two account transfers so both transactions acquire account locks in the same order.

Explain why this removes that particular cycle.

### 29. Retry design

Describe the properties of a safe deadlock retry loop:

- transaction boundary
- rollback behavior
- maximum attempts
- backoff/jitter
- idempotency

---

## Part 8 — Queue workers (optional)

### 30. SKIP LOCKED result

Run two queue workers with `FOR UPDATE SKIP LOCKED LIMIT 1`.

Record which job each session received.

### 31. Consistency tradeoff

Explain why `SKIP LOCKED` is suitable for independent work queues but not a general replacement for normal consistent reads.

---

## Part 9 — Database and cloud design

### 32. Last-ticket workflow

Design a short transaction for buying the final ticket. Include:

- transaction boundary
- lock or atomic condition
- payment boundary
- reservation expiry
- idempotency key
- retry behavior

### 33. Account transfer

Design an account transfer using two balance rows and a ledger entry. Include:

- constraints
- lock ordering
- transaction isolation
- audit/ledger write
- deadlock handling

### 34. Read replica trap

A request writes to the primary and immediately reads from an asynchronous replica.

Explain why transaction isolation on the primary does not guarantee read-your-writes from that replica.

### 35. Cloud failover

A client times out during `COMMIT` while a managed database fails over.

Explain why the client may not know whether the transaction committed and how idempotency helps.

### 36. Cross-service transaction

An order service writes Postgres, a payment provider charges a card, and a notification service sends email.

Explain why a local database transaction cannot make all three actions atomic. Name the broader patterns you would consider.

---

## Part 10 — Reflection

### 37. Decision table

Fill this in:

| Problem | Preferred first tool | Why | Main failure mode |
|---|---|---|---|
| single-row counter decrement |  |  |  |
| low-contention document edit |  |  |  |
| last scarce item |  |  |  |
| multi-row invariant |  |  |  |
| independent work queue |  |  |  |

### 38. Most important correction

Which belief about database concurrency changed or became more precise?

### 39. Remaining confusion

List anything you want clarified before moving on.

---

## Self-check

Before committing, confirm that you can explain:

- why ordinary PostgreSQL reads usually do not block writers
- statement snapshots vs transaction snapshots
- shared/read locks vs exclusive/write locks
- optimistic version checks vs pessimistic row locks
- lost update, phantom, write skew, and deadlock
- why Serializable requires retry handling
- why read-replica lag is not the same as transaction isolation
