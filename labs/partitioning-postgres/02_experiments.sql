-- Lesson 2 experiments.
-- Run after 01_setup.sql.
-- This file intentionally prints plans without supplying interpretation.

\timing on
\pset pager off
\set ON_ERROR_STOP on

\echo ''
\echo '=== Experiment 1: narrow date range on the plain table ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SUMMARY)
SELECT count(*)
FROM events_plain
WHERE occurred_at >= TIMESTAMPTZ '2026-02-10'
  AND occurred_at <  TIMESTAMPTZ '2026-02-12';

\echo ''
\echo '=== Experiment 2: same date range on range partitions ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SUMMARY)
SELECT count(*)
FROM events_by_month
WHERE occurred_at >= TIMESTAMPTZ '2026-02-10'
  AND occurred_at <  TIMESTAMPTZ '2026-02-12';

\echo ''
\echo '=== Experiment 3: range partitions with pruning disabled ==='
SET enable_partition_pruning = off;
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SUMMARY)
SELECT count(*)
FROM events_by_month
WHERE occurred_at >= TIMESTAMPTZ '2026-02-10'
  AND occurred_at <  TIMESTAMPTZ '2026-02-12';
RESET enable_partition_pruning;

\echo ''
\echo '=== Experiment 4: user-only predicate on monthly range partitions ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SUMMARY)
SELECT count(*)
FROM events_by_month
WHERE user_id = 4242;

\echo ''
\echo '=== Experiment 5: exact user predicate on user hash partitions ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SUMMARY)
SELECT count(*)
FROM events_by_user
WHERE user_id = 4242;

\echo ''
\echo '=== Experiment 6: date predicate on user hash partitions ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SUMMARY)
SELECT count(*)
FROM events_by_user
WHERE occurred_at >= TIMESTAMPTZ '2026-02-10'
  AND occurred_at <  TIMESTAMPTZ '2026-02-12';

\echo ''
\echo '=== Experiment 7: combined user and date predicate ==='
\echo '--- range-by-month table ---'
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SUMMARY)
SELECT count(*)
FROM events_by_month
WHERE user_id = 4242
  AND occurred_at >= TIMESTAMPTZ '2026-02-01'
  AND occurred_at <  TIMESTAMPTZ '2026-03-01';

\echo '--- hash-by-user table ---'
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SUMMARY)
SELECT count(*)
FROM events_by_user
WHERE user_id = 4242
  AND occurred_at >= TIMESTAMPTZ '2026-02-01'
  AND occurred_at <  TIMESTAMPTZ '2026-03-01';

\echo ''
\echo '=== Experiment 8: create indexes on partitioned parents ==='
CREATE INDEX IF NOT EXISTS events_by_month_user_time_idx
ON events_by_month (user_id, occurred_at);

CREATE INDEX IF NOT EXISTS events_by_user_time_idx
ON events_by_user (occurred_at);

ANALYZE events_by_month;
ANALYZE events_by_user;

\echo '--- range-by-month after index creation ---'
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SUMMARY)
SELECT *
FROM events_by_month
WHERE user_id = 4242
  AND occurred_at >= TIMESTAMPTZ '2026-02-01'
  AND occurred_at <  TIMESTAMPTZ '2026-03-01'
ORDER BY occurred_at
LIMIT 20;

\echo '--- hash-by-user after index creation ---'
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SUMMARY)
SELECT *
FROM events_by_user
WHERE user_id = 4242
  AND occurred_at >= TIMESTAMPTZ '2026-02-01'
  AND occurred_at <  TIMESTAMPTZ '2026-03-01'
ORDER BY occurred_at
LIMIT 20;

\echo ''
\echo '=== Experiment 9: inspect partitioned indexes ==='
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename LIKE 'events_2026_%'
   OR tablename LIKE 'events_user_p%'
ORDER BY tablename, indexname;

\echo ''
\echo '=== Experiment 10: detach an old partition, then roll back ==='
BEGIN;

SELECT count(*) AS rows_before_detach
FROM events_by_month;

ALTER TABLE events_by_month
DETACH PARTITION events_2026_01;

SELECT count(*) AS rows_visible_through_parent_after_detach
FROM events_by_month;

SELECT count(*) AS rows_still_in_detached_table
FROM events_2026_01;

ROLLBACK;

SELECT count(*) AS rows_after_rollback
FROM events_by_month;
