# Lesson 4 — DML and Transaction Boundaries

## Lesson overview

Data Manipulation Language changes rows. The transcript introduces `INSERT`, `UPDATE` and `DELETE`; a backend engineer must also understand atomicity, retries, concurrent writers and the boundary at which a set of statements becomes one business operation.

### Learning objectives

- Use `INSERT`, `UPDATE`, `DELETE` and PostgreSQL `ON CONFLICT` safely.
- Explain autocommit versus an explicit transaction.
- Choose a transaction boundary for a multi-step service operation.
- Describe at a high level how WAL, MVCC and locks support writes.
- Identify a race condition that cannot be fixed by application validation alone.

## Intuition

A transaction is a logical unit of work. For an order placement, creating the order, inserting its items and reserving inventory should either all become visible together or none should become visible. A transaction is not automatically a distributed transaction across every service; it covers the database session/resources participating in that database transaction.

## Basic DML

```sql
INSERT INTO lab.inventory_reservations (order_id, product_id, reserved_quantity)
VALUES (1001, 1, 1)
ON CONFLICT (order_id, product_id)
DO UPDATE SET reserved_quantity = EXCLUDED.reserved_quantity,
              status = 'active';

UPDATE lab.inventory_reservations
SET status = 'fulfilled'
WHERE order_id = 1001
  AND product_id = 1;

DELETE FROM lab.inventory_reservations
WHERE status = 'released';
```

The `UPDATE` and `DELETE` predicates are part of the safety contract. Before running them in production, inspect the predicate with a `SELECT`, use a transaction where appropriate, and verify the affected-row count.

## Transaction mechanics

```sql
BEGIN;

INSERT INTO lab.inventory_reservations (order_id, product_id, reserved_quantity)
VALUES (1002, 3, 1)
ON CONFLICT (order_id, product_id)
DO UPDATE SET reserved_quantity = EXCLUDED.reserved_quantity;

UPDATE lab.inventory_reservations
SET status = 'fulfilled'
WHERE order_id = 1002
  AND product_id = 3;

COMMIT;
```

If any required step fails, the service should roll back the transaction and report/retry according to the error class. Autocommit means each statement may be committed separately, which is unsafe when multiple statements must form one invariant-preserving operation.

## What happens internally?

At a high level, PostgreSQL:

1. Assigns the transaction a snapshot/identity.
2. Executes row changes and records WAL information for durability/recovery.
3. Maintains row-version visibility metadata under MVCC rather than overwriting every reader's view in place.
4. Uses locks and conflict detection to coordinate concurrent operations.
5. On commit, makes the transaction's results visible according to isolation rules.
6. Later reclaims obsolete row versions through vacuuming.

This is an approximation for learning; exact behavior varies by operation and isolation level. PostgreSQL's default `READ COMMITTED` does not mean “no concurrency issues”; it defines a visibility model, not application-level business serialization.

## Production scenario: inventory race

Two requests both read `available = 1`, both decide they can reserve the item, and both write success. Application-side checks can race. Solutions include an atomic conditional update, a row lock with `SELECT ... FOR UPDATE`, a serializable transaction with retry, or a data model that expresses the invariant. The correct choice depends on contention and business semantics.

## Performance implications

- Large transactions hold resources longer, increase rollback cost and can delay vacuum progress.
- Batch DML reduces round trips but must be bounded to avoid oversized transactions.
- Indexes accelerate predicates but add write work and WAL/index maintenance.
- Retried serialization/deadlock failures must be safe under idempotency rules.

## ORM perspective

Spring's `@Transactional` defines a transaction boundary around the proxied method, but self-invocation, asynchronous execution and multiple data sources can change the actual behavior. Verify transaction propagation, isolation and connection usage rather than assuming the annotation is magic.

## Comparison: application validation versus database enforcement

| Approach | Strength | Limitation |
| --- | --- | --- |
| API validation | Fast feedback and friendly errors | Can be bypassed or race with another writer |
| Service transaction | Groups related statements | Only covers resources enlisted in that transaction |
| Database constraint | Enforces invariant at write boundary | Does not explain business intent to the user by itself |
| Lock/isolation strategy | Controls concurrent visibility/conflicts | Adds contention and may require retries |

## Common mistakes

- Opening a transaction around an entire HTTP request including remote calls.
- Treating a deadlock or serialization failure as an impossible bug instead of a retryable outcome.
- Retrying a non-idempotent `INSERT` without a request/idempotency key.
- Forgetting that a failed PostgreSQL statement marks the current transaction as aborted until rollback.
- Updating rows without checking the affected-row count.

## Lab

Run `sql/labs/02_constraints_and_rollback.sql`. It commits one valid reservation, deliberately violates a `CHECK`, then rolls back. Compare the result with the statements in `sql/foundations/03_dml_and_transactions.sql`, which rolls back the entire demonstration.

## Mental models

- A transaction is a correctness boundary, not merely a performance wrapper.
- `COMMIT` makes a group of database changes durable/visible as one outcome; it does not undo external side effects already sent to another system.
- MVCC gives transactions views of row versions; it does not eliminate the need to reason about invariants and conflicts.

## Interview questions

1. **Junior — What does `COMMIT` do?**  It ends the current transaction successfully and makes its changes durable/visible according to PostgreSQL's rules.
2. **Junior — Why is autocommit dangerous for an order placement flow?**  Each statement can commit independently, leaving partial state if a later statement fails.
3. **Mid — What should a service do after a deadlock or serialization failure?**  Abort the transaction, optionally retry the whole transaction with bounded backoff when the operation is safe to retry.
4. **Mid — What problem does `ON CONFLICT` solve?**  It turns a uniqueness conflict into an explicit insert-or-update decision, avoiding a fragile check-then-insert race.
5. **Senior — Why does a database transaction not automatically include a message broker call?**  The broker and database have independent commit protocols; cross-system atomicity needs an explicit pattern such as an outbox and reliable publication.

## References

- [PostgreSQL Transactions](https://www.postgresql.org/docs/current/tutorial-transactions.html)
- [PostgreSQL Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html)
- [PostgreSQL `INSERT ... ON CONFLICT`](https://www.postgresql.org/docs/current/sql-insert.html)
- [PostgreSQL Explicit Locking](https://www.postgresql.org/docs/current/explicit-locking.html)
- [PostgreSQL `VACUUM`](https://www.postgresql.org/docs/current/sql-vacuum.html)

