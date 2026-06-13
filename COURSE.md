# Database-Forward System Design Course

## Course direction

This course is system design taught through a database and data architecture lens.

It is not a database-from-scratch course. We will use database concepts to understand real systems: cloud data warehouses, partitioning, sharding, query plans, locking, streams, caching, read models, search, queues, and cloud deployment tradeoffs.

Each lesson is centered on one concrete system-design topic, inspired by practical system-design prompts and real products.

## Lesson format

Every lesson follows the same structure:

1. **Topic** — one product/system-design topic.
2. **What you should know first** — vocabulary, mental model, and core tradeoffs.
3. **Technology touchpoint** — a concrete technology to try or inspect.
4. **Predict** — you answer what you expect will happen.
5. **Run or reason** — you run a small lab or work through a design scenario.
6. **Observe** — you record what actually happened.
7. **Explain** — you connect the result back to database/system-design concepts.
8. **Design drill** — you apply the concept to a product system.
9. **Verification** — you paste your answer/results in chat, and I review it.

The goal is active practice, not passive reading.

## Verification style

For most lessons, you should produce at least one of:

- a short design doc
- a query plan
- a benchmark or measurement
- a diagram
- a table of tradeoffs
- a failure-mode analysis
- a revised answer after critique

I will verify your work by checking:

- whether the design follows the access patterns
- whether the technology choice matches the workload
- whether the consistency assumptions are clear
- whether the partitioning/sharding strategy is realistic
- whether the failure modes are handled
- whether the cloud deployment plan is believable

## Technology stack

Core tools:

- PostgreSQL
- Redis
- Kafka or Redpanda
- DuckDB
- Parquet files
- optional: Snowflake trial or sample environment
- optional: DynamoDB local or AWS DynamoDB
- optional: OpenSearch/Elasticsearch

Cloud concepts will be included lightly but consistently:

- regions
- availability zones
- object storage
- managed databases
- managed streams
- queues
- serverless functions
- read replicas
- backups
- disaster recovery
- observability
- cost tradeoffs

## Topic roadmap

### 1. Cloud storage fundamentals and cloud database architecture

Main systems:

- Snowflake-style cloud data warehouse
- object storage
- DuckDB + Parquet as a local learning tool

Concepts:

- separation of storage and compute
- columnar storage
- object storage
- micro-partitions / row groups
- pruning
- cloud services / metadata layer
- warehouse sizing
- OLTP vs OLAP

Deliverable:

- `design-docs/01-cloud-storage-and-cloud-databases.md`

### 2. Partitioning data: cloud vs non-cloud

Main systems:

- PostgreSQL partitioning
- DynamoDB partition keys
- Snowflake micro-partitioning
- Cassandra partition keys

Concepts:

- range partitioning
- hash partitioning
- time partitioning
- tenant partitioning
- hot partitions
- cloud-managed automatic partitioning
- application-level sharding

Deliverable:

- `design-docs/02-partitioning-cloud-vs-non-cloud.md`

### 3. Query plans and query optimization

Main system:

- PostgreSQL

Concepts:

- sequential scan
- index scan
- bitmap scan
- nested loop join
- hash join
- merge join
- cardinality estimates
- stale statistics
- composite indexes
- covering indexes
- partial indexes

Deliverable:

- `design-docs/03-query-plans-and-optimization.md`

### 4. Locking, isolation, and phantoms

Main system:

- PostgreSQL

Concepts:

- optimistic locking
- pessimistic locking
- row locks
- table locks
- MVCC
- isolation levels
- non-repeatable reads
- phantom reads
- write skew
- deadlocks
- transaction retries

Deliverable:

- `design-docs/04-locking-isolation-phantoms.md`

### 5. Rate limiter

Main systems:

- Redis
- PostgreSQL as correctness fallback
- optional DynamoDB conditional writes

Concepts:

- token bucket
- leaky bucket
- fixed window
- sliding window
- sorted sets
- TTLs
- hot keys
- atomic operations
- cache cluster placement

Deliverable:

- `design-docs/05-rate-limiter.md`

### 6. URL shortener / Pastebin

Main systems:

- PostgreSQL
- Redis
- object storage for large payloads

Concepts:

- key generation
- uniqueness
- read-heavy scaling
- cache-aside
- TTLs
- data retention
- abuse/rate limits
- shard key choice

Deliverable:

- `design-docs/06-url-shortener-or-pastebin.md`

### 7. Streams and event-driven systems

Main systems:

- Kafka or Redpanda
- PostgreSQL outbox pattern

Concepts:

- topics
- partitions
- partition keys
- consumer groups
- offsets
- replay
- at-least-once delivery
- idempotent consumers
- dead-letter queues
- backfills

Deliverable:

- `design-docs/07-streams-and-outbox.md`

### 8. Ticketmaster / inventory correctness

Main systems:

- PostgreSQL
- Redis
- queue or stream

Concepts:

- pessimistic locking
- optimistic retries
- reservations
- idempotency keys
- payment state machines
- queues for traffic shaping
- hot events
- fairness vs throughput

Deliverable:

- `design-docs/08-ticketing-inventory.md`

### 9. Search and derived read models

Main systems:

- PostgreSQL
- OpenSearch/Elasticsearch
- Redis

Concepts:

- source of truth
- search index as derived data
- materialized views
- denormalization
- consistency lag
- reindexing
- reconciliation jobs

Deliverable:

- `design-docs/09-search-and-derived-data.md`

### 10. Social feed or notifications

Main systems:

- PostgreSQL
- Redis
- Kafka/Redpanda
- optional Cassandra/DynamoDB-style design

Concepts:

- fanout-on-write
- fanout-on-read
- unread counts
- hot users
- celebrity problem
- timeline ranking
- eventual consistency
- partitioning by user/time

Deliverable:

- `design-docs/10-feed-or-notifications.md`

### 11. Analytics pipeline / ad click aggregator / unique active users

Main systems:

- Kafka/Redpanda
- object storage
- DuckDB/Snowflake-style warehouse
- Redis for approximate real-time counters

Concepts:

- event ingestion
- stream partitions
- batch vs streaming
- late events
- deduplication
- approximate counting
- data warehouse modeling
- cost-aware queries

Deliverable:

- `design-docs/11-analytics-pipeline.md`

### 12. Capstone

Pick one:

- notification platform
- ticketing platform
- analytics pipeline
- chat system

The capstone must include:

- requirements
- access patterns
- data model
- indexes
- partitioning/sharding plan
- locking/correctness plan
- stream/event flow
- cache/read-model strategy
- cloud architecture
- observability
- failure modes
- cost concerns

## References to use during the course

Use references lightly. The course is practice-first.

- Snowflake architecture and key concepts
- Snowflake micro-partitions and clustering
- PostgreSQL EXPLAIN documentation
- PostgreSQL explicit locking documentation
- AWS DynamoDB partition-key design documentation
- Kafka documentation
- Redis Cluster documentation
- Cassandra data modeling documentation
