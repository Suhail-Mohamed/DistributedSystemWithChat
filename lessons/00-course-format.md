# Course Format

## One lesson = one topic

Each lesson focuses on one system-design topic. The topic can come from practical system-design prompts such as rate limiters, URL shorteners, Ticketmaster-style inventory, social feeds, search systems, analytics pipelines, Kafka systems, cloud databases, or distributed locking.

The lesson does not start with a finished architecture. It starts with the data.

## The pattern

### 1. Things you should know

This section gives the vocabulary and mental models needed for the topic.

Example for query plans:

- sequential scan
- index scan
- nested loop join
- hash join
- cardinality estimate
- cost estimate
- statistics

### 2. Questions before technology

You answer product and workload questions first.

Example:

- What are the top reads?
- What are the top writes?
- Which queries are latency-sensitive?
- Which writes require correctness?
- What can be eventually consistent?
- How large is the data?
- What is the growth rate?

### 3. Technology touchpoint

Every lesson should touch a real technology.

Examples:

- PostgreSQL for query plans and locking
- Redis for rate limiters and caches
- Kafka/Redpanda for streams
- DuckDB + Parquet for cloud warehouse concepts
- DynamoDB for partition-key design
- OpenSearch for search/read models
- Snowflake as the cloud data warehouse architecture reference

### 4. Predict, run, observe, explain

Before running an experiment, write what you expect.

Then run the lab or reason through the design.

Then explain what happened and why.

The key habit:

> Do not just learn that a technology exists. Learn what behavior it produces under different workloads.

### 5. Design drill

After the lab, apply the concept to a product/system-design problem.

Example:

- Design a rate limiter.
- Design cloud storage for analytics events.
- Design Ticketmaster inventory reservation.
- Design search for a marketplace.
- Design a Kafka-backed notification pipeline.

### 6. Verification

You paste your answer/results in chat.

I review:

- what is correct
- what is shaky
- what assumptions are missing
- what would break at scale
- what tradeoffs you ignored
- what to revise

## Deliverable template

Use this structure for design-doc answers:

```md
# Topic Name

## Requirements

## Access patterns

## Data model

## Technology choices

## Indexing / partitioning / key design

## Read path

## Write path

## Consistency and correctness

## Cloud deployment sketch

## Failure modes

## Cost concerns

## Questions I still have
```

## Lab result template

Use this structure for lab answers:

```md
# Lab Result

## Prediction

## Setup

## Experiment 1

## Observation

## Explanation

## Experiment 2

## Observation

## Explanation

## Design takeaway
```
