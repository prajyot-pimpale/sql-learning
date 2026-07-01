# Module 10 — Views & Indexes

Two very different tools that both make working with data easier: **views** simplify how
you *read* complex queries, **indexes** make queries run *faster*. Neither changes the
underlying table data.

Tables used throughout:

```sql
CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50)
);
INSERT INTO departments VALUES (1, 'Sales'), (2, 'IT'), (3, 'HR');

CREATE TABLE employees (
    emp_id    INT PRIMARY KEY,
    name      VARCHAR(50),
    salary    DECIMAL(10,2),
    dept_id   INT,
    hire_date DATE
);
INSERT INTO employees VALUES
(1, 'Asha',  55000, 1, '2021-03-01'),
(2, 'Rohan', 72000, 2, '2020-07-15'),
(3, 'Meera', 58000, 1, '2022-01-10'),
(4, 'Karan', 65000, 2, '2023-05-20'),
(5, 'Divya', 49000, 3, '2021-11-30');
```

## 1. Views — A Saved, Reusable Query

A **view** is a virtual table: it stores a `SELECT` statement, not the actual data. Every
time you query the view, it re-runs the underlying query live.

### Scenario 1: Create a simple view
```sql
CREATE VIEW high_earners AS
SELECT name, salary, dept_id
FROM employees
WHERE salary > 60000;
```

### Scenario 2: Query a view exactly like a table
```sql
SELECT * FROM high_earners;
SELECT name FROM high_earners WHERE dept_id = 2;
```
You can filter, join, and aggregate against a view the same way you would a real table —
the database just substitutes the view's underlying query under the hood.

### Scenario 3: View that joins multiple tables (the most common real use case)
```sql
CREATE VIEW employee_directory AS
SELECT e.name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;
```
Now anyone (or any application/report tool) can write:
```sql
SELECT * FROM employee_directory WHERE dept_name = 'Sales';
```
...without needing to know or repeat the join logic every time. This is the #1 reason
views exist: **hiding complexity behind a simple, stable interface.**

### Scenario 4: View with aggregation
```sql
CREATE VIEW department_summary AS
SELECT d.dept_name, COUNT(*) AS headcount, AVG(e.salary) AS avg_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name;
```

### Scenario 5: Updating a view's definition
```sql
-- PostgreSQL
CREATE OR REPLACE VIEW high_earners AS
SELECT name, salary, dept_id FROM employees WHERE salary > 65000;

-- MySQL also supports CREATE OR REPLACE VIEW
```

### Scenario 6: Dropping a view
```sql
DROP VIEW IF EXISTS high_earners;
```

### Scenario 7: Can you `INSERT`/`UPDATE` through a view?
```sql
UPDATE high_earners SET salary = 70000 WHERE name = 'Rohan';
```
Sometimes — **simple views** (single table, no aggregation, no `DISTINCT`/`GROUP BY`)
are often updatable, and the change applies to the real underlying table. Views with
joins or aggregation are generally **not** updatable directly — the database can't know
which underlying row(s) you mean.

### Scenario 8: Materialized views (PostgreSQL — a different beast)
```sql
CREATE MATERIALIZED VIEW department_summary_cached AS
SELECT d.dept_name, COUNT(*) AS headcount, AVG(e.salary) AS avg_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name;

-- Data is now physically stored — fast to read, but goes stale until refreshed:
REFRESH MATERIALIZED VIEW department_summary_cached;
```
A regular view re-runs its query *every time* you read it — always fresh, but no faster
than the underlying query. A **materialized view** stores the result physically — much
faster to read, but you must manually `REFRESH` it to see new data. (MySQL has no native
materialized views — people emulate them with a real table + scheduled job.)

## 2. Indexes — Speeding Up Lookups

An index is a separate data structure (usually a B-tree) that lets the database find rows
matching a condition without scanning the entire table. Think of it like a book's index:
instead of reading every page to find "salary," you jump straight to the right page.

