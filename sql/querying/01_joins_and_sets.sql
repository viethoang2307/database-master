-- Querying Sprint lab: JOIN, anti-join and set operators.
-- Run after sql/bootstrap/99_bootstrap.sql.

SELECT
    o.order_id,
    c.full_name,
    o.order_status
FROM sales.orders AS o
JOIN sales.customers AS c
  ON c.customer_id = o.customer_id
ORDER BY o.order_id;

SELECT
    c.customer_id,
    c.full_name,
    o.order_id,
    o.order_status
FROM sales.customers AS c
LEFT JOIN sales.orders AS o
  ON o.customer_id = c.customer_id
 AND o.order_status = 'paid'
ORDER BY c.customer_id, o.order_id;

SELECT p.product_id, p.product_name
FROM sales.products AS p
WHERE NOT EXISTS (
    SELECT 1
    FROM sales.order_items AS oi
    WHERE oi.product_id = p.product_id
)
ORDER BY p.product_id;

SELECT country AS country_code
FROM sales.customers
WHERE country IS NOT NULL
UNION
SELECT shipping_country AS country_code
FROM sales.orders
WHERE shipping_country IS NOT NULL
ORDER BY country_code;

SELECT product_id
FROM sales.products
WHERE active = TRUE
INTERSECT
SELECT product_id
FROM sales.order_items
ORDER BY product_id;

SELECT product_id
FROM sales.products
WHERE active = TRUE
EXCEPT
SELECT product_id
FROM sales.order_items
ORDER BY product_id;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.customer_id,
    count(DISTINCT o.order_id) AS order_count
FROM sales.customers AS c
LEFT JOIN sales.orders AS o
  ON o.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY c.customer_id;

-- No JOIN: two independent result sets.
SELECT customer_id, full_name, country
FROM sales.customers
ORDER BY customer_id;

SELECT order_id, customer_id, order_status, ordered_at
FROM sales.orders
ORDER BY order_id;

-- Multiple-table JOIN. The result grain is order item.
SELECT
    o.order_id,
    c.full_name,
    p.product_name,
    oi.quantity,
    oi.unit_price
FROM sales.orders AS o
LEFT JOIN sales.customers AS c
  ON c.customer_id = o.customer_id
LEFT JOIN sales.order_items AS oi
  ON oi.order_id = o.order_id
LEFT JOIN sales.products AS p
  ON p.product_id = oi.product_id
ORDER BY o.order_id, p.product_id;

-- Full anti-join with an in-memory example.
WITH left_side(id) AS (VALUES (1), (2)),
     right_side(id) AS (VALUES (2), (3))
SELECT
    left_side.id AS left_id,
    right_side.id AS right_id
FROM left_side
FULL OUTER JOIN right_side
  ON right_side.id = left_side.id
WHERE left_side.id IS NULL
   OR right_side.id IS NULL
ORDER BY left_id NULLS LAST, right_id NULLS LAST;

-- Right anti-join template. The FK means this normally returns no rows.
SELECT o.order_id, o.customer_id
FROM sales.customers AS c
RIGHT JOIN sales.orders AS o
  ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL
ORDER BY o.order_id;

-- Combine current/archive-shaped data and keep source provenance.
WITH current_orders(order_id, customer_id, ordered_at) AS (
    VALUES
        (101::BIGINT, 1::BIGINT, TIMESTAMPTZ '2026-01-10 09:00:00+07'),
        (102::BIGINT, 2::BIGINT, TIMESTAMPTZ '2026-01-11 09:00:00+07')
),
archive_orders(order_id, customer_id, ordered_at) AS (
    VALUES
        (90::BIGINT, 1::BIGINT, TIMESTAMPTZ '2025-12-10 09:00:00+07'),
        (91::BIGINT, 3::BIGINT, TIMESTAMPTZ '2025-12-11 09:00:00+07')
)
SELECT order_id, customer_id, ordered_at, 'current' AS source_table
FROM current_orders
UNION ALL
SELECT order_id, customer_id, ordered_at, 'archive' AS source_table
FROM archive_orders
ORDER BY ordered_at, order_id;

-- Delta detection: day 2 minus day 1.
WITH day_1(customer_id, email) AS (
    VALUES (1, 'a@example.com'), (2, 'b@example.com')
),
day_2(customer_id, email) AS (
    VALUES (1, 'a@example.com'), (2, 'b@example.com'), (3, 'c@example.com')
)
SELECT customer_id, email
FROM day_2
EXCEPT
SELECT customer_id, email
FROM day_1
ORDER BY customer_id;
