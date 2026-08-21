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
