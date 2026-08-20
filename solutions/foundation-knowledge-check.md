# Foundation Knowledge Check Answers

1. **B.** The planner/optimizer compares possible physical plans using estimates and cost settings.
2. **False.** A primary key identifies rows but does not promise result order.
3. `LIMIT` without `ORDER BY` does not define which qualifying rows are returned; a tie-breaker makes page boundaries stable.
4. Only `NULL IS NULL` is `TRUE`. Equality and inequality with `NULL` evaluate to `UNKNOWN`.
5. **C.** A foreign key enforces the referenced relationship.
6. A foreign key enforces correctness, but it does not automatically create every useful index on the referencing side or guarantee a cheap join plan.
7. It is inclusive at both date endpoints but converts a timestamp column for every row and can mishandle the end-of-day boundary. Prefer `ordered_at >= '2025-03-01' AND ordered_at < '2025-04-01'` with explicit time zone semantics.
8. **True.** It runs the statement and reports observed execution details; use side-effect statements carefully.
9. Abort/rollback the transaction and retry the entire logical operation when it is safe and bounded to retry.
10. **C.** `DROP TABLE` removes the relation definition and its data.
11. SQL uses three-valued logic: if no known value matches but the set contains `NULL`, the `NOT IN` predicate can be `UNKNOWN`, which does not pass `WHERE`.
12. Service validation improves feedback and avoids unnecessary database errors; database enforcement protects against races, scripts and other writers.