### Scenario 1: Create a basic index
```sql
CREATE INDEX idx_employees_dept_id ON employees(dept_id);
```
Now any query filtering or joining on `dept_id` can use this index instead of scanning
every row in `employees`.

### Scenario 2: Composite (multi-column) index
```sql
CREATE INDEX idx_employees_dept_salary ON employees(dept_id, salary);
```
Useful when queries commonly filter on *both* columns together, e.g.:
```sql
SELECT * FROM employees WHERE dept_id = 1 AND salary > 50000;
```
> Column order matters: this index helps queries filtering on `dept_id` alone, or on
> `dept_id` + `salary` together — but it does **not** help a query filtering on `salary`
> alone, since the index is sorted by `dept_id` first.

### Scenario 3: Unique index (this is what `UNIQUE`/`PRIMARY KEY` actually create behind the scenes)
```sql
CREATE UNIQUE INDEX idx_employees_email ON employees(email);
```

### Scenario 4: Viewing/checking existing indexes
```sql
-- PostgreSQL
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'employees';

-- MySQL
SHOW INDEX FROM employees;
```

### Scenario 5: Dropping an index
```sql
-- PostgreSQL
DROP INDEX idx_employees_dept_id;

-- MySQL
DROP INDEX idx_employees_dept_id ON employees;
```

### Scenario 6: Seeing whether a query actually uses an index
```sql
EXPLAIN SELECT * FROM employees WHERE dept_id = 1;
```
`EXPLAIN` shows the engine's query plan — whether it's doing a fast "index scan" or a
slow full "table scan." This is the standard first step in diagnosing a slow query.

## 3. The Tradeoff — Indexes Aren't Free

Indexes speed up `SELECT`/`WHERE`/`JOIN`/`ORDER BY` on indexed columns, but:
- They take up extra disk space.
- Every `INSERT`/`UPDATE`/`DELETE` must also update the index — write operations get
  *slower* as you add more indexes.
- Indexing every column "just in case" is a common beginner mistake — it slows writes
  significantly for marginal read benefit on columns rarely filtered.

**Rule of thumb:** index columns you frequently filter (`WHERE`), join (`JOIN ... ON`),
or sort (`ORDER BY`) on — especially on large tables. Don't index small lookup tables or
columns you never filter by.

## 4. Views vs Indexes — Different Jobs

| | Views | Indexes |
|---|---|---|
| Purpose | Simplify/reuse complex queries | Speed up data retrieval |
| Stores data? | No (regular view) / Yes (materialized) | Yes (separate structure) |
| Affects write speed? | No | Yes (slightly slower writes) |
| Affects read speed? | No (same as running the query directly) | Yes (faster reads on indexed columns) |

## 5. Common Mistakes

```sql
-- MISTAKE: expecting a regular view to be faster than the query it wraps
SELECT * FROM department_summary; -- runs the full underlying JOIN + GROUP BY every time

-- MISTAKE: indexing every column "to be safe"
CREATE INDEX idx1 ON employees(name);
CREATE INDEX idx2 ON employees(salary);
CREATE INDEX idx3 ON employees(hire_date);
-- ... if none of these are actually filtered on often, this only slows down writes

-- MISTAKE: forgetting column order matters in composite indexes
CREATE INDEX idx_dept_salary ON employees(dept_id, salary);
SELECT * FROM employees WHERE salary > 50000; -- this query gets little/no benefit from the index above
```

## 6. Self-check before Module 11

1. What's the core difference between a regular view and a materialized view?
2. Why aren't views with `JOIN`/`GROUP BY` usually updatable?
3. Why do indexes speed up reads but slow down writes?
4. In a composite index `(dept_id, salary)`, which queries benefit and which don't?

---
**Previous:** [Module 09 — Constraints & Keys](../09-constraints-keys/README.md)
**Next:** [Module 11 — Transactions](../11-transactions/README.md) *(coming next)*