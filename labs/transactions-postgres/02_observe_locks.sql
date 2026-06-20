-- Run while one lesson session is blocked or holding locks.
-- This report focuses on the two lesson application names.

\pset pager off
\x off

SELECT
    a.pid,
    a.application_name,
    a.state,
    a.xact_start,
    a.wait_event_type,
    a.wait_event,
    pg_blocking_pids(a.pid) AS blocked_by,
    left(a.query, 100) AS current_query
FROM pg_stat_activity AS a
WHERE a.datname = current_database()
  AND (
      a.application_name LIKE 'lesson3-%'
      OR cardinality(pg_blocking_pids(a.pid)) > 0
  )
ORDER BY a.pid;

SELECT
    a.application_name,
    l.pid,
    l.locktype,
    l.mode,
    l.granted,
    l.waitstart,
    coalesce(c.relname, '-') AS relation,
    l.page,
    l.tuple,
    l.transactionid,
    l.virtualxid
FROM pg_locks AS l
JOIN pg_stat_activity AS a
  ON a.pid = l.pid
LEFT JOIN pg_class AS c
  ON c.oid = l.relation
WHERE a.datname = current_database()
  AND a.application_name LIKE 'lesson3-%'
ORDER BY a.application_name, l.granted, l.locktype, l.mode;

SELECT
    blocked.pid AS blocked_pid,
    blocked.application_name AS blocked_application,
    blocker.pid AS blocker_pid,
    blocker.application_name AS blocker_application,
    blocked.wait_event_type,
    blocked.wait_event,
    left(blocked.query, 80) AS blocked_query,
    left(blocker.query, 80) AS blocker_query
FROM pg_stat_activity AS blocked
CROSS JOIN LATERAL unnest(pg_blocking_pids(blocked.pid)) AS blocker_pid
JOIN pg_stat_activity AS blocker
  ON blocker.pid = blocker_pid
ORDER BY blocked.pid, blocker.pid;
