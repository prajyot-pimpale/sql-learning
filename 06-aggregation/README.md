# Module 06 — Aggregation

Aggregation turns many rows into a summary: totals, averages, counts. This is the
backbone of every "report" you've ever seen — total sales by region, average order
value, headcount by department.

Table used throughout (same `employees`/`departments` from Module 05, repeated here):

```sql
CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50)
);
INSERT INTO departments VALUES (1, 'Sales'), (2, 'IT'), (3, 'HR'), (4, 'Marketing');

CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    name        VARCHAR(50),
    salary      DECIMAL(10,2),
    dept_id     INT
);
INSERT INTO employees VALUES
(1, 'Asha',  55000, 1),
(2, 'Rohan', 72000, 2),
(3, 'Meera', 58000, 1),
(4, 'Karan', 65000, 2),
(5, 'Divya', 49000, 3),
(6, 'Tina',  81000, 2),
(7, 'Sam',   47000, 1);
```

## 1. Aggregate Functions — the Core Five

| Function | Purpose |
|---|---|
| `COUNT()` | how many rows |
| `SUM()` | total of a numeric column |
| `AVG()` | average of a numeric column |
| `MIN()` | smallest value |
| `MAX()` | largest value |

### Scenario 1: Count all rows
```sql
SELECT COUNT(*) FROM employees;
```
Returns `7`. `COUNT(*)` counts rows regardless of NULLs in any column.

### Scenario 2: Count non-NULL values in a specific column
```sql
SELECT COUNT(dept_id) FROM employees;
```
If some employees had `dept_id = NULL`, this count would be lower than `COUNT(*)` —
`COUNT(column)` ignores NULLs in that column.

### Scenario 3: Count distinct values
```sql
SELECT COUNT(DISTINCT dept_id) FROM employees;
```
Returns `3` — the number of *different* departments represented, not total rows.

### Scenario 4: Sum
```sql
SELECT SUM(salary) FROM employees;
```
Total payroll across all employees: `427000`.

### Scenario 5: Average
```sql
SELECT AVG(salary) FROM employees;
```

### Scenario 6: Min and Max together
```sql
SELECT MIN(salary) AS lowest, MAX(salary) AS highest FROM employees;
```

### Scenario 7: Combine multiple aggregates in one query
```sql
SELECT
    COUNT(*)      AS total_employees,
    SUM(salary)   AS total_payroll,
    AVG(salary)   AS avg_salary,
    MIN(salary)   AS min_salary,
    MAX(salary)   AS max_salary
FROM employees;
```
This single query gives you a complete summary row — extremely common in dashboards.

## 2. `GROUP BY` — Aggregating per Category

Without `GROUP BY`, aggregates summarize the *entire* table into one row. `GROUP BY`
splits the table into buckets first, then aggregates *within* each bucket.

### Scenario 1: Count employees per department
```sql
SELECT dept_id, COUNT(*) AS employee_count
FROM employees
GROUP BY dept_id;
```
**Result:**
| dept_id | employee_count |
|---|---|
| 1 | 3 |
| 2 | 3 |
| 3 | 1 |

### Scenario 2: Total and average salary per department
```sql
SELECT dept_id, SUM(salary) AS total_salary, AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id;
```

### Scenario 3: Group by department NAME — needs a JOIN first
```sql
SELECT d.dept_name, COUNT(*) AS employee_count, AVG(e.salary) AS avg_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name;
```
This is the realistic version of the query — readable department names instead of raw IDs.

### Scenario 4: Group by multiple columns
```sql
-- imagine an added 'level' column: 'Junior'/'Senior'
SELECT dept_id, level, COUNT(*) 
FROM employees
GROUP BY dept_id, level;
```
Creates one row per *combination* of `dept_id` and `level` — not per `dept_id` alone.

### ⚠️ The #1 `GROUP BY` rule
Every column in your `SELECT` list must be either:
1. Inside an aggregate function (`COUNT()`, `SUM()`, etc.), **or**
2. Listed in the `GROUP BY` clause.

