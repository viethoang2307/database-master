\set ON_ERROR_STOP on
\ir 02_ddl_and_constraints.sql

-- DML and transaction example. This block rolls itself back, so it does not
-- change the canonical seed data.
BEGIN;

INSERT INTO lab.inventory_reservations (order_id, product_id, reserved_quantity)
VALUES (1001, 1, 1)
ON CONFLICT (order_id, product_id)
DO UPDATE SET reserved_quantity = EXCLUDED.reserved_quantity,
              status = 'active';

UPDATE lab.inventory_reservations
SET status = 'fulfilled'
WHERE order_id = 1001
  AND product_id = 1;

-- A real service would COMMIT after all invariants are satisfied.
-- ROLLBACK is intentional here so the lab is repeatable.
ROLLBACK;
