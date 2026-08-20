# Foundation Sprint Exercises

Do not open the solution file until you have written down your prediction and reasoning.

## Level 1 — Recall

1. Explain the difference between a PostgreSQL server, database, schema and table.
2. What is the role of a DBMS that a plain CSV file does not provide?
3. Define projection, predicate, ordering and pagination.
4. Why is `ORDER BY` required for deterministic top-N results?
5. Name four constraints used in the `sales` schema and state the invariant each protects.
6. Compare `DELETE`, `TRUNCATE` and `DROP TABLE`.
7. What does `COMMIT` do, and what does `ROLLBACK` do?
8. Why is `NULL` different from an empty string?

## Level 2 — Apply

1. Write a query returning active products priced between 50 and 150 inclusive, ordered by price descending and product id ascending.
2. Write a query returning the five newest orders for customer `8`, with a deterministic tie-breaker.
3. Calculate each order's total from `sales.order_items`, applying `discount_pct` and rounding to two decimal places.
4. Return every customer who has never placed an order. Use `NOT EXISTS`.
5. Create a table `lab.shipment_events` with an identity primary key, an order foreign key, a non-null event type restricted to `created`, `packed` or `shipped`, and an event timestamp.
6. Insert a shipment event twice safely so that the second execution does not create a duplicate event for the same order and event type. State the unique constraint needed.
7. Write a transaction that inserts an order item and then marks the order as `paid`. Explain what must happen if the second statement fails.
8. Predict whether each predicate returns `TRUE`, `FALSE` or `UNKNOWN` for `country = NULL`, then verify:

   ```sql
   SELECT
       NULL = NULL AS equality,
       NULL IS NULL AS is_null,
       NULL <> 'VN' AS inequality;
   ```

## Level 3 — Engineering

1. An order-placement endpoint currently performs `SELECT stock`, validates in Java, then performs `UPDATE stock`. Explain the race condition and propose a PostgreSQL-safe write strategy.
2. A report endpoint uses `OFFSET 100000 LIMIT 50` on a table with 200 million rows. Design a keyset pagination query and identify the required ordering/index shape.
3. A migration adds a `NOT NULL` column with a default to a table receiving 5,000 writes per second. Describe a safe rollout sequence and what you would measure.
4. A service validates email uniqueness before insertion, but duplicate-email errors still appear in production. Explain why and identify the database rule that should exist.
5. A developer replaces every `NULL` country with the string `unknown` during ingestion. Discuss how this changes filtering, analytics and future data-quality decisions.

## Debugging challenges

For each scenario, state what is wrong, why it is wrong and how you would fix it.

### Challenge 1 — Unstable pagination

```sql
SELECT order_id, ordered_at
FROM sales.orders
ORDER BY ordered_at DESC
LIMIT 20 OFFSET 20;
```

### Challenge 2 — Null comparison

```sql
SELECT customer_id, full_name
FROM sales.customers
WHERE country = NULL;
```

### Challenge 3 — Check-then-insert race

```text
if repository.findByEmail(email) is empty:
    repository.insert(user)
```

### Challenge 4 — Partial business operation

```text
insert order       // autocommit
insert order items // fails
```

### Challenge 5 — Dangerous bulk update

```sql
UPDATE sales.orders
SET order_status = 'cancelled';
```

## Deliverable

Save your answers as a personal note. For Level 2 SQL, include the query and one sentence explaining the expected result. For Level 3, include the invariant, transaction boundary, failure behavior and observability plan.

