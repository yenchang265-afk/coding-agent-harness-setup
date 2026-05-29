## Data — Oracle & MariaDB (OLTP)

### Portability
- Target both engines. Avoid vendor-only syntax unless isolated and documented:
  - Pagination: prefer `OFFSET ... FETCH NEXT ... ROWS ONLY` (works on modern Oracle and MariaDB) over `ROWNUM`/`LIMIT` mixing.
  - Identifiers: lower_snake_case, unquoted; don't rely on Oracle's uppercasing.
  - Types: use portable types (`VARCHAR`, `NUMERIC`/`DECIMAL`, `TIMESTAMP`); note Oracle `NUMBER` vs MariaDB numeric differences.

### Safety
- **Parameter-bind everything.** Never concatenate user input into SQL.
- Every `UPDATE`/`DELETE` has a `WHERE`; review for accidental full-table writes.
- Wrap multi-statement changes in explicit transactions.

### Schema & performance
- All schema changes via Flyway/Liquibase migrations, reviewed and reversible.
- Index the columns you filter/join on; check the execution plan for new heavy queries.
- Avoid `SELECT *` in application code; list columns explicitly.
