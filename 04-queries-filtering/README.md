# Module 04 — Queries & Filtering

This module is the one you'll use the most, every single day. We go deep on `WHERE`,
comparison/logical operators, pattern matching, ranges, sorting, and limiting results.

Table used throughout:

```sql
CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    name        VARCHAR(50),
    department  VARCHAR(50),
    salary      DECIMAL(10,2),
    hire_date   DATE,
    manager_id  INT
);

INSERT INTO employees VALUES
(1, 'Asha',  'Sales', 55000, '2021-03-01', NULL),
(2, 'Rohan', 'IT',    72000, '2020-07-15', NULL),
(3, 'Meera', 'Sales', 58000, '2022-01-10', 1),
(4, 'Karan', 'IT',    65000, '2023-05-20', 2),
(5, 'Divya', 'HR',    49000, '2021-11-30', NULL),
(6, 'Tina',  'IT',    81000, '2019-09-05', 2),
(7, 'Sam',   'Sales', 47000, '2023-02-14', 1);
```

## 1. Comparison Operators

| Operator | Meaning |
|---|---|
| `=` | equal |
| `!=` or `<>` | not equal |
| `>` `<` `>=` `<=` | greater/less than (or equal) |

### Scenario 1: Equality
```sql
SELECT * FROM employees WHERE department = 'IT';
```

### Scenario 2: Not equal
```sql
SELECT * FROM employees WHERE department <> 'IT';
```

### Scenario 3: Greater than
```sql
SELECT name, salary FROM employees WHERE salary > 60000;
```

## 2. Logical Operators — `AND`, `OR`, `NOT`

### Scenario 1: AND — both conditions must be true
```sql
SELECT * FROM employees WHERE department = 'IT' AND salary > 70000;
```
Returns Rohan and Tina only — Karan is IT but under 70000, so excluded.

### Scenario 2: OR — either condition true
```sql
SELECT * FROM employees WHERE department = 'HR' OR salary > 80000;
```
Returns Divya (HR) and Tina (salary 81000), even though Tina isn't HR.

### Scenario 3: NOT — negate a condition
```sql
SELECT * FROM employees WHERE NOT department = 'Sales';
```
Same result as `department <> 'Sales'`.

### Scenario 4: Combining AND/OR — use parentheses, always
```sql
SELECT * FROM employees
WHERE department = 'Sales' AND (salary > 50000 OR hire_date < '2022-01-01');
```
**Critical habit:** without parentheses, `AND` has higher precedence than `OR`, so
`A OR B AND C` is evaluated as `A OR (B AND C)` — not `(A OR B) AND C`. This causes
silent bugs. Always parenthesize when mixing `AND`/`OR`.

## 3. Range Filtering — `BETWEEN`

### Scenario 1: Numeric range
```sql
SELECT name, salary FROM employees WHERE salary BETWEEN 50000 AND 70000;
```
**Inclusive** on both ends — includes exactly 50000 and exactly 70000.

### Scenario 2: Date range
```sql
SELECT name, hire_date FROM employees
WHERE hire_date BETWEEN '2021-01-01' AND '2022-12-31';
```

### Scenario 3: NOT BETWEEN
```sql
SELECT name, salary FROM employees WHERE salary NOT BETWEEN 50000 AND 70000;
```

## 4. Set Membership — `IN` / `NOT IN`

### Scenario 1: Match any value in a list
```sql
SELECT * FROM employees WHERE department IN ('Sales', 'HR');
```
Cleaner than `department = 'Sales' OR department = 'HR'` — same result, more readable,
especially as the list grows.

### Scenario 2: Exclude a list
```sql
SELECT * FROM employees WHERE department NOT IN ('IT');
```

### Scenario 3: IN with a subquery (preview — full depth in Module 07)
```sql
SELECT * FROM employees
WHERE manager_id IN (SELECT emp_id FROM employees WHERE department = 'IT');
```

## 5. Pattern Matching — `LIKE`

| Wildcard | Meaning |
|---|---|
| `%` | zero or more characters |
| `_` | exactly one character |

### Scenario 1: Starts with
```sql
SELECT * FROM employees WHERE name LIKE 'A%';
```
Matches "Asha".

