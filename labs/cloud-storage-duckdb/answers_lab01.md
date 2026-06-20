Which query is slowest?
  - group_by_country_event_type - it seems to be accessing multiple columns at the sametime which for columnar storage is not ideal.

EXPLAIN ANALYZE SELECT count(*) FROM read_parquet('data/events/**/*.parquet');
┌────────────────────────────────────────────────┐
│┌──────────────────────────────────────────────┐│
││              Total Time: 0.0039s             ││
│└──────────────────────────────────────────────┘│
└────────────────────────────────────────────────┘

EXPLAIN ANALYZE  SELECT count(*) FROM read_parquet('data/events/**/*.parquet') WHERE day = '2026-06-05';
┌────────────────────────────────────────────────┐
│┌──────────────────────────────────────────────┐│
││              Total Time: 0.0014s             ││
│└──────────────────────────────────────────────┘│
└────────────────────────────────────────────────┘

EXPLAIN ANALYZE
SELECT country, event_type, count(*) AS events FROM read_parquet('data/events/**/*.parquet') WHERE country = 'CA' GROUP BY country, event_type ORDER BY event_type 
┌────────────────────────────────────────────────┐
│┌──────────────────────────────────────────────┐│
││              Total Time: 0.0090s             ││
│└──────────────────────────────────────────────┘│
└────────────────────────────────────────────────┘

Which query appears to read less?
  - filter_by_day

Does filtering on day help?
  - Yes, the day column the most compressed column we have so it makes sense why
    it is easiest to process. I am also assuming the metadata parquet makes it easy
    to determine number of elements in a page, with the metadata field num_values

How would results change if the data were one huge CSV?
  - We would be processing each row at a time
  - We would have no parquet compression
  - queries would all take the same time


What does this teach you about warehouse storage design?
  - In practice these parquet files would be on something like s3 and
    duckdb would be reading these from a compute node, seperate from 
    the data. In something like AWS EC2, this seperation of storage and
    compute allows us to have more dynamic load bearing, meaning during 
    times of low traffic compute nodes can be shutdown. During times of
    high activity compute nodes can startup and modify data as need be.
    dynamic scale up / scale down.

Why might directory layout help a query engine skip work?
  - We can partition on something like date, and if a query references
    date we can send this query to process on a subset of data. This subset
    is dependent on our partitioning.

Why is this different from a B-tree index?
  - Both limit a queries area of search to a subset of data. But I would say overall
    they are quite different. As a B+-tree can be applied to a table which is partitioned.
    So you can have both partitioned data and B+tree. Which is why I think there is a 
    similiarity but not that much...

What is similar between Parquet file skipping and Snowflake micro-partition pruning?
  - they are both paritioning data to make searching faster. 

Why is this better for analytics than for OLTP writes?
  - Why is partitioning better for OLAP? Because it is often dealing with larger queries
    where we have to analyze a large amount of data (at once). OLTP can benefit from partitioning
    as well. I actually think both workloads benefit from partitioning...

You are designing a video app. For each piece of data, decide whether it belongs in a database, object storage, a stream, or a derived warehouse table.
- Video File -> home: object storage, Why: videos are large unorganized data, likely can be held in a blob object. Because video files are rarely updated
  it is beneficial for it to be held there 

- Thumbnail -> home: a database, Why: thumbnails are often accessed and likely need quick retrieval. Additionally the meta-data sorrounding a thumbnail often
  needs to be fetched together with it. So I would specifically say a OLTP database is most ideal for a thumbnail.
  (all of these should be held in the same table as the thumbnail)
  - Title and description -> database.
  - Daily view count -> database
  - Comments -> database (likely in a different table though)

- Raw watch events -> home: stream. I am assuming these are likes / reactions info. Maybe stream can feed this info into analytics algorithm to either 


Question B: 5 billion click events

A product team wants to analyze 5 billion click events. They need cheap raw storage, daily aggregation, ad hoc analyst queries, no impact on the production app, and backfills. Design the source of truth, ingestion path, storage format, compute engine, partitioning/clustering strategy, cost risk, and failure mode.
Question C: database choice


Choose among Postgres, Snowflake-style warehouse, object storage + query engine, DynamoDB-style KV/document, Kafka/Kinesis-style stream, Redis, or search index for these workloads:

    user login sessions -> 
    order checkout -> postgres
    raw clickstream events -> kafka
    monthly revenue dashboard -> snowflake
    product search -> 
    image uploads -> KV?
    notification badge count ->


