# Cloud Storage and Cloud Databases

## Things I learned

Write the key ideas in your own words:

- OLTP vs OLAP
- row-oriented vs column-oriented storage
- object storage
- compute/storage separation
- micro-partitions or row groups
- pruning
- warehouse/compute sizing
- cloud metadata/control layer

## Predictions

### Query A vs Query B

Which should be cheaper in a columnar system?

```sql
SELECT *
FROM events
WHERE event_date = '2025-06-01';
```

```sql
SELECT country, count(*)
FROM events
WHERE event_date = '2025-06-01'
GROUP BY country;
```

My prediction:


### Sorted vs unsorted layout

Which should be faster for date filters?

My prediction:


### Cloud warehouse indexing

Why might a Snowflake-style warehouse not use the same index strategy as an OLTP database?

My answer:


## Lab setup

Record:

- DuckDB version:
- number of rows generated:
- file sizes:
  - unsorted Parquet:
  - sorted Parquet:

## Query results

### Query 1: SELECT * with date filter

Plan notes:

Runtime:

Observation:


### Query 2: selected columns with date filter and aggregation

Plan notes:

Runtime:

Observation:


### Query 3: unsorted Parquet with date filter

Plan notes:

Runtime:

Observation:


### Query 4: sorted Parquet with date filter

Plan notes:

Runtime:

Observation:


### Query 5: filter that does not match sort order

Plan notes:

Runtime:

Observation:


## Explanation

Explain what happened using these concepts:

- column pruning
- row-group or micro-partition pruning
- metadata
- data layout
- selective filters
- aggregation

## Design drill answer

Design the analytical storage layer for an app that tracks product events.

Requirements:

- app receives 20,000 events per second
- events are queried by date, tenant, event type, country, and product id
- dashboards need daily and hourly aggregates
- raw events must be retained for one year
- product managers run ad hoc queries
- some tenants are much larger than others
- cost matters

### Source of truth for raw events


### Landing path


### Storage format


### Partitioning / clustering / layout


### Pre-aggregations


### Raw queries vs aggregate queries


### Workload isolation


### Metrics to monitor


### Main cost risk


### What changes if this is OLTP instead of analytics?


## Questions I still have

-
