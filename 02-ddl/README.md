# Module 02 — DDL (Data Definition Language)

DDL commands define and modify the **structure** of your database — tables, columns,
their types and rules. None of these commands touch row *data* directly (that's DML,
Module 03) — they shape the container the data lives in.

Commands covered: `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, plus a note on `RENAME`.

## 1. `CREATE DATABASE` / `CREATE TABLE`

### Scenario 1: Create a database
```sql
CREATE DATABASE company_db;
```
> SQLite has no `CREATE DATABASE` — a SQLite database *is* a file. You just open/create
> the file: `sqlite3 company.db`. MySQL/PostgreSQL/SQL Server all support `CREATE DATABASE`.

### Scenario 2: Create a basic table
```sql
CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL
);
```

### Scenario 3: Create a table with multiple data types and constraints
```sql
CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    name        VARCHAR(50) NOT NULL,
    email       VARCHAR(100) UNIQUE,
    salary      DECIMAL(10,2) DEFAULT 0,
    hire_date   DATE NOT NULL,
    dept_id     INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
```
What each piece does (deep dive comes in Module 09, but you need the vocabulary now):
- `PRIMARY KEY` — uniquely identifies each row, can't be NULL.
- `NOT NULL` — column must always have a value.
- `UNIQUE` — no two rows can share this value (unlike PK, a table can have several UNIQUE columns).
- `DEFAULT 0` — if no value given on insert, use `0`.
- `FOREIGN KEY` — links to another table's primary key (this is what makes the data *relational*).

### Scenario 4: Create a table from another table's results
```sql
CREATE TABLE sales_employees AS
SELECT * FROM employees WHERE dept_id = 1;
```
Handy for quick backups or snapshots. Note: this copies *data* too, but **not**
constraints like PRIMARY KEY/FOREIGN KEY — those must be added manually if needed.

### Scenario 5: `IF NOT EXISTS` — avoid errors on re-run
```sql
CREATE TABLE IF NOT EXISTS departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50)
);
```
Without `IF NOT EXISTS`, running `CREATE TABLE` twice throws an error ("table already
exists"). Useful in setup scripts you might re-run.

## 2. `ALTER TABLE`

Used to change an existing table's structure without dropping/recreating it (and without
losing existing data).

### Scenario 1: Add a column
```sql
ALTER TABLE employees ADD COLUMN phone VARCHAR(15);
```
Existing rows get `NULL` in the new column automatically.

### Scenario 2: Add a column with a default for existing rows
```sql
ALTER TABLE employees ADD COLUMN status VARCHAR(20) DEFAULT 'Active';
```

### Scenario 3: Modify a column's data type
```sql
-- PostgreSQL
ALTER TABLE employees ALTER COLUMN phone TYPE VARCHAR(20);

-- MySQL
ALTER TABLE employees MODIFY COLUMN phone VARCHAR(20);
```
> Syntax genuinely differs here across engines — this is one of the few real dialect splits.

### Scenario 4: Rename a column
```sql
-- PostgreSQL / MySQL 8+
ALTER TABLE employees RENAME COLUMN phone TO contact_number;
```

### Scenario 5: Drop a column
```sql
ALTER TABLE employees DROP COLUMN status;
```

### Scenario 6: Add a constraint to an existing table
```sql
ALTER TABLE employees ADD CONSTRAINT chk_salary CHECK (salary >= 0);
```

### Scenario 7: Rename the whole table
```sql
ALTER TABLE employees RENAME TO staff;
-- some engines (older MySQL) instead use:
RENAME TABLE employees TO staff;
```

## 3. `DROP` vs `TRUNCATE` vs `DELETE` (a classic interview question)

This trips up nearly everyone early on — get the distinction solid now.

| Command | Removes | Structure survives? | Can rollback? | Speed |
|---|---|---|---|---|
| `DROP TABLE` | Table + all data + structure | ❌ No — table is gone | Depends on engine/transaction | Instant |
| `TRUNCATE TABLE` | All rows | ✅ Yes — empty table remains | Usually no (DDL, auto-commits in most engines) | Very fast |
| `DELETE FROM table` | Rows (optionally filtered) | ✅ Yes | ✅ Yes (it's DML) | Slower (logs each row) |

### Scenario 1: Drop a table entirely
```sql
DROP TABLE sales_employees;
```
Gone. Structure, data, indexes on it — all gone. Use `DROP TABLE IF EXISTS sales_employees;`
to avoid an error if it might not exist.

### Scenario 2: Empty a table but keep its structure
```sql
TRUNCATE TABLE employees;
```
All rows deleted instantly. Table still exists, ready for new data. Auto-increment
counters typically reset to 1 (engine-dependent) — unlike `DELETE`, which doesn't reset them.

### Scenario 3: When to use `DELETE` instead of `TRUNCATE`
```sql
DELETE FROM employees WHERE dept_id = 3;
```
You can't `TRUNCATE` with a `WHERE` clause — truncate is all-or-nothing. Need to remove
*some* rows? That's `DELETE` (Module 03).

### Scenario 4: Drop a database
```sql
DROP DATABASE company_db;
```
Irreversible — wipes every table inside it. Always double-check which database you're
connected to before running this.

## 4. Practical Mental Model

Think of DDL as **architecture** — building/changing rooms in a house.
DML (next module) is **furniture** — what goes inside those rooms.
You wouldn't furnish a room before building it, and you generally don't redesign the
house's structure every day once people are living in it.

## 5. Common Mistakes

```sql
-- MISTAKE: forgetting IF EXISTS, script breaks on re-run
DROP TABLE employees;   -- errors if employees doesn't exist

-- BETTER
DROP TABLE IF EXISTS employees;

-- MISTAKE: assuming TRUNCATE can be rolled back like DELETE
-- In MySQL/PostgreSQL, TRUNCATE is DDL — it auto-commits in many configs.
-- Always be deliberate, especially in production.
```

## 6. Self-check before Module 03

1. What's the real difference between `DROP`, `TRUNCATE`, and `DELETE`?
2. Why might `CREATE TABLE x AS SELECT * FROM y` not preserve all your constraints?
3. When would you choose `ALTER TABLE ... ADD COLUMN` over recreating the table?
4. Why does `TRUNCATE` typically reset auto-increment values but `DELETE` doesn't?

---
**Previous:** [Module 01 — Basics](../01-basics/README.md)
**Next:** [Module 03 — DML](../03-dml/README.md) *(coming next)*