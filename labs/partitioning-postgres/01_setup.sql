-- Lesson 2 setup: plain, range-partitioned, and hash-partitioned event tables.
-- Safe to rerun: this drops only lab tables in the local system_design database.

\timing on
\set ON_ERROR_STOP on

DROP TABLE IF EXISTS events_by_month CASCADE;
DROP TABLE IF EXISTS events_by_user CASCADE;
DROP TABLE IF EXISTS events_plain CASCADE;

CREATE TABLE events_plain (
    event_id      bigint      NOT NULL,
    tenant_id     integer     NOT NULL,
    user_id       bigint      NOT NULL,
    event_type    text        NOT NULL,
    occurred_at   timestamptz NOT NULL,
    payload       jsonb       NOT NULL
);

-- 600,000 events across six months.
-- tenant_id=1 deliberately receives about 40% of rows to create skew for discussion.
INSERT INTO events_plain (
    event_id,
    tenant_id,
    user_id,
    event_type,
    occurred_at,
    payload
)
SELECT
    gs,
    (CASE
        WHEN gs % 10 < 4 THEN 1
        ELSE 2 + (gs % 999)
    END)::integer AS tenant_id,
    1 + (gs * 7919 % 100000) AS user_id,
    (ARRAY['view', 'click', 'purchase', 'login'])[(1 + (gs % 4))::integer] AS event_type,
    TIMESTAMPTZ '2026-01-01 00:00:00+00'
        + (((gs - 1) % 181)::double precision * INTERVAL '1 day')
        + (((gs * 37) % 86400)::double precision * INTERVAL '1 second') AS occurred_at,
    jsonb_build_object('source', 'lesson-02', 'sequence', gs)
FROM generate_series(1::bigint, 600000::bigint) AS gs;

ANALYZE events_plain;

CREATE TABLE events_by_month (
    event_id      bigint      NOT NULL,
    tenant_id     integer     NOT NULL,
    user_id       bigint      NOT NULL,
    event_type    text        NOT NULL,
    occurred_at   timestamptz NOT NULL,
    payload       jsonb       NOT NULL
) PARTITION BY RANGE (occurred_at);

CREATE TABLE events_2026_01 PARTITION OF events_by_month
FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE events_2026_02 PARTITION OF events_by_month
FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

CREATE TABLE events_2026_03 PARTITION OF events_by_month
FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE TABLE events_2026_04 PARTITION OF events_by_month
FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE events_2026_05 PARTITION OF events_by_month
FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

CREATE TABLE events_2026_06 PARTITION OF events_by_month
FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

INSERT INTO events_by_month
SELECT * FROM events_plain;

ANALYZE events_by_month;

CREATE TABLE events_by_user (
    event_id      bigint      NOT NULL,
    tenant_id     integer     NOT NULL,
    user_id       bigint      NOT NULL,
    event_type    text        NOT NULL,
    occurred_at   timestamptz NOT NULL,
    payload       jsonb       NOT NULL
) PARTITION BY HASH (user_id);

CREATE TABLE events_user_p0 PARTITION OF events_by_user
FOR VALUES WITH (MODULUS 8, REMAINDER 0);
CREATE TABLE events_user_p1 PARTITION OF events_by_user
FOR VALUES WITH (MODULUS 8, REMAINDER 1);
CREATE TABLE events_user_p2 PARTITION OF events_by_user
FOR VALUES WITH (MODULUS 8, REMAINDER 2);
CREATE TABLE events_user_p3 PARTITION OF events_by_user
FOR VALUES WITH (MODULUS 8, REMAINDER 3);
CREATE TABLE events_user_p4 PARTITION OF events_by_user
FOR VALUES WITH (MODULUS 8, REMAINDER 4);
CREATE TABLE events_user_p5 PARTITION OF events_by_user
FOR VALUES WITH (MODULUS 8, REMAINDER 5);
CREATE TABLE events_user_p6 PARTITION OF events_by_user
FOR VALUES WITH (MODULUS 8, REMAINDER 6);
CREATE TABLE events_user_p7 PARTITION OF events_by_user
FOR VALUES WITH (MODULUS 8, REMAINDER 7);

INSERT INTO events_by_user
SELECT * FROM events_plain;

ANALYZE events_by_user;

SELECT 'plain_rows' AS check_name, count(*) AS row_count
FROM events_plain
UNION ALL
SELECT 'range_rows', count(*) FROM events_by_month
UNION ALL
SELECT 'hash_rows', count(*) FROM events_by_user;

SELECT
    tableoid::regclass AS physical_partition,
    count(*) AS rows
FROM events_by_month
GROUP BY tableoid
ORDER BY physical_partition;

SELECT
    tableoid::regclass AS physical_partition,
    count(*) AS rows
FROM events_by_user
GROUP BY tableoid
ORDER BY physical_partition;
