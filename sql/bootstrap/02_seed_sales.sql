TRUNCATE TABLE sales.order_items, sales.orders, sales.products, sales.customers
RESTART IDENTITY CASCADE;

INSERT INTO sales.customers (customer_id, full_name, email, country, signup_date)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'An Nguyen', 'an@example.com', 'VN', DATE '2024-01-10'),
    (2, 'Binh Tran', 'binh@example.com', 'VN', DATE '2024-02-15'),
    (3, 'Chloe Martin', 'chloe@example.com', 'FR', DATE '2024-03-20'),
    (4, 'Diego Garcia', 'diego@example.com', 'ES', DATE '2024-04-03'),
    (5, 'Elena Rossi', 'elena@example.com', 'IT', DATE '2024-05-18'),
    (6, 'Farah Khan', 'farah@example.com', NULL, DATE '2024-06-22'),
    (7, 'Grace Lee', 'grace@example.com', 'SG', DATE '2024-07-11'),
    (8, 'Huy Le', 'huy@example.com', 'VN', DATE '2024-08-09');

INSERT INTO sales.products (product_id, product_name, category, unit_price, active)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'Mechanical Keyboard', 'accessories', 89.00, TRUE),
    (2, 'Wireless Mouse', 'accessories', 35.50, TRUE),
    (3, '27-inch Monitor', 'displays', 249.99, TRUE),
    (4, 'USB-C Dock', 'accessories', 129.00, TRUE),
    (5, 'Laptop Stand', 'ergonomics', 59.90, TRUE),
    (6, 'Legacy Webcam', 'accessories', 45.00, FALSE);

INSERT INTO sales.orders (order_id, customer_id, order_status, ordered_at, shipping_country)
OVERRIDING SYSTEM VALUE
VALUES
    (1001, 1, 'paid',      TIMESTAMPTZ '2025-01-05 09:15:00+07', 'VN'),
    (1002, 1, 'shipped',   TIMESTAMPTZ '2025-01-18 13:30:00+07', 'VN'),
    (1003, 2, 'cancelled', TIMESTAMPTZ '2025-02-02 10:00:00+07', 'VN'),
    (1004, 2, 'paid',      TIMESTAMPTZ '2025-02-21 16:45:00+07', 'VN'),
    (1005, 3, 'shipped',   TIMESTAMPTZ '2025-03-03 08:20:00+01', 'FR'),
    (1006, 3, 'pending',   TIMESTAMPTZ '2025-03-17 11:10:00+01', 'FR'),
    (1007, 4, 'paid',      TIMESTAMPTZ '2025-04-09 15:05:00+02', 'ES'),
    (1008, 5, 'shipped',   TIMESTAMPTZ '2025-04-22 12:25:00+02', 'IT'),
    (1009, 6, 'paid',      TIMESTAMPTZ '2025-05-13 18:40:00+00', NULL),
    (1010, 7, 'paid',      TIMESTAMPTZ '2025-06-01 09:00:00+08', 'SG'),
    (1011, 8, 'shipped',   TIMESTAMPTZ '2025-06-14 14:35:00+07', 'VN'),
    (1012, 8, 'pending',   TIMESTAMPTZ '2025-06-29 17:55:00+07', 'VN');

INSERT INTO sales.order_items (order_id, product_id, quantity, unit_price, discount_pct)
VALUES
    (1001, 1, 1, 89.00, 0),
    (1001, 2, 2, 35.50, 5),
    (1002, 3, 1, 249.99, 10),
    (1002, 5, 1, 59.90, 0),
    (1003, 6, 1, 45.00, 0),
    (1004, 4, 1, 129.00, 0),
    (1004, 2, 1, 35.50, 0),
    (1005, 3, 2, 249.99, 15),
    (1006, 1, 1, 89.00, 0),
    (1007, 4, 2, 129.00, 5),
    (1008, 5, 2, 59.90, 0),
    (1008, 2, 1, 35.50, 0),
    (1009, 1, 1, 89.00, 0),
    (1009, 6, 1, 45.00, 20),
    (1010, 3, 1, 249.99, 0),
    (1011, 4, 1, 129.00, 0),
    (1011, 5, 1, 59.90, 0),
    (1012, 2, 3, 35.50, 0),
    (1012, 6, 1, 45.00, 0),
    (1012, 1, 1, 89.00, 10);

-- Explicit seed identifiers do not advance identity sequences automatically.
-- Align the sequences so later application inserts cannot collide with seeds.
SELECT setval(
    pg_get_serial_sequence('sales.customers', 'customer_id'),
    (SELECT max(customer_id) FROM sales.customers),
    TRUE
);

SELECT setval(
    pg_get_serial_sequence('sales.products', 'product_id'),
    (SELECT max(product_id) FROM sales.products),
    TRUE
);

SELECT setval(
    pg_get_serial_sequence('sales.orders', 'order_id'),
    (SELECT max(order_id) FROM sales.orders),
    TRUE
);

ANALYZE sales.customers;
ANALYZE sales.products;
ANALYZE sales.orders;
ANALYZE sales.order_items;
