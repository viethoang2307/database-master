-- Foundation query examples. Run after sql/bootstrap/99_bootstrap.sql.

-- Projection and a business predicate: only products currently offered.
SELECT product_id, product_name, unit_price
FROM sales.products
WHERE active = TRUE
ORDER BY unit_price DESC, product_id;

-- Join order headers to customers. The second ORDER BY key makes pagination stable.
SELECT
    o.order_id,
    c.full_name AS customer_name,
    o.order_status,
    o.ordered_at
FROM sales.orders AS o
JOIN sales.customers AS c ON c.customer_id = o.customer_id
WHERE o.order_status IN ('paid', 'shipped')
ORDER BY o.ordered_at DESC, o.order_id DESC
LIMIT 5;

-- Calculate a line total without mutating stored historical price data.
SELECT
    oi.order_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    oi.discount_pct,
    round(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100), 2) AS line_total
FROM sales.order_items AS oi
ORDER BY oi.order_id, oi.product_id;

-- NULL is not an empty string and must be tested with IS NULL/IS NOT NULL.
SELECT customer_id, full_name, country
FROM sales.customers
WHERE country IS NULL;

