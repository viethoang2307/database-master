-- Query-planning lab. Run as one psql session after bootstrap.
-- The generated data is intentionally larger than the demo tables, but it is
-- still disposable because the table is temporary.

DROP TABLE IF EXISTS temp_order_events;

CREATE TEMP TABLE temp_order_events AS
SELECT
    event_id,
    ((event_id - 1) % 1000) + 1 AS customer_id,
    (CURRENT_DATE - ((event_id - 1) % 365))::date AS event_date,
    CASE WHEN event_id % 4 = 0 THEN 'payment' ELSE 'view' END AS event_type
FROM generate_series(1, 100000) AS generated(event_id);

ANALYZE temp_order_events;

-- Prediction: this is initially a sequential scan because no access path was
-- created for customer_id/event_date. Do not assume the planner must choose
-- this plan; inspect the actual output on your machine.
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM temp_order_events
WHERE customer_id = 42
  AND event_date >= CURRENT_DATE - 30;

CREATE INDEX temp_order_events_customer_date_idx
    ON temp_order_events (customer_id, event_date);

ANALYZE temp_order_events;

-- Prediction: the index is now a candidate. The planner may use an Index Scan,
-- Bitmap Index Scan + Bitmap Heap Scan, or another plan based on cost estimates.
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM temp_order_events
WHERE customer_id = 42
  AND event_date >= CURRENT_DATE - 30;

