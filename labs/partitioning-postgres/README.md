# Lesson 2 Lab — Partitioning

This lab has two parts:

1. PostgreSQL range and hash partitioning.
2. A dependency-free Python simulator for hot partitions.

## Requirements

- Docker Desktop or Docker Engine with Compose
- Python 3

The repository already includes `labs/docker-compose.yml`.

## Start PostgreSQL

From the repository root:

```bash
cd labs
docker compose up -d postgres
docker compose ps
cd ..
```

## Load the data

From the repository root:

```bash
docker exec -i ds_course_postgres \
  psql -U app -d system_design \
  < labs/partitioning-postgres/01_setup.sql
```

This creates 600,000 fake events in:

- `events_plain`
- `events_by_month`
- `events_by_user`

## Run the query-plan experiments

```bash
docker exec -i ds_course_postgres \
  psql -U app -d system_design \
  < labs/partitioning-postgres/02_experiments.sql
```

Keep the output available while answering:

```text
questions/lesson-02-partitioning-cloud-vs-noncloud.md
```

## Run the hot-partition simulator

```bash
python labs/partitioning-postgres/hot_partition_sim.py
```

No third-party Python packages are required.

## Open an interactive `psql` session

```bash
docker exec -it ds_course_postgres \
  psql -U app -d system_design
```

Useful commands:

```sql
\d+ events_by_month
\d+ events_by_user

SELECT
  tableoid::regclass AS physical_partition,
  count(*)
FROM events_by_month
GROUP BY tableoid
ORDER BY tableoid;
```

## Reset the lab

Rerun:

```bash
docker exec -i ds_course_postgres \
  psql -U app -d system_design \
  < labs/partitioning-postgres/01_setup.sql
```

The setup file drops and recreates only the lesson tables.

## Stop PostgreSQL

```bash
cd labs
docker compose down
```
