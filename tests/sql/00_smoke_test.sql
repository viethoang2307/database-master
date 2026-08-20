\set ON_ERROR_STOP on

DO $$
DECLARE
    actual_count BIGINT;
BEGIN
    SELECT count(*) INTO actual_count FROM sales.customers;
    IF actual_count <> 8 THEN
        RAISE EXCEPTION 'Expected 8 customers, got %', actual_count;
    END IF;

    SELECT count(*) INTO actual_count FROM sales.products;
    IF actual_count <> 6 THEN
        RAISE EXCEPTION 'Expected 6 products, got %', actual_count;
    END IF;

    SELECT count(*) INTO actual_count FROM sales.orders;
    IF actual_count <> 12 THEN
        RAISE EXCEPTION 'Expected 12 orders, got %', actual_count;
    END IF;

    SELECT count(*) INTO actual_count FROM sales.order_items;
    IF actual_count <> 20 THEN
        RAISE EXCEPTION 'Expected 20 order items, got %', actual_count;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM sales.orders AS o
        LEFT JOIN sales.customers AS c ON c.customer_id = o.customer_id
        WHERE c.customer_id IS NULL
    ) THEN
        RAISE EXCEPTION 'Found an order without a valid customer';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM sales.order_items AS oi
        LEFT JOIN sales.orders AS o ON o.order_id = oi.order_id
        WHERE o.order_id IS NULL
    ) THEN
        RAISE EXCEPTION 'Found an order item without a valid order';
    END IF;
END $$;

SELECT
    'smoke test passed' AS result,
    (SELECT count(*) FROM sales.customers) AS customers,
    (SELECT count(*) FROM sales.products) AS products,
    (SELECT count(*) FROM sales.orders) AS orders,
    (SELECT count(*) FROM sales.order_items) AS order_items;

