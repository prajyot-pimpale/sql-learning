# Module 08 — Functions

SQL ships with built-in functions for manipulating text, numbers, dates, and for
conditional logic inside a query. Function names differ more across engines here than
anywhere else in this course — every section calls out the dialect differences clearly.

Table used throughout:

```sql
CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    first_name  VARCHAR(50),
    last_name   VARCHAR(50),
    email       VARCHAR(100),
    salary      DECIMAL(10,2),
    hire_date   DATE
);
INSERT INTO employees VALUES
(1, 'Asha',  'Mehta',  'asha.mehta@co.com',  55250.456, '2021-03-01'),
(2, 'Rohan', 'Verma',  'rohan.verma@co.com', 72000.00,  '2020-07-15'),
(3, 'Meera', 'Iyer',   'meera.iyer@co.com',  58000.00,  '2022-01-10');
```

## 1. String Functions

| Function | Purpose |
|---|---|
| `CONCAT()` | join strings together |
| `UPPER()` / `LOWER()` | change case |
| `LENGTH()` / `LEN()` | string length |
| `TRIM()` | remove leading/trailing whitespace |
| `SUBSTRING()` | extract part of a string |
| `REPLACE()` | swap text within a string |

### Scenario 1: Concatenate first and last name
```sql
SELECT CONCAT(first_name, ' ', last_name) AS full_name FROM employees;
```
> PostgreSQL also supports the `||` operator: `SELECT first_name || ' ' || last_name`.
> SQL Server traditionally used `+` instead of `CONCAT()` in older versions.

### Scenario 2: Change case
```sql
SELECT UPPER(first_name) AS upper_name, LOWER(email) AS lower_email FROM employees;
```

### Scenario 3: String length
```sql
SELECT first_name, LENGTH(first_name) AS name_length FROM employees;
```
> SQL Server uses `LEN()` instead of `LENGTH()`.

### Scenario 4: Extract a substring
```sql
SELECT email, SUBSTRING(email, 1, 4) AS first_four_chars FROM employees;
```
`SUBSTRING(string, start_position, length)` — 1-indexed (the first character is position 1, not 0).

### Scenario 5: Find and replace text
```sql
SELECT REPLACE(email, '@co.com', '@newdomain.com') AS updated_email FROM employees;
```

### Scenario 6: Trim whitespace
```sql
SELECT TRIM('  Asha  ') AS cleaned;  -- returns 'Asha'
```

### Scenario 7: Combine string functions
```sql
SELECT CONCAT(UPPER(first_name), ' ', UPPER(last_name)) AS full_name_caps
FROM employees;
```

## 2. Numeric Functions

| Function | Purpose |
|---|---|
| `ROUND()` | round to N decimal places |
| `CEIL()` / `CEILING()` | round up |
| `FLOOR()` | round down |
| `ABS()` | absolute value |
| `POWER()` | exponentiation |
| `MOD()` | remainder (also `%`) |

### Scenario 1: Round salary to 2 decimals
```sql
SELECT salary, ROUND(salary, 2) AS rounded_salary FROM employees;
```
Asha's `55250.456` becomes `55250.46`.

### Scenario 2: Round to nearest thousand (negative decimal places)
```sql
SELECT salary, ROUND(salary, -3) AS nearest_thousand FROM employees;
```
`72000.00` stays `72000`; `55250.456` becomes `55000`.

### Scenario 3: Ceiling and floor
```sql
SELECT salary, CEIL(salary / 1000) AS ceil_thousands, FLOOR(salary / 1000) AS floor_thousands
FROM employees;
```

### Scenario 4: Absolute value
```sql
SELECT ABS(-150) AS abs_value; -- returns 150
```

### Scenario 5: Modulo — check even/odd, or cyclic logic
```sql
SELECT emp_id, emp_id % 2 AS remainder FROM employees;
-- remainder = 0 means even emp_id, 1 means odd
```

## 3. Date Functions

These vary the most by engine — examples below note exactly which engine each syntax targets.

### Scenario 1: Current date/time
```sql
SELECT CURRENT_DATE;       -- PostgreSQL, MySQL
SELECT CURRENT_TIMESTAMP;  -- most engines
SELECT NOW();               -- MySQL, PostgreSQL
```

### Scenario 2: Extract part of a date
```sql
-- PostgreSQL / MySQL
SELECT name, hire_date, EXTRACT(YEAR FROM hire_date) AS hire_year FROM employees;

-- MySQL also supports:
SELECT name, YEAR(hire_date) AS hire_year, MONTH(hire_date) AS hire_month FROM employees;
```

