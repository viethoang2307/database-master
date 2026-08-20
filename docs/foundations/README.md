# Foundation Sprint

## Lesson overview

This sprint builds the mental model needed before using an ORM or a framework. The learner moves from “a database stores data” to a more precise model: a PostgreSQL server accepts SQL, parses it, plans an execution strategy, executes against relations and indexes, and enforces constraints while coordinating concurrent transactions.

## Learning objectives

After completing this sprint, the student should be able to:

- Distinguish a database, DBMS, schema, table, row, column and SQL statement.
- Explain the path from a backend request to a PostgreSQL execution plan.
- Write deterministic `SELECT` queries with projection, filtering, ordering and pagination.
- Design a small relational schema with primary keys, foreign keys, unique, `NOT NULL` and `CHECK` constraints.
- Explain why constraints belong in the database even when the service validates input.
- Use `INSERT`, `UPDATE`, `DELETE`, `ON CONFLICT` and explicit transactions safely.
- Predict how `NULL` and three-valued logic affect predicates.
- Use `EXPLAIN (ANALYZE, BUFFERS)` as evidence rather than guessing about performance.

## Big picture

```text
HTTP request
    |
    v
Backend service / ORM
    |
    v
SQL + parameters
    |
    v
PostgreSQL connection
    |
    +--> Parser and analyzer
    |
    +--> Planner / optimizer
    |
    +--> Executor
              |
              +--> indexes
              +--> buffer cache
              +--> heap/table pages
              +--> WAL and transaction visibility
```

The application describes *what* it wants. PostgreSQL decides *how* to obtain it while preserving the relational and transactional rules declared in the schema.

## Lessons

1. [Database, DBMS, SQL and PostgreSQL](01-database-dbms-sql-postgresql.md)
2. [Query lifecycle and `SELECT`](02-query-lifecycle-and-select.md)
3. [DDL, data types and constraints](03-ddl-data-types-and-constraints.md)
4. [DML and transaction boundaries](04-dml-and-transactions.md)
5. [Filtering, `NULL` and three-valued logic](05-filtering-null-and-case.md)

## Shared lab data

Run the root bootstrap first. It creates the `sales` schema and deterministic seed data. The demo data is intentionally small for reasoning; the query-plan lab creates a temporary larger relation so plan choices become observable.

