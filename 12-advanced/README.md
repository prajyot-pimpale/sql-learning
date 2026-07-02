# Module 12 — Advanced SQL

The final module. Window functions and CTEs are what separate "knows basic SQL" from
"can write the queries data analysts/engineers actually use daily." Stored procedures and
triggers move logic *into* the database itself.

Table used throughout:

```sql
CREATE TABLE employees (
    emp_id    INT PRIMARY KEY,
    name      VARCHAR(50),
    dept_id   INT,
    salary    DECIMAL(10,2),
    hire_date DATE
);
INSERT INTO employees VALUES
(1, 'Asha',  1, 55000, '2021-03-01'),
(2, 'Rohan', 2, 72000, '2020-07-15'),
(3, 'Meera', 1, 58000, '2022-01-10'),
(4, 'Karan', 2, 65000, '2023-05-20'),
(5, 'Divya', 3, 49000, '2021-11-30'),
(6, 'Tina',  2, 81000, '2019-09-05');
```

## 1. Common Table Expressions (CTEs) — `WITH`

A CTE is a named, temporary result set you define with `WITH`, then reference in the main
query — like a derived table (Module 07) but more readable, and reusable multiple times
in the same query.

### Scenario 1: Basic CTE — replaces a nested subquery
```sql
WITH dept_averages AS (
    SELECT dept_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY dept_id
)
SELECT e.name, e.salary, d.avg_salary
FROM employees e
JOIN dept_averages d ON e.dept_id = d.dept_id
WHERE e.salary > d.avg_salary;
```
Compare this readability to the equivalent derived-table version from Module 07 — the
`WITH` block reads top-to-bottom like a sentence: "define this, then use it."

### Scenario 2: Multiple CTEs in one query
```sql
WITH dept_averages AS (
    SELECT dept_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY dept_id
),
high_avg_depts AS (
    SELECT dept_id FROM dept_averages WHERE avg_salary > 60000
)
SELECT e.name, e.dept_id
FROM employees e
WHERE e.dept_id IN (SELECT dept_id FROM high_avg_depts);
```
The second CTE can reference the first — they build on each other in sequence.

### Scenario 3: Recursive CTE — walking a hierarchy
```sql
-- Find an employee's full management chain upward
WITH RECURSIVE management_chain AS (
    -- base case: start with one employee
    SELECT emp_id, name, manager_id, 1 AS level
    FROM employees
    WHERE emp_id = 4

    UNION ALL

    -- recursive case: join to the next level up
    SELECT e.emp_id, e.name, e.manager_id, mc.level + 1
    FROM employees e
    JOIN management_chain mc ON e.emp_id = mc.manager_id
)
SELECT * FROM management_chain;
```
Recursive CTEs are how SQL handles hierarchical/tree data — org charts, category trees,
bill-of-materials — without knowing the depth in advance. The query repeats itself,
feeding each result back in, until no new rows are produced.

## 2. Window Functions — Calculations Across Rows Without Collapsing Them

`GROUP BY` collapses rows into one summary row per group. **Window functions** compute
something across a set of related rows, but keep every original row intact. This is the
single most useful "advanced" SQL feature for analytics.

General shape: `FUNCTION() OVER (PARTITION BY ... ORDER BY ...)`

### Scenario 1: Running total
```sql
SELECT name, salary,
    SUM(salary) OVER (ORDER BY emp_id) AS running_total
FROM employees;
```
Each row shows the cumulative sum of salary up to and including that row, ordered by `emp_id`.

### Scenario 2: Rank within the whole table
```sql
SELECT name, salary,
    RANK() OVER (ORDER BY salary DESC) AS salary_rank
FROM employees;
```
`RANK()` gives ties the *same* rank, then skips numbers (1, 2, 2, 4, ...).

### Scenario 3: `DENSE_RANK` — no gaps after ties
```sql
SELECT name, salary,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS salary_rank
FROM employees;
```
Ties still share a rank, but the next rank doesn't skip (1, 2, 2, 3, ...).

### Scenario 4: `ROW_NUMBER` — always unique, even with ties
```sql
SELECT name, salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_num
FROM employees;
```
Every row gets a distinct sequential number regardless of ties — useful for picking
"exactly 1 row per group" (see Scenario 6).

### Scenario 5: `PARTITION BY` — reset the calculation per group
```sql
SELECT name, dept_id, salary,
    RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rank_in_dept
FROM employees;
```
This is the window-function equivalent of "top earner per department" from Module 07's
correlated subquery — but cleaner, and it shows *all* employees with their rank, not just
the top one.

