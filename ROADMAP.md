# Database Master Roadmap

## Learning path

| Phase | Module | Main outcomes | Status |
| --- | --- | --- | --- |
| 0 | Orientation | Database mental model, tools, study workflow | Foundation Sprint |
| 1 | SQL foundations | `SELECT`, DDL, constraints, DML, transactions | Foundation Sprint |
| 2 | Querying data | Filtering, `NULL`, `CASE`, sorting, pagination | Foundation Sprint |
| 3 | Combining data | Inner/outer joins, anti-joins, set operators | Planned |
| 4 | Transformation and analytics | Strings, dates, numeric functions, aggregates | Planned |
| 5 | Window functions | Aggregate, ranking and value windows | Planned |
| 6 | Complex SQL | Subqueries, CTEs, views, CTAS, temp tables | Planned |
| 7 | Server-side programming | Functions, procedures, triggers and error handling | Planned |
| 8 | Performance engineering | Indexes, statistics, execution plans, `VACUUM` | Planned |
| 9 | Partitioning | Declarative partitioning, pruning and lifecycle operations | Planned |
| 10 | Data warehouse project | Bronze/Silver/Gold pipelines and dimensional modeling | Planned |
| 11 | Analytics project | EDA, metrics, reports and business questions | Planned |
| 12 | Production review | Interview questions, failure scenarios and design trade-offs | Planned |

## Lesson workflow

Each substantive lesson follows:

```text
Why -> What -> How -> SQL -> Internals -> Trade-offs -> Production -> Practice
```

The lesson must explain the raw database behavior before showing ORM syntax. Small transcript videos that teach the same idea are grouped into one coherent lesson to reduce repetition.

## Canonical demo domain

The course uses a small e-commerce sales domain:

```text
customers 1 ---- n orders 1 ---- n order_items n ---- 1 products
```

The same business domain will later feed the Bronze/Silver/Gold warehouse project and analytics reports. Foundation data is synthetic and deterministic so that expected results remain reproducible.

## Source boundaries

The source folder contains both Java and SQL transcript material. Only the numbered SQL course transcript is in scope. The Java transcript is unrelated and remains outside this repository.

