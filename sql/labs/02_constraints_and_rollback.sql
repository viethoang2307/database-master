\set ON_ERROR_STOP on
\ir ../foundations/02_ddl_and_constraints.sql

-- Run this as one session. The first transaction commits valid data; the
-- second transaction is rolled back after a deliberate constraint failure.

BEGIN;
INSERT INTO lab.inventory_reservations (order_id, product_id, reserved_quantity)
VALUES (1002, 3, 1)
ON CONFLICT (order_id, product_id)
DO UPDATE SET reserved_quantity = EXCLUDED.reserved_quantity;
COMMIT;

BEGIN;
-- This statement fails because reserved_quantity must be positive.
INSERT INTO lab.inventory_reservations (order_id, product_id, reserved_quantity)
VALUES (1002, 4, 0);
ROLLBACK;

SELECT *
FROM lab.inventory_reservations
WHERE order_id = 1002;