### Scenario 6: Top N per group, using ROW_NUMBER + a CTE
```sql
WITH ranked AS (
    SELECT name, dept_id, salary,
        ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rn
    FROM employees
)
SELECT name, dept_id, salary FROM ranked WHERE rn = 1;
```
This combo — window function inside a CTE, then filter on the row number — is the
standard way to get "the top (or top N) row(s) per group," a query shape that's
extremely common in real reporting and very awkward to write any other way.

### Scenario 7: `LAG` / `LEAD` — compare to the previous/next row
```sql
SELECT name, hire_date,
    LAG(name) OVER (ORDER BY hire_date) AS hired_before,
    LEAD(name) OVER (ORDER BY hire_date) AS hired_after
FROM employees;
```
`LAG` looks one row back, `LEAD` looks one row forward — by hire order here. Classic use:
month-over-month comparisons (`LAG(revenue) OVER (ORDER BY month)`).

### Scenario 8: Moving/rolling average
```sql
SELECT name, hire_date, salary,
    AVG(salary) OVER (ORDER BY hire_date ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS moving_avg
FROM employees;
```
Averages each row with its immediate neighbor before and after — the building block of
trend-smoothing in time-series reporting.

## 3. Stored Procedures — Reusable Logic Inside the Database

A stored procedure is a saved block of SQL (with parameters, logic, even loops) that you
call by name instead of retyping every time.

### Scenario: Basic stored procedure (PostgreSQL syntax)
```sql
CREATE OR REPLACE PROCEDURE give_raise(p_emp_id INT, p_amount DECIMAL)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE employees SET salary = salary + p_amount WHERE emp_id = p_emp_id;
    COMMIT;
END;
$$;

-- Call it:
CALL give_raise(1, 5000);
```
> MySQL syntax differs (`DELIMITER //`, `CREATE PROCEDURE ... END //`), but the core idea
> — parameters in, SQL logic inside, callable by name — is the same everywhere.

## 4. Triggers — Automatic Logic on Data Changes

A trigger automatically runs code when a specified event (`INSERT`/`UPDATE`/`DELETE`)
happens on a table — without anyone explicitly calling it.

### Scenario: Auto-log every salary change (PostgreSQL syntax)
```sql
CREATE TABLE salary_audit (
    audit_id   SERIAL PRIMARY KEY,
    emp_id     INT,
    old_salary DECIMAL,
    new_salary DECIMAL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_salary_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO salary_audit (emp_id, old_salary, new_salary)
    VALUES (OLD.emp_id, OLD.salary, NEW.salary);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_salary_change
AFTER UPDATE OF salary ON employees
FOR EACH ROW
EXECUTE FUNCTION log_salary_change();
```
Now every `UPDATE` that changes `salary` automatically writes a row to `salary_audit` —
no application code has to remember to log it; the database guarantees it happens.

## 5. When to Use What — Quick Decision Guide

| Need | Reach for |
|---|---|
| Reuse a complex query, make it readable | CTE (`WITH`) |
| Walk a hierarchy/tree of unknown depth | Recursive CTE |
| Rank, running totals, "top N per group" without collapsing rows | Window function |
| Reusable parameterized logic, callable on demand | Stored procedure |
| Logic that must happen automatically on every data change | Trigger |

## 6. Common Mistakes

```sql
-- MISTAKE: trying to use a window function result directly in WHERE
SELECT name, RANK() OVER (ORDER BY salary DESC) AS r FROM employees WHERE r = 1;
-- ERROR: window function result not available in WHERE (same execution-order issue from Module 06)
-- FIX: wrap in a CTE or subquery first, then filter
WITH ranked AS (
    SELECT name, RANK() OVER (ORDER BY salary DESC) AS r FROM employees
)
SELECT * FROM ranked WHERE r = 1;

-- MISTAKE: overusing triggers for logic that's clearer in application code
-- Triggers are powerful but invisible — someone reading application code won't see them.
-- Use sparingly, document heavily (e.g., audit logging, enforcing invariants only the DB can guarantee).
```

## 7. Self-check — Course Completion

1. What's the difference between a CTE and a derived table (subquery in FROM)?
2. When would you reach for `RANK()` vs `DENSE_RANK()` vs `ROW_NUMBER()`?
3. How does `PARTITION BY` change a window function's behavior compared to no partition?
4. Why can't you filter directly on a window function's result in `WHERE`?
5. What's the practical difference between a stored procedure and a trigger?

---
**Previous:** [Module 11 — Transactions](../11-transactions/README.md)

🎉 **You've completed the full course.** Next steps: pick a real dataset (Kaggle has many
free ones), load it into PostgreSQL or SQLite, and rewrite every query in this repo
against your own data — that's where it actually sticks.