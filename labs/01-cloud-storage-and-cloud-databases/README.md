# Lab 1: Cloud Storage and Cloud Database Architecture

## Goal

Use DuckDB and Parquet locally to understand ideas used by cloud analytical databases:

- columnar storage
- file/row-group metadata
- pruning
- data layout
- sorted vs unsorted analytical data
- why `SELECT *` can be more expensive than selecting a few columns

This lab is not Snowflake, but it gives you a small version of the same mental model:

```text
SQL engine -> columnar files -> metadata/pruning -> scan only what is needed
```

## Requirements

Install DuckDB CLI or use Python.

Python option:

```bash
python -m venv .venv
source .venv/bin/activate
pip install duckdb
```

Windows PowerShell:

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install duckdb
```

## Step 1: Create synthetic event data

Run this from this lab directory:

```bash
python create_events.py
```

If the script does not exist yet, create it with this content:

```python
import duckdb
from pathlib import Path

out = Path("data")
out.mkdir(exist_ok=True)

con = duckdb.connect()

rows = 2_000_000

con.execute(f"""
CREATE OR REPLACE TABLE events AS
SELECT
  i AS event_id,
  CAST(1 + (i % 1000) AS INTEGER) AS tenant_id,
  CAST(1 + (i % 200000) AS INTEGER) AS user_id,
  DATE '2025-01-01' + CAST(i % 365 AS INTEGER) AS event_date,
  TIMESTAMP '2025-01-01 00:00:00' + CAST(i AS BIGINT) * INTERVAL '1 second' AS created_at,
  CASE i % 5
    WHEN 0 THEN 'page_view'
    WHEN 1 THEN 'click'
    WHEN 2 THEN 'purchase'
    WHEN 3 THEN 'signup'
    ELSE 'logout'
  END AS event_type,
  CASE i % 6
    WHEN 0 THEN 'US'
    WHEN 1 THEN 'CA'
    WHEN 2 THEN 'GB'
    WHEN 3 THEN 'DE'
    WHEN 4 THEN 'IN'
    ELSE 'BR'
  END AS country,
  CAST(i % 10000 AS INTEGER) AS product_id,
  CAST((i % 100000) / 100.0 AS DOUBLE) AS amount,
  repeat('x', 200) AS raw_payload
FROM range({rows}) t(i);
""")

con.execute("""
COPY events
TO 'data/events_unsorted.parquet'
(FORMAT PARQUET, ROW_GROUP_SIZE 100000);
""")

con.execute("""
COPY (
  SELECT *
  FROM events
  ORDER BY event_date, tenant_id, event_type
)
TO 'data/events_sorted.parquet'
(FORMAT PARQUET, ROW_GROUP_SIZE 100000);
""")

print('Created: data/events_unsorted.parquet')
print('Created: data/events_sorted.parquet')
```

Then run:

```bash
python create_events.py
```

## Step 2: Open DuckDB

```bash
duckdb
```

If you are using Python instead of the CLI, you can run the SQL statements through `duckdb.connect().execute(...)`.

## Step 3: Compare selecting all columns vs a few columns

Run:

```sql
EXPLAIN ANALYZE
SELECT *
FROM read_parquet('data/events_sorted.parquet')
WHERE event_date = DATE '2025-06-01';
```

Then run:

```sql
EXPLAIN ANALYZE
SELECT country, count(*)
FROM read_parquet('data/events_sorted.parquet')
WHERE event_date = DATE '2025-06-01'
GROUP BY country;
```

Record:

- total time
- columns scanned, if visible
- number of rows returned
- anything the plan says about filters

Question:

Why should the second query usually be cheaper in a columnar system?

## Step 4: Compare sorted vs unsorted layout

Run:

```sql
EXPLAIN ANALYZE
SELECT country, count(*)
FROM read_parquet('data/events_unsorted.parquet')
WHERE event_date = DATE '2025-06-01'
GROUP BY country;
```

Then:

```sql
EXPLAIN ANALYZE
SELECT country, count(*)
FROM read_parquet('data/events_sorted.parquet')
WHERE event_date = DATE '2025-06-01'
GROUP BY country;
```

Record:

- which query was faster
- whether the difference was large or small
- whether the plan suggests filtering/pruning

Question:

Why can sorted layout help a query engine skip more data?

## Step 5: Try a filter that does not match the sort order

Run:

```sql
EXPLAIN ANALYZE
SELECT event_type, count(*)
FROM read_parquet('data/events_sorted.parquet')
WHERE product_id = 1234
GROUP BY event_type;
```

Question:

Why might sorting by `event_date, tenant_id, event_type` help date filters more than product filters?

## Step 6: Try an aggregate without a selective filter

Run:

```sql
EXPLAIN ANALYZE
SELECT country, count(*), sum(amount)
FROM read_parquet('data/events_sorted.parquet')
GROUP BY country;
```

Question:

Why does this still need to scan a lot of data?

## Step 7: Connect to system design

Answer these in your lab notes:

1. What does this lab teach about Snowflake-style micro-partitions?
2. Why is object storage useful for analytics but not enough by itself?
3. Why does data layout matter if there is no traditional B-tree index?
4. When would you pre-aggregate instead of querying raw events?
5. What could go wrong if one dashboard query scans a huge table every minute?
6. What would you monitor in production?

## Optional Snowflake version

If you have Snowflake access:

1. Load similar event data into a Snowflake table.
2. Run a date-filtered query.
3. Open Query Profile.
4. Look for partitions scanned vs partitions total.
5. Resize the virtual warehouse and rerun.
6. Compare runtime and credit/cost implications.

Questions:

1. Did resizing compute improve the query?
2. Did the query scan fewer partitions after changing data layout or clustering?
3. What does Snowflake hide from you compared with managing Parquet files yourself?
4. What costs become easier to accidentally create?

## Deliverable

Create:

```text
design-docs/01-cloud-storage-and-cloud-databases.md
```

Include:

```md
# Cloud Storage and Cloud Databases

## Predictions

## Lab setup

## Query results

## Observations

## Explanation

## Design drill answer

## Questions I still have
```
