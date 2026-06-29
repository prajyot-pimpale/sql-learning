# Module 07 — Subqueries

A subquery is a `SELECT` nested inside another SQL statement. It lets you use the result
of one query as an input to another — a value, a list, or a whole virtual table.

Tables used throughout:

```sql
CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50)
);
INSERT INTO departments VALUES (1, 'Sales'), (2, 'IT'), (3, 'HR');

CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    name        VARCHAR(50),
    salary      DECIMAL(10,2),
    dept_id     INT,
    manager_id  INT
);
INSERT INTO employees VALUES
(1, 'Asha',  55000, 1, NULL),
(2, 'Rohan', 72000, 2, NULL),
(3, 'Meera', 58000, 1, 1),
(4, 'Karan', 65000, 2, 2),
(5, 'Divya', 49000, 3, NULL),
(6, 'Tina',  81000, 2, 2);
```

## 1. Types of Subqueries — the Map

| Type | Returns | Used where |
|---|---|---|
| **Scalar** | a single value | anywhere a single value is expected (`WHERE col =`, `SELECT` list) |
| **Column/list** | a list of values | `IN`, `NOT IN`, `ANY`, `ALL` |
| **Table (derived table)** | multiple rows/columns | `FROM`, `JOIN` |
| **Correlated** | re-evaluated per outer row | `WHERE`, `SELECT` — references the outer query |

## 2. Scalar Subqueries — return exactly one value

### Scenario 1: Compare against a single computed value
```sql
SELECT name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);
```
The inner query computes one number (the average salary); the outer query compares each
row's salary against it. This is the most common subquery pattern of all.

### Scenario 2: Scalar subquery inside the SELECT list
```sql
SELECT name, salary,
       (SELECT AVG(salary) FROM employees) AS company_avg
FROM employees;
```
Every row shows its own salary *and* the constant company-wide average side by side —
useful for "how does this compare to the average" reports.

### Scenario 3: Scalar subquery with a correlated condition
```sql
SELECT name, salary, dept_id
FROM employees e
WHERE salary = (
    SELECT MAX(salary) FROM employees WHERE dept_id = e.dept_id
);
```
Finds the highest earner **within each department** — the inner query re-runs per
department because it references `e.dept_id` from the outer query. This is a
**correlated subquery** (more on this below).

## 3. Subqueries with `IN` / `NOT IN`

### Scenario 1: Employees in departments with more than 1 person
```sql
SELECT name, dept_id
FROM employees
WHERE dept_id IN (
    SELECT dept_id FROM employees GROUP BY dept_id HAVING COUNT(*) > 1
);
```

### Scenario 2: Employees who are NOT managers
```sql
SELECT name
FROM employees
WHERE emp_id NOT IN (
    SELECT manager_id FROM employees WHERE manager_id IS NOT NULL
);
```
> ⚠️ **Classic trap:** `NOT IN` behaves unexpectedly if the subquery's result contains
> any `NULL`. If even one row in the subquery has `manager_id = NULL`, the entire
> `NOT IN` comparison can return zero rows in some engines, because SQL can't prove
> "not equal to NULL." That's exactly why the example filters `WHERE manager_id IS NOT NULL`
> inside the subquery — always do this when using `NOT IN` with a nullable column.

## 4. `EXISTS` / `NOT EXISTS` — the safer alternative

`EXISTS` checks only whether the subquery returns *any* row at all — it doesn't care
about the actual values, which makes it immune to the NULL trap above, and often faster.

### Scenario 1: Departments that have at least one employee
```sql
SELECT d.dept_name
FROM departments d
WHERE EXISTS (
    SELECT 1 FROM employees e WHERE e.dept_id = d.dept_id
);
```
`SELECT 1` is a convention — the actual selected value doesn't matter for `EXISTS`, only
whether a row exists.

