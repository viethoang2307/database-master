# Lesson 5 — Filtering, `NULL` and Three-Valued Logic

## Lesson overview

The source course treats comparison and logical operators as simple building blocks. The difficult production detail is that SQL predicates operate with three logical outcomes: `TRUE`, `FALSE` and `UNKNOWN`. `NULL` represents missing/unknown/not-applicable data; it is not zero, an empty string or a normal value.

### Learning objectives

- Use comparison, `IN`, `BETWEEN`, `LIKE`, `AND`, `OR` and `NOT` correctly.
- Predict how `NULL` changes a predicate.
- Explain why `column = NULL` is wrong.
- Use `IS NULL`, `COALESCE` and `CASE` intentionally.
- Recognize the `NOT IN` plus `NULL` trap.
- Keep predicates index-friendly when performance matters.

## Formal model

For a `WHERE` clause, PostgreSQL keeps rows for which the predicate is `TRUE`. Rows for which it is `FALSE` or `UNKNOWN` are filtered out.

```text
NULL = 5       -> UNKNOWN
NULL <> 5      -> UNKNOWN
NULL = NULL    -> UNKNOWN
NULL IS NULL   -> TRUE
```

### Example

```sql
SELECT customer_id, full_name, country
FROM sales.customers
WHERE country IS NULL;
```

This returns Farah because `IS NULL` tests the null marker directly. `country = NULL` returns no rows because ordinary equality cannot establish that two unknown values are equal.

## Operators and edge cases

```sql
-- Inclusive range; use half-open ranges for timestamps when appropriate.
SELECT order_id, ordered_at
FROM sales.orders
WHERE ordered_at >= TIMESTAMPTZ '2025-03-01 00:00:00+07'
  AND ordered_at <  TIMESTAMPTZ '2025-04-01 00:00:00+07';

-- Pattern matching; the leading wildcard can prevent ordinary b-tree prefix use.
SELECT product_id, product_name
FROM sales.products
WHERE product_name ILIKE 'wire%';

-- Explicit fallback for display, not for pretending missing data was present.
SELECT full_name, COALESCE(country, 'unknown') AS display_country
FROM sales.customers;

-- Categorize values while preserving the source amount.
SELECT
    product_name,
    unit_price,
    CASE
        WHEN unit_price >= 200 THEN 'premium'
        WHEN unit_price >= 50 THEN 'standard'
        ELSE 'entry'
    END AS price_band
FROM sales.products;
```

## The `NOT IN` trap

If the right-hand set contains `NULL`, `x NOT IN (...)` can evaluate to `UNKNOWN` for values that are not equal to any known member. Prefer `NOT EXISTS` when the subquery may contain nulls and the intended meaning is anti-membership.

```sql
-- Robust anti-membership shape.
SELECT c.customer_id, c.full_name
FROM sales.customers AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM sales.orders AS o
    WHERE o.customer_id = c.customer_id
);
```

## Internal and performance behavior

The planner can use statistics to estimate predicate selectivity. A simple predicate on an indexed column is more likely to be useful than applying a function to every row:

```sql
-- Often more index-friendly for a timestamp range:
WHERE ordered_at >= :start_at AND ordered_at < :end_at

-- May require an expression index or more work:
WHERE date(ordered_at) = :target_date
```

This is not an absolute rule; inspect `EXPLAIN`. `LIKE 'wire%'` has a prefix that can be indexable under suitable collation/operator-class conditions, while `LIKE '%wire%'` generally needs a different search strategy such as trigram indexing for large workloads.

## Backend perspective

Decide whether a missing value means unknown, not applicable or not yet collected. That policy affects API serialization, filters, reporting and uniqueness. Do not silently turn every `NULL` into an empty string merely to simplify JSON.

When constructing optional filters, use parameterized predicates and a deliberate query shape. A query that includes `WHERE (:country IS NULL OR country = :country)` may be convenient but can complicate selectivity and planning; measure it for high-volume endpoints.

## Common misconceptions

- `NULL` is not the same as `0`, `''` or `FALSE`.
- `BETWEEN` is inclusive at both ends; timestamp reporting often benefits from `[start, end)` ranges.
- `CASE` is an expression returning a value; it is not a general procedural `if` block.
- `COALESCE` is not data repair. It only changes the expression result.

## Hands-on lab

1. Run the queries in `sql/foundations/01_querying_sales.sql`.
2. Predict the result of `WHERE country = NULL`, then replace it with `IS NULL`.
3. Create a temporary values table containing `(1), (2), (NULL)` and compare `NOT IN` with `NOT EXISTS`.
4. Run `EXPLAIN` for a timestamp range and for `date(ordered_at) = ...`; explain any difference without assuming the plan must change on the small demo table.

## Interview questions

1. **Junior — Why does `column = NULL` not work?**  Equality with an unknown value yields `UNKNOWN`; `IS NULL` is the null test.
2. **Junior — What rows pass `WHERE`?**  Only rows whose predicate evaluates to `TRUE`; `FALSE` and `UNKNOWN` are excluded.
3. **Mid — Why can `NOT IN` behave unexpectedly?**  A `NULL` in the compared set can make the result `UNKNOWN`; `NOT EXISTS` expresses anti-membership more robustly.
4. **Mid — Is `BETWEEN` inclusive?**  Yes, for both endpoints; explicit half-open timestamp ranges are often safer for adjacent periods.
5. **Senior — Why can wrapping an indexed column in a function hurt performance?**  A normal index is ordered by the stored expression, not necessarily by the function result, so the planner may not be able to use it without an expression index or rewrite.

## References

- [PostgreSQL Comparison Functions and Operators](https://www.postgresql.org/docs/current/functions-comparison.html)
- [PostgreSQL Conditional Expressions](https://www.postgresql.org/docs/current/functions-conditional.html)
- [PostgreSQL Pattern Matching](https://www.postgresql.org/docs/current/functions-matching.html)
- [PostgreSQL Indexes on Expressions](https://www.postgresql.org/docs/current/indexes-expressional.html)