### Scenario 3: Date arithmetic — add/subtract days
```sql
-- PostgreSQL
SELECT hire_date, hire_date + INTERVAL '30 days' AS thirty_days_later FROM employees;

-- MySQL
SELECT hire_date, DATE_ADD(hire_date, INTERVAL 30 DAY) AS thirty_days_later FROM employees;
```

### Scenario 4: Difference between two dates
```sql
-- PostgreSQL
SELECT name, CURRENT_DATE - hire_date AS days_employed FROM employees;

-- MySQL
SELECT name, DATEDIFF(CURDATE(), hire_date) AS days_employed FROM employees;
```

### Scenario 5: Format a date for display
```sql
-- PostgreSQL
SELECT TO_CHAR(hire_date, 'DD-Mon-YYYY') AS formatted_date FROM employees;

-- MySQL
SELECT DATE_FORMAT(hire_date, '%d-%b-%Y') AS formatted_date FROM employees;
```

## 4. Conditional Logic — `CASE WHEN`

The closest thing SQL has to an if/else statement, used directly inside a query.

### Scenario 1: Simple categorization
```sql
SELECT name, salary,
    CASE
        WHEN salary >= 70000 THEN 'High'
        WHEN salary >= 55000 THEN 'Medium'
        ELSE 'Low'
    END AS salary_band
FROM employees;
```
Conditions are checked top to bottom — the **first** matching `WHEN` wins, the rest are
skipped. Always order from most-specific/highest to least, especially with ranges.

### Scenario 2: CASE used inside an aggregate (conditional counting)
```sql
SELECT
    COUNT(CASE WHEN salary >= 60000 THEN 1 END) AS high_earners,
    COUNT(CASE WHEN salary < 60000 THEN 1 END) AS low_earners
FROM employees;
```
This pattern — `COUNT(CASE WHEN condition THEN 1 END)` — is how you build a "pivot-style"
summary (counts split by category) without multiple queries.

### Scenario 3: CASE for simple equality checks (shorthand form)
```sql
SELECT name,
    CASE last_name
        WHEN 'Mehta' THEN 'Family A'
        WHEN 'Verma' THEN 'Family B'
        ELSE 'Other'
    END AS family_group
FROM employees;
```
This shorthand (`CASE column WHEN value THEN ...`) only works for exact-match equality —
use the full `CASE WHEN condition THEN ...` form (Scenario 1) for ranges/comparisons.

## 5. NULL-Handling Functions

### Scenario 1: Substitute a default for NULL
```sql
SELECT name, COALESCE(manager_id, 0) AS manager_id_or_zero FROM employees;
```
`COALESCE(a, b, c, ...)` returns the first non-NULL value in the list — works across all
major engines and accepts any number of arguments.

### Scenario 2: NULLIF — turn a specific value into NULL
```sql
SELECT name, NULLIF(salary, 0) AS salary_or_null FROM employees;
```
Useful to avoid divide-by-zero errors: `total / NULLIF(count, 0)` returns `NULL` instead
of crashing when `count` is `0`.

## 6. Putting It Together

```sql
SELECT
    CONCAT(UPPER(first_name), ' ', last_name) AS employee_name,
    ROUND(salary, 0) AS salary_rounded,
    EXTRACT(YEAR FROM hire_date) AS hire_year,
    CASE
        WHEN salary >= 70000 THEN 'Senior Pay'
        WHEN salary >= 55000 THEN 'Mid Pay'
        ELSE 'Entry Pay'
    END AS pay_tier
FROM employees
ORDER BY salary DESC;
```

## 7. Common Mistakes

```sql
-- MISTAKE: forgetting SUBSTRING is 1-indexed, not 0-indexed
SELECT SUBSTRING('Hello', 0, 2); -- behavior is engine-dependent/unexpected; use position 1

-- MISTAKE: CASE WHEN order matters — putting general condition first hides specific ones
SELECT salary,
    CASE
        WHEN salary >= 0 THEN 'Has salary'      -- matches EVERYTHING first, others never reached
        WHEN salary >= 70000 THEN 'High'
        ELSE 'Low'
    END AS band
FROM employees;

-- MISTAKE: using = NULL instead of COALESCE/IS NULL when checking for missing values
SELECT * FROM employees WHERE manager_id = NULL; -- always returns nothing, see Module 01
```

## 8. Self-check before Module 09

1. Why might `CONCAT()` syntax differ when you switch from MySQL to older SQL Server?
2. What does `ROUND(value, -3)` do differently from `ROUND(value, 3)`?
3. Why does `CASE WHEN` order matter, and what's the safe ordering habit?
4. What's the difference between `COALESCE` and `NULLIF`?

---
**Previous:** [Module 07 — Subqueries](../07-subqueries/README.md)
**Next:** [Module 09 — Constraints & Keys](../09-constraints-keys/README.md) *(coming next)*