### Scenario 2: Departments with NO employees (mirrors the LEFT JOIN pattern from Module 05)
```sql
SELECT d.dept_name
FROM departments d
WHERE NOT EXISTS (
    SELECT 1 FROM employees e WHERE e.dept_id = d.dept_id
);
```

### Scenario 3: Employees who manage at least one person
```sql
SELECT name
FROM employees m
WHERE EXISTS (
    SELECT 1 FROM employees e WHERE e.manager_id = m.emp_id
);
```

## 5. Correlated Subqueries — Deep Dive

A **correlated subquery** references a column from the *outer* query — meaning it can't
run on its own; it re-executes once for every row the outer query considers. Compare:

```sql
-- NOT correlated — inner query is fully independent, runs once total
SELECT name FROM employees WHERE salary > (SELECT AVG(salary) FROM employees);

-- CORRELATED — inner query depends on e.dept_id, runs once PER outer row
SELECT name, salary
FROM employees e
WHERE salary > (SELECT AVG(salary) FROM employees WHERE dept_id = e.dept_id);
```
The second version finds employees earning above their **own department's** average —
a different, department-specific threshold per row, not one global number.

### Scenario: Second-highest salary using a correlated subquery
```sql
SELECT name, salary
FROM employees e1
WHERE 1 = (
    SELECT COUNT(*) FROM employees e2 WHERE e2.salary > e1.salary
);
```
Reads as: "give me the row where exactly 1 other employee earns more" — that's the
2nd-highest by definition. A classic interview-style query.

## 6. Subqueries in the `FROM` Clause (Derived Tables)

A subquery can act as a temporary, in-memory table you then query/join like any other.

### Scenario: Pre-aggregate, then filter the aggregate
```sql
SELECT dept_id, avg_salary
FROM (
    SELECT dept_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY dept_id
) AS dept_averages
WHERE avg_salary > 60000;
```
This achieves the same as a `HAVING` clause here, but derived tables become essential
once the logic is too complex for a single `GROUP BY`/`HAVING` — e.g., combining two
separate aggregations before comparing them.

> A derived table **must** have an alias (`AS dept_averages` above) — most engines
> require this even though the alias itself is never referenced elsewhere.

## 7. Subqueries vs Joins — When to Use Which

| Use a subquery when... | Use a join when... |
|---|---|
| You only need filtering/existence checks, not extra columns | You need columns from *both* tables in the final result |
| The logic reads more clearly nested (e.g., "above average") | You're combining and displaying related data side by side |
| You need a pre-aggregated value to compare against | Performance matters at scale (joins are usually optimized better) |

In practice, most things you can do with a subquery, you can also do with a join — and
vice versa. Readability for the specific case usually wins.

## 8. Common Mistakes

```sql
-- MISTAKE: NOT IN with NULLs in the subquery — silently returns nothing
SELECT name FROM employees WHERE emp_id NOT IN (SELECT manager_id FROM employees);
-- manager_id has NULLs → fix by filtering them out inside the subquery

-- MISTAKE: scalar subquery accidentally returning multiple rows
SELECT name FROM employees WHERE dept_id = (SELECT dept_id FROM employees);
-- Error: subquery returns more than 1 row — use IN instead of = here

-- MISTAKE: forgetting the alias on a derived table
SELECT * FROM (SELECT dept_id, COUNT(*) FROM employees GROUP BY dept_id);
-- Error in most engines: every derived table requires an alias
```

## 9. Self-check before Module 08

1. What's the difference between a scalar subquery and a correlated subquery?
2. Why is `EXISTS` often safer than `IN`/`NOT IN` when NULLs are involved?
3. Why must a subquery in the `FROM` clause always have an alias?
4. How would you find the 3rd-highest salary using the "count how many earn more"
   pattern shown above?

---
**Previous:** [Module 06 — Aggregation](../06-aggregation/README.md)
**Next:** [Module 08 — Functions](../08-functions/README.md) *(coming next)*