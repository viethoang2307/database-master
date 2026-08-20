# Lesson 1 — Database, DBMS, SQL and PostgreSQL

## Lesson overview

The transcript begins with the motivation for databases: applications and businesses create more data than is practical to manage as unrelated files. This lesson repairs the simplified “database is a container” explanation and introduces the components a backend engineer actually operates.

### Prerequisites

Basic command-line use, simple programming variables and a rough understanding of tables are sufficient. No ORM knowledge is assumed.

### Learning objectives

By the end of this lesson, you should be able to:

- Define database, DBMS, SQL, schema, relation, tuple and attribute.
- Explain why a DBMS is more than a file format.
- Distinguish a PostgreSQL server, database, schema and table.
- Identify which work belongs to the application and which work belongs to PostgreSQL.
- Connect to the lab database and verify its identity.

## Big picture

```text
Backend application
        |
        | parameterized SQL over a connection
        v
PostgreSQL server process
        |
        +--> database: database_master
                  |
                  +--> schema: sales
                            |
                            +--> tables, indexes, constraints
```

A database is a logical collection of related objects. A DBMS is the software that parses SQL, stores and retrieves data, enforces permissions and constraints, coordinates concurrent work, and recovers from failures. PostgreSQL is a DBMS; `database_master` is one database managed by a PostgreSQL server.

## Concept: database versus DBMS

### Intuition

A file can hold bytes. A DBMS gives those bytes meaning and controlled operations: it can reject an invalid foreign key, isolate two transactions, recover committed changes after a crash, and choose an access path for a query.

### Formal definition

- A **database** is an organized collection of persistent data and metadata.
- A **DBMS** is software that defines, stores, queries and manages databases.
- **SQL** is a declarative language used to define structures, manipulate data and query relational data. SQL itself does not specify every implementation detail of a DBMS.

### Why it exists

Backend systems need shared, durable, concurrent and queryable state. A collection of JSON files does not automatically provide constraints, transactions, indexes, recovery or safe concurrent updates.

### How it works

1. A client opens a connection to a server.
2. The client sends SQL and parameter values.
3. PostgreSQL parses and analyzes the statement against catalog metadata.
4. The planner chooses an execution plan.
5. The executor reads or writes pages through the buffer manager.
6. For a write, PostgreSQL records enough information in WAL and makes the change visible according to transaction rules.

### Production notes

The database is not “just a persistence layer.” It is part of the correctness boundary. A service-level validation can improve user feedback, but only a database constraint protects data when another service, script, job or race condition writes the same tables.

## Concept: schema, table, row and column

In the relational model, a table represents a relation, a row represents a tuple, and a column represents an attribute with a declared type. PostgreSQL schemas provide namespaces inside a database; `sales.orders` means table `orders` in schema `sales`.

The words are related but not interchangeable:

| Term | Meaning | Example |
| --- | --- | --- |
| Server | PostgreSQL instance accepting connections | Docker `postgres` service |
| Database | Logical database selected by a connection | `database_master` |
| Schema | Namespace inside a database | `sales` |
| Table | Persistent relation of rows and columns | `sales.orders` |
| Row/tuple | One record in a relation | Order `1001` |
| Column/attribute | Typed value position | `ordered_at` |

## SQL example

```sql
SELECT
    current_database() AS database_name,
    current_schema() AS default_schema,
    current_user AS connected_role,
    version() AS server_version;
```

Expected result: one row identifying the active database, current schema, role and PostgreSQL version. This is useful when a query behaves differently because it was run against the wrong database, role or server version.

## Internal behavior

PostgreSQL stores object definitions in system catalogs. When it analyzes `sales.orders`, it resolves the schema-qualified table name, checks column names and types, and verifies privileges. The catalog is metadata used by the parser, planner and administration tools; it is not the business data itself.

## Backend and ORM perspective

```text
Controller -> service transaction -> repository/ORM -> connection pool -> PostgreSQL
```

JPA/Hibernate hides the connection and SQL construction, but it still sends SQL to a DBMS. A `@ManyToOne` mapping does not replace a foreign key, and an entity validation annotation does not replace a database `CHECK` or `NOT NULL` constraint.

## Common misconceptions

**“SQL is the database.”** SQL is a language. PostgreSQL is the DBMS executing it.

**“A database guarantees security automatically.”** Security requires roles, privileges, network controls, secret management, auditing and safe query construction. A DBMS provides mechanisms; production configuration determines the result.

**“The ORM is the source of truth.”** The deployed database schema and its constraints are the final authority for stored data.

## Lab

Run:

```powershell
./scripts/bootstrap.ps1
```

Then inspect:

```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('sales', 'lab')
ORDER BY table_schema, table_name;
```

## Mental models

- A database is durable shared state; a DBMS is the system that makes that state queryable, consistent and recoverable.
- A schema is a namespace, not a security boundary by itself.
- SQL states the desired result; the optimizer chooses an implementation.

## Interview questions

1. **Junior — What is the difference between a database and a DBMS?**  A database is the organized data; a DBMS is the software that manages storage, queries, constraints, concurrency and recovery.
2. **Junior — What is a schema in PostgreSQL?**  A namespace inside a database that groups objects such as tables, views and functions.
3. **Mid — Why keep constraints in the database if the API validates input?**  Multiple writers and races can bypass API validation; database constraints protect the invariant at the final write boundary.
4. **Senior — Why can the same SQL query have different performance after moving servers?**  Planner statistics, indexes, data distribution, configuration, PostgreSQL version and hardware can change the chosen plan and I/O cost.
5. **Senior — Why is SQL called declarative?**  It describes the result or operation rather than prescribing a complete algorithm; the DBMS can choose among valid execution strategies.

## References

- [PostgreSQL Architecture](https://www.postgresql.org/docs/current/tutorial-arch.html)
- [PostgreSQL Database Access Control](https://www.postgresql.org/docs/current/ddl-priv.html)
- [PostgreSQL Schemas](https://www.postgresql.org/docs/current/ddl-schemas.html)

