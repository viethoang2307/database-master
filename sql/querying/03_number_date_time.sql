-- Lesson 3 lab: numeric, date/time, formatting and casting
-- PostgreSQL. Run from repository root after bootstrap scripts.
-- The lab uses a temporary table, so reconnecting clears lab_events.

\echo 'Setup: create temporary event data'
DROP TABLE IF EXISTS lab_events;
CREATE TEMP TABLE lab_events (
    event_id integer PRIMARY KEY,
    occurred_at timestamptz NOT NULL,
    ended_at timestamptz,
    amount numeric(12,3),
    raw_date text,
    raw_number text
);

INSERT INTO lab_events VALUES
    (1, '2025-01-31 23:30:00+07', '2025-02-01 01:00:00+07',
     3.516, '2025-01-31', '12.345'),
    (2, '2025-02-01 00:05:00+07', '2025-02-01 00:20:00+07',
     -10.250, '2025-02-30', '-8.50'),
    (3, '2025-02-28 12:00:00+07', '2025-03-01 12:30:00+07',
     100.005, '2025-02-28', 'bad'),
    (4, '2025-03-01 00:00:00+07', NULL,
     NULL, NULL, '42');

\echo 'Experiment 1: round and abs'
SELECT
    event_id,
    amount,
    round(amount, 2) AS rounded_amount,
    abs(amount) AS magnitude
FROM lab_events
ORDER BY event_id;

\echo 'Experiment 2: timezone and business date'
SELECT
    event_id,
    occurred_at,
    occurred_at AT TIME ZONE 'UTC' AS utc_wall_clock,
    occurred_at AT TIME ZONE 'Asia/Ho_Chi_Minh' AS vn_wall_clock,
    (occurred_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS vn_date
FROM lab_events
ORDER BY event_id;

\echo 'Experiment 3: extract and date_trunc'
SELECT
    event_id,
    extract(year FROM occurred_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::int
        AS year_number,
    extract(month FROM occurred_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::int
        AS month_number,
    date_trunc(
        'month',
        occurred_at,
        'Asia/Ho_Chi_Minh'
    ) AS month_bucket
FROM lab_events
ORDER BY occurred_at;

\echo 'Experiment 4: first day, last day and exclusive next start'
WITH x AS (
    SELECT date_trunc(
        'month',
        TIMESTAMPTZ '2025-02-28 12:00:00+07',
        'Asia/Ho_Chi_Minh'
    ) AS start_at
)
SELECT
    start_at::date AS first_day,
    (start_at + interval '1 month' - interval '1 day')::date AS last_day,
    start_at + interval '1 month' AS next_start
FROM x;

\echo 'Experiment 5: elapsed duration'
SELECT
    event_id,
    ended_at - occurred_at AS elapsed_interval,
    extract(epoch FROM (ended_at - occurred_at)) / 3600.0
        AS elapsed_hours
FROM lab_events
WHERE ended_at IS NOT NULL
  AND ended_at >= occurred_at;

\echo 'Experiment 6: format versus cast'
SELECT
    event_id,
    to_char(
        occurred_at AT TIME ZONE 'Asia/Ho_Chi_Minh',
        'YYYY-MM-DD HH24:MI:SS'
    ) AS display_time,
    (occurred_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS vn_date
FROM lab_events
ORDER BY event_id;

SELECT
    pg_typeof(to_char(occurred_at, 'YYYY-MM-DD')) AS formatted_type,
    pg_typeof(occurred_at::date) AS cast_type
FROM lab_events
LIMIT 1;

\echo 'Experiment 7: validate raw date on modern PostgreSQL'
SELECT
    event_id,
    raw_date,
    pg_input_is_valid(raw_date, 'date') AS valid_date
FROM lab_events
ORDER BY event_id;

\echo 'Experiment 8: explain a range predicate'
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, ordered_at
FROM sales.orders
WHERE ordered_at >= TIMESTAMPTZ '2025-02-01 00:00:00+07'
  AND ordered_at <  TIMESTAMPTZ '2025-03-01 00:00:00+07';

-- Optional production-style comparison. Keep this index only if your local
-- experiment database is disposable or you explicitly want the index.
-- CREATE INDEX idx_orders_ordered_at_lab ON sales.orders (ordered_at);
-- ANALYZE sales.orders;
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT order_id, ordered_at
-- FROM sales.orders
-- WHERE ordered_at >= TIMESTAMPTZ '2025-02-01 00:00:00+07'
--   AND ordered_at < TIMESTAMPTZ '2025-03-01 00:00:00+07';
