# Lesson 1: Cloud Storage Fundamentals and Cloud Database Architecture

## Topic

Cloud storage fundamentals and the architecture of cloud databases, using Snowflake-style cloud data warehouses as the reference model.

This lesson is about understanding why modern analytical databases look different from traditional single-node or self-hosted databases.

## Why this topic comes first

A lot of system design eventually touches cloud storage:

- event logs land in object storage
- analytics systems scan Parquet files
- data warehouses separate compute from storage
- cloud databases hide partition management from you
- cost depends on bytes scanned, compute time, and storage layout
- query speed depends heavily on pruning and layout

Before we talk about sharding, streams, or query optimization, you should understand the cloud data architecture that many systems feed into.

## Things you should know

### OLTP vs OLAP

OLTP systems are optimized for application transactions.

Examples:

- create order
- mark notification as read
- reserve ticket
- update account profile

Typical OLTP traits:

- many small reads/writes
- low latency
- indexes matter a lot
- transactions matter a lot
- row-level updates matter

OLAP systems are optimized for analytical queries.

Examples:

- count daily active users
- aggregate ad clicks by country
- compute revenue by product category
- scan a year of events

Typical OLAP traits:

- large scans
- aggregations
- columnar storage
- fewer row-by-row updates
- batch or streaming ingestion
- storage layout matters a lot

### Row-oriented vs column-oriented storage

Row-oriented storage is good when you often need many columns from a small number of rows.

Column-oriented storage is good when you often need a few columns from many rows.

Example:

```sql
SELECT country, count(*)
FROM events
WHERE event_date = '2025-06-01'
GROUP BY country;
```

A columnar system can avoid reading unrelated columns like `user_agent`, `raw_payload`, or `debug_metadata`.

### Object storage

Object storage is cloud storage for files/objects rather than database pages.

Examples:

- Amazon S3
- Google Cloud Storage
- Azure Blob Storage

Common uses:

- raw event logs
- Parquet files
- data lake tables
- backups
- exported query results
- archived data
- media files

Object storage is usually cheap and durable, but it is not the same thing as a low-latency transactional database.

### Compute/storage separation

In many cloud analytical systems, storage and compute scale separately.

Storage layer:

- stores compressed columnar data
- often backed by object storage
- persists independently of compute clusters

Compute layer:

- runs queries
- can scale up/down
- may be isolated per workload/team
- can often be paused/resumed

Metadata/control layer:

- tracks tables, schemas, files, partitions, statistics, permissions, query optimization, and coordination

### Micro-partitions / row groups

Cloud warehouses and lakehouse engines often divide table data into smaller chunks.

Names differ by technology:

- Snowflake: micro-partitions
- Parquet: row groups
- BigQuery: storage blocks/partitions/clustering concepts
- data lakes: files, manifests, partitions, row groups

These chunks usually store metadata such as min/max values for columns. Query engines can use this metadata to skip chunks that cannot match a filter.

This is called pruning.

### Pruning

Pruning means the engine avoids scanning data that cannot possibly match the query.

Example:

If a chunk has:

```text
min_event_date = 2025-01-01
max_event_date = 2025-01-31
```

Then this query can skip it:

```sql
SELECT count(*)
FROM events
WHERE event_date = '2025-06-01';
```

The database-forward lesson:

> Cloud warehouses often do not need traditional application-style indexes for every query. They rely heavily on columnar layout, metadata, pruning, clustering, and large-scale parallel scan.

## Mental model

A simplified Snowflake-like architecture:

```text
Client / BI Tool
      |
      v
Cloud services layer
  - auth
  - metadata
  - query optimization
  - coordination
      |
      v
Virtual warehouse / compute cluster
  - scans data
  - joins
  - aggregates
  - sorts
      |
      v
Cloud storage
  - compressed columnar table data
  - micro-partitions / files
  - metadata
```

Important difference from a normal app database:

```text
Postgres OLTP:
  app -> database process -> buffer pool -> indexes/pages -> disk

Snowflake-style OLAP:
  client -> cloud services -> elastic compute -> cloud storage chunks
```

## Technology touchpoint

You will use DuckDB + Parquet locally to simulate several cloud warehouse ideas without needing a paid cloud account.

Optional extension:

- Use Snowflake if you have access to a trial or existing account.
- Compare the local DuckDB/Parquet behavior with Snowflake Query Profile and warehouse sizing.

## Lab

Go to:

```text
labs/01-cloud-storage-and-cloud-databases/README.md
```

You will create synthetic event data, write it to Parquet, and test how sorted vs unsorted layout affects filtered analytical queries.

## Predict before running

Before the lab, answer these.

### Question 1

You have a 500 GB event table with 80 columns.

Query A:

```sql
SELECT *
FROM events
WHERE event_date = '2025-06-01';
```

Query B:

```sql
SELECT country, count(*)
FROM events
WHERE event_date = '2025-06-01'
GROUP BY country;
```

Which query should be cheaper in a columnar analytical system, and why?

### Question 2

Suppose the same data is stored two ways:

1. randomly ordered
2. sorted by `event_date`

Which layout should make date filters faster, and why?

### Question 3

In a traditional OLTP database, you might add this index:

```sql
CREATE INDEX ON events (event_date);
```

Why might a cloud warehouse not rely on the same kind of index strategy?

### Question 4

A team says:

> Snowflake is fast because it is just S3 plus SQL.

What is incomplete or misleading about that statement?

### Question 5

A team runs every dashboard query on the same warehouse/compute cluster.

What performance or cost problems might happen?

## Run-and-observe questions

After the lab, answer these.

### Question 6

What happened when you queried only a few columns versus all columns?

### Question 7

What happened when you filtered by a date on sorted Parquet versus unsorted Parquet?

### Question 8

Did the query engine scan all data, or did it appear to prune/skip some data?

### Question 9

What information did `EXPLAIN` or `EXPLAIN ANALYZE` show you?

### Question 10

How is this different from reading a query plan in PostgreSQL?

## Design drill

Design the analytical storage layer for an app that tracks product events.

Requirements:

- app receives 20,000 events per second
- events are queried by date, tenant, event type, country, and product id
- dashboards need daily and hourly aggregates
- raw events must be retained for one year
- product managers run ad hoc queries
- some tenants are much larger than others
- cost matters

Answer:

1. What is the source of truth for raw events?
2. Where do raw events land first?
3. What file/table format would you use?
4. How would you partition or cluster the data?
5. What pre-aggregations would you build?
6. What queries should hit raw events vs aggregates?
7. How would you prevent one team from slowing down another team?
8. What metrics would you monitor?
9. What is the main cost risk?
10. What would you do differently if this were an OLTP product feature instead of analytics?

## Deliverable

Create:

```text
design-docs/01-cloud-storage-and-cloud-databases.md
```

Use this structure:

```md
# Cloud Storage and Cloud Databases

## Things I learned

## Predictions

## Lab observations

## Explanation

## Design drill answer

## Questions I still have
```

## Expected takeaways

By the end of this lesson, you should be able to explain:

- why analytical cloud databases separate compute and storage
- why columnar storage helps analytical scans
- what pruning means
- why data layout affects query performance
- why warehouse sizing and isolation matter
- how cloud analytical databases differ from OLTP databases
- why object storage is useful but not sufficient by itself

## Reference anchors

You do not need to deeply read these yet, but these are the official concepts this lesson is based on:

- Snowflake key concepts and architecture
- Snowflake micro-partitions and data clustering
- PostgreSQL EXPLAIN docs, for contrast with OLTP query plans
