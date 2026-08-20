# Foundation Knowledge Check

Answer without looking at the solution file.

1. **Multiple choice:** Which component chooses between a sequential scan and an index scan?
   - A. SQL client
   - B. Query planner/optimizer
   - C. Foreign key
   - D. Connection pool

2. **True/false:** A table has a guaranteed physical row order if it has a primary key.

3. **Short answer:** Why should an API top-N query normally include a deterministic `ORDER BY`?

4. **Predict the output:** Which expression is `TRUE`?

   ```sql
   SELECT NULL = NULL, NULL IS NULL, NULL <> 10;
   ```

5. **Multiple choice:** Which constraint protects that every order references an existing customer?
   - A. `CHECK`
   - B. `UNIQUE`
   - C. `FOREIGN KEY`
   - D. `DEFAULT`

6. **Explain why:** Why can a foreign key be correct but still leave a join slow?

7. **Query analysis:** What is wrong with this query for the month of March?

   ```sql
   WHERE date(ordered_at) BETWEEN DATE '2025-03-01' AND DATE '2025-03-31'
   ```

8. **True/false:** `EXPLAIN ANALYZE` executes the statement being analyzed.

9. **Short answer:** What should an application do if a transaction receives a serialization failure?

10. **Multiple choice:** Which operation removes the table definition?
    - A. `DELETE`
    - B. `TRUNCATE`
    - C. `DROP TABLE`
    - D. `VACUUM`

11. **Predict the result:** Why can `NOT IN` return no rows when its subquery contains `NULL`?

12. **Engineering reasoning:** Give one reason to enforce an invariant in both the service and database.

