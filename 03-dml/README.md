# Module 03 — DML (Data Manipulation Language)

DDL (Module 02) built the structure. DML is what puts **data** into that structure and
changes it: `INSERT`, `UPDATE`, `DELETE`. Unlike DDL, these are typically transactional —
you can `ROLLBACK` them if wrapped in a transaction (Module 11).

We'll use this table throughout:

```sql
CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    name        VARCHAR(50) NOT NULL,
    email       VARCHAR(100) UNIQUE,
    salary      DECIMAL(10,2) DEFAULT 0,
    hire_date   DATE NOT NULL,
    dept_id     INT
);
```

## 1. `INSERT` — Adding Data

### Scenario 1: Insert a single full row
```sql
INSERT INTO employees (emp_id, name, email, salary, hire_date, dept_id)
VALUES (1, 'Asha', 'asha@co.com', 55000, '2021-03-01', 1);
```
Always list column names explicitly. `INSERT INTO employees VALUES (1, 'Asha', ...)`
works too, but it's fragile — if someone adds a column later, the query breaks silently
or inserts data into the wrong column.

### Scenario 2: Insert a row, skipping optional columns
```sql
INSERT INTO employees (emp_id, name, hire_date)
VALUES (2, 'Rohan', '2020-07-15');
```
Unlisted columns get `NULL` (or their `DEFAULT` if one is set — `salary` becomes `0` here,
not `NULL`, because of `DEFAULT 0` on that column).

### Scenario 3: Insert multiple rows in one statement
```sql
INSERT INTO employees (emp_id, name, email, salary, hire_date, dept_id) VALUES
(3, 'Meera', 'meera@co.com', 58000, '2022-01-10', 1),
(4, 'Karan', 'karan@co.com', 65000, '2023-05-20', 2),
(5, 'Divya', 'divya@co.com', 49000, '2021-11-30', 3);
```
Much faster than 3 separate `INSERT` statements — fewer round-trips to the database.

### Scenario 4: Insert data copied from another table (`INSERT INTO ... SELECT`)
```sql
INSERT INTO sales_employees (emp_id, name, salary)
SELECT emp_id, name, salary FROM employees WHERE dept_id = 1;
```
This is how you move/copy filtered data between tables — extremely common in ETL-style work.

### Scenario 5: Insert and let the database generate the key (auto-increment)
```sql
CREATE TABLE logs (
    log_id  INT AUTO_INCREMENT PRIMARY KEY,  -- MySQL
    message VARCHAR(200)
);
INSERT INTO logs (message) VALUES ('Server started');
-- log_id is generated automatically
```
> PostgreSQL uses `SERIAL` or `GENERATED ALWAYS AS IDENTITY` instead of `AUTO_INCREMENT`.
> SQLite uses `INTEGER PRIMARY KEY AUTOINCREMENT`.

## 2. `UPDATE` — Modifying Data

General shape:
```sql
UPDATE table_name
SET column1 = value1, column2 = value2
WHERE condition;
```

> ⚠️ **The most dangerous mistake in SQL**: forgetting `WHERE` on an `UPDATE` updates
> **every row** in the table. Always write and verify your `WHERE` clause — ideally
> test it first as a `SELECT` (see Scenario 5 below) before running the `UPDATE`.

### Scenario 1: Update one row
```sql
UPDATE employees
SET salary = 60000
WHERE emp_id = 1;
```

### Scenario 2: Update multiple columns at once
```sql
UPDATE employees
SET salary = 60000, dept_id = 2
WHERE emp_id = 1;
```

### Scenario 3: Update multiple rows matching a condition
```sql
UPDATE employees
SET salary = salary * 1.10
WHERE dept_id = 1;
```
Gives every Sales employee a 10% raise. Note `salary = salary * 1.10` — the right side
is evaluated using the *current* value before the update applies.

### Scenario 4: Update using a value from another table (subquery)
```sql
UPDATE employees
SET salary = salary + 5000
WHERE dept_id = (SELECT dept_id FROM departments WHERE dept_name = 'IT');
```

### Scenario 5: The safety habit — preview before you commit
```sql
-- Step 1: see exactly which rows will be affected
SELECT * FROM employees WHERE dept_id = 1;

-- Step 2: only run the UPDATE once you've confirmed the row set
UPDATE employees SET salary = salary * 1.10 WHERE dept_id = 1;
```

## 3. `DELETE` — Removing Data

General shape:
```sql
DELETE FROM table_name
WHERE condition;
```

> ⚠️ Same warning as `UPDATE`: `DELETE FROM employees;` with no `WHERE` deletes **every
> row**. The table structure survives (unlike `DROP`), but all your data is gone.

### Scenario 1: Delete a specific row
```sql
DELETE FROM employees WHERE emp_id = 5;
```

### Scenario 2: Delete rows matching a condition
```sql
DELETE FROM employees WHERE salary < 50000;
```

### Scenario 3: Delete using a subquery condition
```sql
DELETE FROM employees
WHERE dept_id IN (SELECT dept_id FROM departments WHERE dept_name = 'HR');
```

### Scenario 4: Delete everything (rare, but you should know it)
```sql
DELETE FROM employees;
```
Compare to `TRUNCATE TABLE employees;` from Module 02 — `TRUNCATE` is faster for this
exact case but isn't filterable and may not be rollback-safe depending on engine/transaction mode.

## 4. `INSERT`, `UPDATE`, `DELETE` — Side-by-Side Mental Model

| Command | Adds rows | Changes existing rows | Removes rows | Needs WHERE? |
|---|---|---|---|---|
| `INSERT` | ✅ | ❌ | ❌ | N/A |
| `UPDATE` | ❌ | ✅ | ❌ | Optional but almost always needed |
| `DELETE` | ❌ | ❌ | ✅ | Optional but almost always needed |

## 5. Common Mistakes

```sql
-- MISTAKE: missing WHERE — updates the entire table
UPDATE employees SET salary = 60000;

-- MISTAKE: column/value count mismatch
INSERT INTO employees (emp_id, name) VALUES (6, 'Tina', 'extra-value');
-- Error: more values than listed columns

-- MISTAKE: violating UNIQUE constraint
INSERT INTO employees (emp_id, name, email, hire_date)
VALUES (7, 'Sam', 'asha@co.com', '2024-01-01');
-- Error: email already exists (UNIQUE constraint from Module 02)
```

## 6. Self-check before Module 04

1. Why is it safer to always name columns explicitly in `INSERT`?
2. What value does an unlisted column get on `INSERT` if it has no `DEFAULT`?
3. What's the single most dangerous habit to avoid with `UPDATE`/`DELETE`?
4. How would you copy only employees earning above 60000 into a new table using DML you've learned?

---
**Previous:** [Module 02 — DDL](../02-ddl/README.md)
**Next:** [Module 04 — Queries & Filtering](../04-queries-filtering/README.md) *(coming next)*