```sql
-- ERROR in PostgreSQL/standard SQL (MySQL may silently allow it, with undefined results)
SELECT dept_id, name, COUNT(*) FROM employees GROUP BY dept_id;
-- 'name' isn't aggregated and isn't in GROUP BY — which name would it even show per group?
```

## 3. `HAVING` — Filtering AFTER Aggregation

`WHERE` filters rows *before* grouping. `HAVING` filters *groups* after aggregation.
You cannot use an aggregate function inside `WHERE` — that's exactly what `HAVING` is for.

### Scenario 1: Departments with more than 1 employee
```sql
SELECT dept_id, COUNT(*) AS employee_count
FROM employees
GROUP BY dept_id
HAVING COUNT(*) > 1;
```
Excludes HR (only 1 employee).

### Scenario 2: Departments where average salary exceeds 60000
```sql
SELECT dept_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id
HAVING AVG(salary) > 60000;
```

### Scenario 3: Combine WHERE (row-level) + HAVING (group-level)
```sql
SELECT dept_id, AVG(salary) AS avg_salary
FROM employees
WHERE salary > 45000              -- filter rows first
GROUP BY dept_id
HAVING AVG(salary) > 55000;       -- then filter resulting groups
```
This is the pattern that confuses beginners most — internalize the order: filter rows
(`WHERE`) → group them (`GROUP BY`) → filter groups (`HAVING`).

## 4. The Real Logical Execution Order (extending Module 01)

```
FROM      → which table(s), including JOINs
WHERE     → filter individual rows
GROUP BY  → bucket rows into groups
HAVING    → filter groups
SELECT    → pick/compute final columns
ORDER BY  → sort the final result
LIMIT     → cut down to N rows
```
This explains a lot of "why doesn't this work" moments — e.g., why you **can't** filter
on an alias defined in `SELECT` inside a `WHERE` clause (because `WHERE` runs before
`SELECT` logically), but you often *can* in `ORDER BY` (which runs after).

```sql
-- This FAILS in most engines:
SELECT salary * 12 AS annual_salary FROM employees WHERE annual_salary > 600000;
-- annual_salary doesn't exist yet when WHERE runs

-- This WORKS:
SELECT salary * 12 AS annual_salary FROM employees ORDER BY annual_salary DESC;
-- ORDER BY runs after SELECT, so the alias already exists
```

## 5. Putting It All Together

```sql
SELECT d.dept_name, COUNT(*) AS headcount, AVG(e.salary) AS avg_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 45000
GROUP BY d.dept_name
HAVING COUNT(*) >= 2
ORDER BY avg_salary DESC;
```
Read in plain English: "department name, headcount, and average salary, from employees
joined to departments, where salary is above 45000, grouped by department, keeping only
departments with at least 2 such employees, sorted by average salary descending."

## 6. Common Mistakes

```sql
-- MISTAKE: aggregate in WHERE instead of HAVING
SELECT dept_id, COUNT(*) FROM employees WHERE COUNT(*) > 1 GROUP BY dept_id;
-- Error: aggregate functions are not allowed in WHERE

-- MISTAKE: non-aggregated, non-grouped column in SELECT
SELECT dept_id, name, AVG(salary) FROM employees GROUP BY dept_id;
-- Ambiguous: which 'name' would represent the whole group?

-- MISTAKE: forgetting COUNT(*) counts rows, COUNT(column) skips NULLs in that column
SELECT COUNT(*), COUNT(dept_id) FROM employees;
-- These can differ if dept_id has NULLs anywhere
```

## 7. Self-check before Module 07

1. What's the difference between `WHERE` and `HAVING`?
2. Why can't you reference a `SELECT`-list alias inside `WHERE`?
3. What rule governs which columns are allowed in `SELECT` when using `GROUP BY`?
4. How would you find departments with average salary above 50000, but only counting
   employees hired before 2023?

---
**Previous:** [Module 05 — Joins](../05-joins/README.md)
**Next:** [Module 07 — Subqueries](../07-subqueries/README.md) *(coming next)*