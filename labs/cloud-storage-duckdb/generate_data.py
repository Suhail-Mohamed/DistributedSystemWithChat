from pathlib import Path
import random
import pandas as pd

DATA_DIR = Path("data/events")
DATA_DIR.mkdir(parents=True, exist_ok=True)

# Keep this small enough for a laptop. Increase ROWS_PER_DAY later if you want.
DAYS = 10
ROWS_PER_DAY = 100_000
COUNTRIES = ["CA", "US", "GB", "DE", "IN"]
EVENT_TYPES = ["view", "click", "purchase"]

for day in range(1, DAYS + 1):
    rows = []
    for i in range(ROWS_PER_DAY):
        rows.append(
            {
                "event_id": f"{day}-{i}",
                "user_id": random.randint(1, 100_000),
                "event_type": random.choice(EVENT_TYPES),
                "country": random.choice(COUNTRIES),
                "amount": round(random.random() * 100, 2),
                "day": f"2026-06-{day:02d}",
            }
        )

    df = pd.DataFrame(rows)
    out_dir = DATA_DIR / f"day=2026-06-{day:02d}"
    out_dir.mkdir(parents=True, exist_ok=True)
    df.to_parquet(out_dir / "events.parquet", index=False)
    print(f"wrote {len(df):,} rows to {out_dir / 'events.parquet'}")

print("done")
