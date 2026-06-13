# Database-Forward System Design

Practice-based system design with a database foundation, a light cloud layer, and one topic per lesson.

## Start here

Open `index.html` locally in your browser.

The course is now HTML-first:

- `index.html` — course landing page
- `setup/downloads.html` — tool setup and download instructions
- `course/00-course-format-and-roadmap.html` — topic sequence and lesson format
- `lessons/01-cloud-storage-and-cloud-database-architecture.html` — first lesson with editable answer boxes

## How submissions work

Each lesson has an editable submission workspace inside the HTML file.

1. Open the lesson locally in your browser.
2. Type answers into the boxes.
3. Click **Save Draft** while working.
4. Click **Copy Submission** or **Download Submission**.
5. Paste the submission into chat for review.

Drafts are saved in browser local storage, not Git. Download or copy your answers when you want to keep them permanently.

## First lesson

Topic: cloud storage fundamentals and cloud database architecture.

Main example: Snowflake-style architecture.

Hands-on: DuckDB + Parquet.

Lab files:

- `labs/cloud-storage-duckdb/generate_data.py`
- `labs/cloud-storage-duckdb/run_queries.py`
- `labs/cloud-storage-duckdb/README.html`

## Later local services

Docker is optional for Lesson 1, but useful later. The repo includes:

- `labs/docker-compose.yml`

It can run local Postgres, Redis, and Redpanda for later lessons.
