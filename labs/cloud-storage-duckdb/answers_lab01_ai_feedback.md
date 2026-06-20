# Lab 01 — concise AI feedback

Which query is slowest?
(AI-answer: The group-by query. It does filtering, grouping, counting, and ordering; reading multiple needed columns is not itself bad for columnar storage.)

Which query appears to read less?
(AI-answer: The day-filter query. It can likely skip unrelated day folders/files.)

Does filtering on day help?
(AI-answer: Yes, mainly because the directory layout is partitioned by day. Compression helps, but skipping files/folders is the bigger point.)

How would results change if the data were one huge CSV?
(AI-answer: CSV would likely be slower because it lacks columnar layout, typed binary encoding, row-group stats, and efficient column pruning. Not all queries would be exactly the same time.)

What does this teach you about warehouse storage design?
(AI-answer: Store data cheaply/durably in files or object storage, then scale compute separately for scans, transforms, aggregations, and derived tables.)

Why might directory layout help a query engine skip work?
(AI-answer: If filters match folder partitions, such as `day=...`, the engine can ignore unrelated folders/files.)

Why is this different from a B-tree index?
(AI-answer: A B-tree is a row/key lookup structure. Parquet pruning is coarser: it skips files, row groups, or columns using layout and metadata.)

What is similar between Parquet file skipping and Snowflake micro-partition pruning?
(AI-answer: Both use metadata about data chunks to skip chunks that cannot match the query filter.)

Why is this better for analytics than for OLTP writes?
(AI-answer: Parquet/warehouse layouts favor batch writes, large scans, column pruning, compression, and aggregations. OLTP needs tiny row updates, transactions, and low-latency point reads.)

Video file
(AI-answer: Object storage/CDN for video bytes; database for metadata and object URLs.)

Thumbnail
(AI-answer: Object storage/CDN for thumbnail image bytes; database for thumbnail metadata, URL, dimensions, and status.)

Title and description
(AI-answer: Database. This is core app metadata.)

Daily view count
(AI-answer: Current count can be DB/cache; historical daily counts often belong in a derived warehouse table.)

Comments
(AI-answer: Database, usually a separate indexed table/service.)

Raw watch events
(AI-answer: Stream for ingestion; object storage/warehouse for long-term analytics. Examples include starts, pauses, progress, completions, and buffering events.)

Question B: 5 billion click events
(AI-answer: App emits events to Kafka/Kinesis; raw events land in object storage as Parquet partitioned by date/hour and maybe tenant; warehouse/query engine handles ad hoc queries and daily aggregates; risks are duplicate/lost events, late data, bad partitioning, and costly full scans.)

user login sessions
(AI-answer: Redis for short-lived fast sessions; DynamoDB-style KV for durable/global managed sessions.)

order checkout
(AI-answer: Postgres. Needs transactions, constraints, idempotency, and a strong source of truth.)

raw clickstream events
(AI-answer: Kafka/Kinesis for ingestion; object storage/warehouse for long-term analytics.)

monthly revenue dashboard
(AI-answer: Snowflake-style warehouse or derived aggregate tables.)

product search
(AI-answer: Search index, with source of truth usually still in Postgres or another primary database.)

image uploads
(AI-answer: Object storage/CDN for image bytes; database or document store for metadata.)

notification badge count
(AI-answer: Redis/cache or DB counter for fast reads; notification/read-state database remains source of truth.)