### Scenario 2: Ends with
```sql
SELECT * FROM employees WHERE name LIKE '%a';
```
Matches "Asha", "Meera", "Tina" — anything ending in 'a'.

### Scenario 3: Contains
```sql
SELECT * FROM employees WHERE name LIKE '%an%';
```
Matches "Rohan", "Karan" — 'an' anywhere in the string.

### Scenario 4: Exactly N characters using `_`
```sql
SELECT * FROM employees WHERE name LIKE '____'; -- exactly 4 characters
```
Matches "Tina", "Asha", "Sam " — wait, "Sam" is 3 chars so it wouldn't match; this
matches exactly 4-letter names like "Tina", "Asha".

### Scenario 5: Case sensitivity caveat
> `LIKE` is case-**insensitive** in MySQL/SQLite by default, but case-**sensitive** in
> PostgreSQL. Use `ILIKE` in PostgreSQL for case-insensitive matching:
> ```sql
> SELECT * FROM employees WHERE name ILIKE 'a%';  -- PostgreSQL only
> ```

## 6. NULL Checks — Recap from Module 01

### Scenario 1: Find rows with no manager
```sql
SELECT * FROM employees WHERE manager_id IS NULL;
```

### Scenario 2: Find rows with a manager
```sql
SELECT * FROM employees WHERE manager_id IS NOT NULL;
```

## 7. Sorting — `ORDER BY`

### Scenario 1: Ascending (default)
```sql
SELECT name, salary FROM employees ORDER BY salary;
```

### Scenario 2: Descending
```sql
SELECT name, salary FROM employees ORDER BY salary DESC;
```

### Scenario 3: Sort by multiple columns
```sql
SELECT name, department, salary
FROM employees
ORDER BY department ASC, salary DESC;
```
Groups by department alphabetically, and within each department, highest salary first.

### Scenario 4: Sort by column position (works, but avoid in real code — fragile)
```sql
SELECT name, salary FROM employees ORDER BY 2 DESC; -- sorts by 2nd column (salary)
```

## 8. Limiting Results — `LIMIT` / `OFFSET`

### Scenario 1: Top N rows
```sql
SELECT name, salary FROM employees ORDER BY salary DESC LIMIT 3;
```
The 3 highest-paid employees.

### Scenario 2: Pagination with `OFFSET`
```sql
SELECT name, salary FROM employees ORDER BY salary DESC LIMIT 3 OFFSET 3;
```
Skips the first 3 (already shown on "page 1"), returns the next 3 ("page 2").

> SQL Server uses different syntax: `SELECT TOP 3 ...` instead of `LIMIT`, and
> `OFFSET 3 ROWS FETCH NEXT 3 ROWS ONLY` for pagination.

## 9. Putting It All Together

### Scenario: Real combined query
```sql
SELECT name, department, salary
FROM employees
WHERE department IN ('IT', 'Sales')
  AND salary > 50000
  AND manager_id IS NOT NULL
ORDER BY department ASC, salary DESC
LIMIT 5;
```
Read this top to bottom as plain English: "Give me name, department, and salary, from
employees, where the department is IT or Sales, and salary is above 50000, and they have
a manager, sorted by department then by salary descending, limited to 5 rows."

## 10. Common Mistakes

```sql
-- MISTAKE: mixing AND/OR without parentheses — silent logic bug
SELECT * FROM employees WHERE department = 'Sales' OR department = 'HR' AND salary > 50000;
-- Actually means: Sales (any salary) OR (HR AND salary > 50000) — probably not intended

-- MISTAKE: assuming BETWEEN is exclusive
SELECT * FROM employees WHERE salary BETWEEN 50000 AND 70000; -- includes 50000 and 70000

-- MISTAKE: forgetting % wildcards needed for LIKE partial match
SELECT * FROM employees WHERE name LIKE 'an'; -- matches nothing; needs '%an%'
```

## 11. Self-check before Module 05

1. Why should you always parenthesize when mixing `AND` and `OR`?
2. Is `BETWEEN 50000 AND 70000` inclusive or exclusive of the boundary values?
3. What's the difference between `%` and `_` in `LIKE` patterns?
4. How would you get rows 11–20 of a result set sorted by `hire_date`?

---
**Previous:** [Module 03 — DML](../03-dml/README.md)
**Next:** [Module 05 — Joins](../05-joins/README.md) *(coming next)*