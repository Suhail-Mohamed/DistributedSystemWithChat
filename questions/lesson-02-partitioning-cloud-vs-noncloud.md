# Lesson 2 Questions — Partitioning: Cloud vs Non-Cloud

Answer in:

```text
labs/partitioning-postgres/answers_lab02.md
```

Do not research the prediction section before running the lab. It is useful to preserve what you expected and compare it with what PostgreSQL actually did.

---

## Part 1 — Before the lab: predictions

### 1. Terminology

In your own words, distinguish:

- partitioning
- sharding
- replication
- partition pruning
- partition key
- hot partition

### 2. Predict the best first partitioning method

Choose **range**, **hash**, or **list** and briefly justify each choice:

1. Event logs queried and deleted by month.
2. Login sessions fetched by exact `user_id`.
3. Customer records separated by legal region.
4. Chat messages fetched by `conversation_id` and time.
5. Metrics where almost all writes go to the current hour.

### 3. Predict the PostgreSQL plans

Before running the SQL, predict which physical partitions should appear for:

1. `events_by_month` filtered to February.
2. `events_by_month` filtered only by `user_id`.
3. `events_by_user` filtered by one exact `user_id`.
4. `events_by_user` filtered to February.
5. `events_by_month` filtered by both February and one `user_id`.

---

## Part 2 — PostgreSQL range-partition lab

Run:

```bash
docker exec -i ds_course_postgres \
  psql -U app -d system_design \
  < labs/partitioning-postgres/01_setup.sql

docker exec -i ds_course_postgres \
  psql -U app -d system_design \
  < labs/partitioning-postgres/02_experiments.sql
```

### 4. Verify physical placement

Paste the row counts for each child table under `events_by_month`.

State whether inserts into the parent were routed where you expected.

### 5. Plain table vs range-partitioned table

For the narrow February query:

- Record the important relation names from each plan.
- Note whether all child partitions or only one child partition appeared.
- Compare buffers and execution time, but do not rely only on timing.
- Explain the strongest evidence that pruning occurred or did not occur.

### 6. Disable pruning

Compare the range-partitioned query with:

```sql
SET enable_partition_pruning = off;
```

Record what changed in the plan.

### 7. Query that does not use the partition key

Run the `user_id`-only query against `events_by_month`.

Record how many monthly partitions PostgreSQL considered and explain why the monthly layout could not eliminate most partitions.

### 8. Indexes plus partitions

After the index creation section:

- Record whether PostgreSQL used an index, a sequential scan, or another path.
- Explain the different jobs performed by partition pruning and an index.
- State whether the index made the partition key irrelevant.

### 9. Retention operation

Describe what happened when January was detached inside the transaction.

Explain why detach/drop can be operationally attractive for retention compared with deleting every January row.

---

## Part 3 — PostgreSQL hash-partition lab

### 10. Exact user lookup

For a single `user_id`, record which hash partition appeared in the plan.

State whether the result matched your prediction.

### 11. Date-range query on the hash table

Record how many hash partitions appeared for a February-only query.

Explain why hashing by user helps one query shape and hurts another.

### 12. Combined predicate

For `user_id` plus a February date range:

- Which condition enabled partition pruning?
- Which condition was applied inside the selected partition?
- Did an index change the result?

### 13. Range vs hash conclusion

Give one workload where you would choose the range-partitioned table and one where you would choose the hash-partitioned table.

---

## Part 4 — Hot-partition simulator

Run:

```bash
python labs/partitioning-postgres/hot_partition_sim.py
```

### 14. Uniform workload

Record:

- busiest partition
- busiest partition’s traffic share
- max/min partition ratio

### 15. One hot key

Record the same metrics for the skewed workload.

Explain why increasing the number of partitions would not automatically split one unchanged hot key.

### 16. Write sharding / salting

Record what changed when the hot key was split into multiple salted keys.

State one benefit and one new read-side or aggregation-side cost.

---

## Part 5 — Cloud comparison

### 17. Fill the comparison table

| System | Who chooses the partition boundaries? | Routing/pruning mechanism | Main hotspot risk | Rebalancing responsibility |
|---|---|---|---|---|
| PostgreSQL declarative partitions |  |  |  |  |
| Parquet files in object storage |  |  |  |  |
| Snowflake micro-partitions |  |  |  |  |
| DynamoDB-style partition key |  |  |  |  |
| Application-sharded relational DB |  |  |  |  |

### 18. Cloud vs non-cloud

Explain what a managed cloud service can hide from the application and what it **cannot** hide about poor key choice or skew.

### 19. Snowflake vs PostgreSQL

Explain why Snowflake micro-partitions should not be treated as identical to manually defined PostgreSQL partitions.

### 20. Parquet folder partition vs distributed shard

Explain why `day=2026-06-01/` in object storage is not automatically a database shard.

---

## Part 6 — DDIA-style design analysis

For each scenario, cover:

1. partition key or rule
2. placement
3. request routing
4. expected skew/hotspots
5. rebalancing
6. secondary-index or alternate-query impact

### 21. Multi-tenant audit log

Requirements:

- append-heavy
- most queries are one tenant plus a time range
- one tenant creates 40% of all events
- retain seven years
- recent 90 days queried most often

### 22. Group chat

Requirements:

- fetch messages by conversation in time order
- ordinary chats are small
- one livestream chat produces millions of messages per hour
- users search their own message history

### 23. Online store orders

Requirements:

- direct lookup by `order_id`
- “my orders” by `customer_id`
- daily revenue reporting
- order writes require strong transactional correctness

### 24. Design failure

Describe a partitioning design that looks evenly distributed in a small test but fails under production skew.

---

## Part 7 — Reflection

### 25. Most important correction

Which belief did the experiments change or make more precise?

### 26. Remaining confusion

List anything you want clarified before Lesson 3.

---

## Self-check

Before committing your answers, confirm that you can explain:

- why partitioning is not the same as sharding
- why pruning depends on query predicates
- why partitioning and indexes can work together
- why hash distribution does not solve one hot key
- why every distributed partition design needs routing and rebalancing
