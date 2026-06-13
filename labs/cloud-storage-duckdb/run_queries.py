import duckdb
from pathlib import Path

DATA_GLOB = "data/events/**/*.parquet"

if not Path("data/events").exists():
    raise SystemExit("No data found. Run: python generate_data.py")

queries = {
    "count_everything": f"""
        EXPLAIN ANALYZE
        SELECT count(*)
        FROM read_parquet('{DATA_GLOB}');
    """,
    "filter_by_day": f"""
        EXPLAIN ANALYZE
        SELECT count(*)
        FROM read_parquet('{DATA_GLOB}')
        WHERE day = '2026-06-05';
    """,
    "group_by_country_event_type": f"""
        EXPLAIN ANALYZE
        SELECT country, event_type, count(*) AS events
        FROM read_parquet('{DATA_GLOB}')
        WHERE country = 'CA'
        GROUP BY country, event_type
        ORDER BY event_type;
    """,
}

con = duckdb.connect()

for name, sql in queries.items():
    print("\n" + "=" * 80)
    print(name)
    print("=" * 80)
    result = con.sql(sql).fetchall()
    for row in result:
        print(row[1] if len(row) > 1 else row[0])
