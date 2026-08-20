# Lesson 2 — Query Lifecycle and `SELECT`

## Lesson overview

The transcript introduces `SELECT`, `FROM`, `WHERE`, sorting and limiting results. The important repair is that SQL is not executed simply from the first line to the last line. PostgreSQL parses a statement, transforms it into a query tree, plans physical operators and then executes the plan.

### Learning objectives

- Write a projection with explicit columns instead of relying on `SELECT *`.
- Explain logical query processing versus physical execution.
- Produce deterministic top-N and paginated results.
- Read the basic shape of a PostgreSQL plan.
- Distinguish estimated rows/cost from actual rows/time.

## Mental map

```text
SQL text + parameters
        |
        v
Parser / analyzer
        |
        v
Logical query representation
        |
        v
Planner / optimizer
        |
        v
Seq Scan | Index Scan | Join | Sort | Aggregate
        |
        v
Rows returned to the client
```

## Concept: projection, filtering and ordering

### Formal definition

- **Projection** chooses output expressions/columns.
- **Filtering** chooses rows satisfying a predicate.
- **Ordering** defines the requested output order; without `ORDER BY`, row order is not guaranteed.
- **Limiting** restricts the number of rows returned, but does not define which rows are selected without ordering.

### Example

```sql
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
```

The result contains at most five paid or shipped orders, newest first. `order_id` is a tie-breaker so two orders with the same timestamp do not make pagination unstable.

### Logical order versus written order

A useful teaching model is:

```text
FROM / JOIN -> WHERE -> GROUP BY -> HAVING -> SELECT -> DISTINCT -> ORDER BY -> LIMIT
```

This is a logical model, not a promise that PostgreSQL physically performs every operation in that exact order. The optimizer may push a predicate down, use an index for ordering, or eliminate unnecessary work while preserving the result semantics.

## Internal database behavior

For a simple query, PostgreSQL may choose a sequential scan over table pages. For a selective predicate and a useful index, it may choose an index scan or bitmap scan. The planner compares estimated costs; it does not blindly prefer indexes.

`EXPLAIN` displays the plan without executing it. `EXPLAIN ANALYZE` executes the statement and reports observed row counts and timings, so use it carefully with `UPDATE`, `DELETE` or other side effects. `BUFFERS` helps show shared/local/temp block activity.

Example:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, customer_id, ordered_at
FROM sales.orders
WHERE customer_id = 8
ORDER BY ordered_at DESC;
```

The exact plan is environment-dependent. Read the node tree from the bottom upward, compare `rows=` with `actual rows=`, and look for large misestimates or expensive sorts/scans.

## Performance implications

- Returning fewer columns reduces network and materialization work.
- Filtering early can reduce rows consumed by later joins or aggregates, but the optimizer decides how to implement it.
- `LIMIT` can reduce work when the plan can produce ordered rows incrementally; it does not make an unordered full scan cheap automatically.
- Offset pagination becomes increasingly expensive when the database must skip many rows. Keyset pagination uses a stable cursor such as `(ordered_at, order_id)`.

## Backend perspective

Never construct a user-provided `ORDER BY` identifier by string concatenation. Map an approved API sort key to a fixed SQL expression. Bind values as parameters.

JPA example:

```java
@Query("""
    select o from OrderEntity o
    where o.customer.id = :customerId
    order by o.orderedAt desc, o.id desc
    """)
List<OrderEntity> findRecentOrders(long customerId, Pageable pageable);
```

The ORM may generate a `SELECT` with joins and a limit. Inspect generated SQL and the real execution plan when latency matters.

## Common mistakes

- Assuming rows are naturally ordered by primary key.
- Using `SELECT *` in an API projection.
- Applying `LIMIT` without `ORDER BY` for a business-facing top-N result.
- Treating `EXPLAIN` cost units as milliseconds.
- Believing an index must be used because one exists.

## Hands-on lab

Run `sql/foundations/01_querying_sales.sql`, then run `sql/labs/01_query_plan.sql` as one session. Before the second query-plan `EXPLAIN`, predict whether PostgreSQL will use an index, bitmap scan or sequential scan. The lab deliberately avoids asserting one answer because planner choices depend on cost and statistics.

## Comparison

| Operation | Purpose | Internal behavior | Typical use |
| --- | --- | --- | --- |
| `SELECT` | Read/project rows | Planner chooses scans and operators | API reads and reports |
| `SELECT ... ORDER BY` | Request deterministic order | May sort or exploit ordered access path | Recent records, top-N |
| `SELECT ... LIMIT` | Cap result count | May stop early, but only after satisfying ordering/filtering | Page size |
| `EXPLAIN` | Inspect planned work | Does not execute the statement | Plan analysis |
| `EXPLAIN ANALYZE` | Measure observed execution | Executes the statement | Controlled performance investigation |

## Interview questions

1. **Junior — Why is `ORDER BY` needed with `LIMIT`?**  Without it, the database may return any qualifying rows because relational results are unordered by default.
2. **Junior — What is a sequential scan?**  An access method that examines table pages/rows sequentially.
3. **Mid — Why can a sequential scan be faster than an index scan?**  If many rows qualify, sequential I/O and filtering can cost less than many random heap lookups.
4. **Mid — What does `actual rows` tell you in `EXPLAIN ANALYZE`?**  The observed rows emitted by a plan node, useful for comparing reality with estimates.
5. **Senior — Why can an ORM-generated query be correct but still slow?**  Correctness and access-path efficiency are separate; joins, projections, predicates, row estimates and indexes may still produce an expensive plan.

## References

- [PostgreSQL `SELECT`](https://www.postgresql.org/docs/current/sql-select.html)
- [Using `EXPLAIN`](https://www.postgresql.org/docs/current/using-explain.html)
- [Keyset pagination discussion in PostgreSQL documentation](https://www.postgresql.org/docs/current/queries-limit.html)

