"""Lesson 2: show uniform keys, one hot key, and write sharding."""

from __future__ import annotations

import hashlib
import random
from collections import Counter
from typing import Iterable

PARTITIONS = 16
REQUESTS = 100_000
HOT_KEY = "celebrity-user"
HOT_FRACTION = 0.40
SALT_BUCKETS = 16
SEED = 42


def partition_for(key: str, partitions: int = PARTITIONS) -> int:
    digest = hashlib.sha256(key.encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big") % partitions


def uniform_keys(count: int) -> Iterable[str]:
    for _ in range(count):
        yield f"user-{random.randint(1, 1_000_000)}"


def skewed_keys(count: int, salted: bool) -> Iterable[str]:
    for _ in range(count):
        if random.random() < HOT_FRACTION:
            if salted:
                yield f"{HOT_KEY}#{random.randrange(SALT_BUCKETS)}"
            else:
                yield HOT_KEY
        else:
            yield f"user-{random.randint(1, 1_000_000)}"


def summarize(name: str, keys: Iterable[str]) -> None:
    counts = Counter(partition_for(key) for key in keys)
    values = [counts[i] for i in range(PARTITIONS)]
    busiest = max(range(PARTITIONS), key=lambda i: counts[i])
    quietest = min(range(PARTITIONS), key=lambda i: counts[i])
    max_count = counts[busiest]
    min_count = counts[quietest]

    print("\n" + "=" * 74)
    print(name)
    print("=" * 74)

    for partition, count in enumerate(values):
        bar = "#" * max(1, round(count / max(values) * 40))
        print(f"p{partition:02d} {count:7,d} | {bar}")

    print(f"\nBusiest partition: p{busiest:02d}")
    print(f"Busiest share:     {max_count / sum(values):.2%}")
    print(f"Max/min ratio:     {max_count / max(min_count, 1):.2f}x")


def main() -> None:
    random.seed(SEED)
    summarize("Uniform keys", uniform_keys(REQUESTS))

    random.seed(SEED)
    summarize(
        f"One hot key ({HOT_FRACTION:.0%} of requests)",
        skewed_keys(REQUESTS, salted=False),
    )

    random.seed(SEED)
    summarize(
        f"Hot key write-sharded across {SALT_BUCKETS} salted keys",
        skewed_keys(REQUESTS, salted=True),
    )


if __name__ == "__main__":
    main()
