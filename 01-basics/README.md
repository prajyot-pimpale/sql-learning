# Module 01 — SQL Basics

## 1. What is SQL?

**SQL (Structured Query Language)** is a language for talking to a **relational
database** — software that stores data in **tables** (rows + columns), the way you'd
organize data in a spreadsheet, but with rules that keep it consistent and fast to search.

SQL is **declarative**: you describe *what* you want, not *how* to get it.

```sql
SELECT name FROM employees WHERE department = 'Sales';
```
You never tell the database *how* to search — no loops, no pointers. The database engine
figures out the most efficient way internally.

## 2. RDBMS — Relational Database Management System

A database is a container. A **table** inside it looks like this:

**employees**

| emp_id | name    | department | salary | hire_date  |
|--------|---------|------------|--------|------------|
| 1      | Asha    | Sales      | 55000  | 2021-03-01 |
| 2      | Rohan   | IT         | 72000  | 2020-07-15 |
| 3      | Meera   | Sales      | 58000  | 2022-01-10 |

Key vocabulary:
- **Row (record/tuple)** — one entry, e.g., Asha's full data.
- **Column (field/attribute)** — one property, e.g., `salary`.
- **Schema** — the structure: column names + their data types.
- **Primary Key** — a column (or set of columns) that uniquely identifies a row (`emp_id` here).
- **Relational** — tables can *relate* to each other via shared keys (you'll see this heavily in Module 05 - Joins).

Popular RDBMS engines: MySQL, PostgreSQL, SQLite, SQL Server, Oracle. The SQL you write is
~95% identical across all of them; small dialect differences will be called out as we go.

## 3. The Sublanguages of SQL

SQL commands are grouped by purpose. You'll meet all of these across this course, but
knowing the map now helps everything click into place later.

| Sublanguage | Stands for | Commands | Purpose |
|---|---|---|---|
| **DDL** | Data Definition Language | `CREATE`, `ALTER`, `DROP`, `TRUNCATE` | Define/change table structure |
| **DML** | Data Manipulation Language | `INSERT`, `UPDATE`, `DELETE` | Change data inside tables |
| **DQL** | Data Query Language | `SELECT` | Read/retrieve data |
| **DCL** | Data Control Language | `GRANT`, `REVOKE` | Control access/permissions |
| **TCL** | Transaction Control Language | `COMMIT`, `ROLLBACK`, `SAVEPOINT` | Manage transactions |

> Some people lump DQL into DML. Don't worry about the label — worry about what each
> command *does*. That's covered module-by-module in this repo.

## 4. Basic Syntax Rules

- SQL keywords are **not case-sensitive** (`SELECT` = `select`), but the convention in
  this course is: **KEYWORDS IN CAPS**, identifiers (table/column names) in lowercase.
- Statements end with a semicolon `;`.
- Strings use single quotes: `'Sales'` — **not** double quotes (double quotes are for
  identifiers in PostgreSQL, and not valid at all for strings in most engines).
- Comments:
  ```sql
  -- this is a single-line comment

  /* this is a
     multi-line comment */
  ```

## 5. Data Types (the core ones you'll use constantly)

| Category | Type | Example | Notes |
|---|---|---|---|
| Numbers | `INT`, `INTEGER` | `42` | Whole numbers |
| Numbers | `DECIMAL(p,s)` / `NUMERIC(p,s)` | `1999.99` | Exact decimals — use for money |
| Numbers | `FLOAT`, `DOUBLE` | `3.14159` | Approximate decimals — avoid for money |
| Text | `VARCHAR(n)` | `'Asha'` | Variable-length text, max `n` chars |
| Text | `CHAR(n)` | `'A'` | Fixed-length text |
| Text | `TEXT` | long text | No practical length limit (engine-dependent) |
| Date/Time | `DATE` | `'2024-05-21'` | Date only |
| Date/Time | `TIME` | `'14:30:00'` | Time only |
| Date/Time | `TIMESTAMP` / `DATETIME` | `'2024-05-21 14:30:00'` | Date + time |
| Boolean | `BOOLEAN` | `TRUE` / `FALSE` | SQLite/MySQL store this as 0/1 internally |
| Other | `NULL` | — | Not a type — represents **absence** of a value |

**Important concept — `NULL`:**
`NULL` means "unknown/missing," not zero or empty string. This trips up beginners constantly:

```sql
-- WRONG: this will NEVER match NULL rows
SELECT * FROM employees WHERE manager_id = NULL;

-- CORRECT
SELECT * FROM employees WHERE manager_id IS NULL;
SELECT * FROM employees WHERE manager_id IS NOT NULL;
```

## 6. Your First Query — `SELECT`

The most-used SQL statement of all. General shape:

```sql
SELECT column1, column2
FROM table_name
WHERE condition;
```

### Scenario 1: Select everything
```sql
SELECT * FROM employees;
```
`*` means "all columns." Fine for exploring; avoid in real application code (explicit
columns are faster and safer against schema changes).

### Scenario 2: Select specific columns
```sql
SELECT name, salary FROM employees;
```

### Scenario 3: Rename output columns (alias) with `AS`
```sql
SELECT name AS employee_name, salary AS monthly_salary
FROM employees;
```
`AS` is optional in most engines (`SELECT name employee_name` also works) but write it
explicitly — it reads cleaner.

### Scenario 4: Simple calculated column
```sql
SELECT name, salary, salary * 12 AS annual_salary
FROM employees;
```
You can do arithmetic directly in the `SELECT` list: `+ - * / %`.

### Scenario 5: Filter rows with `WHERE`
```sql
SELECT name, department
FROM employees
WHERE department = 'Sales';
```

### Scenario 6: Remove duplicates with `DISTINCT`
```sql
SELECT DISTINCT department FROM employees;
```
If `employees` has Sales, IT, Sales, HR, Sales — this returns Sales, IT, HR (each once).

### Scenario 7: Combine column selection + filter + alias
```sql
SELECT name AS employee, department, salary * 12 AS annual_pay
FROM employees
WHERE salary > 50000;
```

## 7. Order in which SQL actually executes (mental model)

You *write* a query top to bottom, but the engine *executes* it in roughly this order:

```
FROM   → which table(s)
WHERE  → filter rows
SELECT → pick/compute columns
```
(We'll extend this execution order in later modules once `GROUP BY`, `HAVING`, `ORDER BY`
enter the picture — Module 06.) Understanding this now explains *why* certain errors
happen later (e.g., why you can't filter on an aliased column in `WHERE`).

## 8. Practice Setup

Run this once in your chosen engine to create the table used in this module's examples
(full version is in `queries.sql`):

```sql
CREATE TABLE employees (
    emp_id     INT PRIMARY KEY,
    name       VARCHAR(50),
    department VARCHAR(50),
    salary     DECIMAL(10,2),
    hire_date  DATE
);

INSERT INTO employees VALUES
(1, 'Asha',  'Sales', 55000, '2021-03-01'),
(2, 'Rohan', 'IT',    72000, '2020-07-15'),
(3, 'Meera', 'Sales', 58000, '2022-01-10');
```
(Don't worry about understanding `CREATE TABLE`/`INSERT` syntax fully yet — that's all of
Module 02 and 03. Just run it so you have data to query.)

## 9. Self-check before moving to Module 02

You should be able to answer these without looking back:
1. What's the difference between DDL and DML?
2. Why does `WHERE manager_id = NULL` never return rows?
3. What does `SELECT DISTINCT department` do differently from `SELECT department`?
4. In what order does the engine logically process `FROM`, `WHERE`, `SELECT`?

If any of these feel shaky, re-read that section — don't move forward yet.

---
**Next:** [Module 02 — DDL](../02-ddl/README.md) *(coming next)*