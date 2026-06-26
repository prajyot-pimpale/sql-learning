# Module 05 — Joins

This is the module where relational databases truly earn the "relational" name. Joins
let you combine rows from two (or more) tables based on a related column — usually a
foreign key pointing to a primary key.

Two tables used throughout:

```sql
CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50)
);

INSERT INTO departments VALUES
(1, 'Sales'),
(2, 'IT'),
(3, 'HR'),
(4, 'Marketing');   -- note: no employees in Marketing yet

CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    name        VARCHAR(50),
    salary      DECIMAL(10,2),
    dept_id     INT,             -- foreign key -> departments.dept_id
    manager_id  INT              -- foreign key -> employees.emp_id (self-reference)
);

INSERT INTO employees VALUES
(1, 'Asha',  55000, 1, NULL),
(2, 'Rohan', 72000, 2, NULL),
(3, 'Meera', 58000, 1, 1),
(4, 'Karan', 65000, 2, 2),
(5, 'Divya', 49000, NULL, NULL);   -- note: no department assigned yet
```

Notice the deliberate gaps: Marketing has no employees, and Divya has no department.
This is intentional — it's exactly what exposes the difference between join types.

## 1. `INNER JOIN` — only matching rows from both sides

```sql
SELECT e.name, e.salary, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;
```
**Result:** Asha, Rohan, Meera, Karan — each with their department. **Divya is excluded**
(no `dept_id`), and **Marketing is excluded** (no employees). `INNER JOIN` only keeps rows
where the join condition matches on *both* sides.

> `JOIN` alone (without specifying a type) defaults to `INNER JOIN` in every major engine.

### Scenario: Join with a filter
```sql
SELECT e.name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;
```
Filters happen *after* the join — so this returns Rohan, Meera, Karan (Asha is exactly
55000, excluded by `>`).

## 2. `LEFT JOIN` (a.k.a. `LEFT OUTER JOIN`) — all rows from the left, matched or not

```sql
SELECT e.name, e.dept_id, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;
```
**Result:** every employee appears, including **Divya** — but her `dept_name` is `NULL`
because she has no matching department. The "left" table (`employees`, listed first) is
the table you guarantee to keep every row from.

### Scenario: Find employees with no department (classic use case)
```sql
SELECT e.name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;
```
This pattern — `LEFT JOIN` + `WHERE right_table.key IS NULL` — is the standard way to
find "orphan" rows: employees with no valid department, customers with no orders, etc.

## 3. `RIGHT JOIN` (a.k.a. `RIGHT OUTER JOIN`) — all rows from the right, matched or not

```sql
SELECT e.name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;
```
**Result:** every department appears, including **Marketing** — with `name` as `NULL`
since no employee belongs to it.

> `RIGHT JOIN` is just `LEFT JOIN` with the tables swapped. Most people standardize on
> always writing `LEFT JOIN` and reordering the tables instead, for consistency:
> ```sql
> SELECT e.name, d.dept_name
> FROM departments d
> LEFT JOIN employees e ON e.dept_id = d.dept_id;
> -- identical result to the RIGHT JOIN above
> ```
> SQLite historically didn't support `RIGHT JOIN` (fixed in newer versions) — this is
> exactly why the LEFT-JOIN-with-swapped-tables habit is worth building early.

### Scenario: Find departments with zero employees
```sql
SELECT d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;
```
Returns Marketing — the mirror image of the "orphan employees" pattern above.

## 4. `FULL JOIN` (a.k.a. `FULL OUTER JOIN`) — everything from both sides

```sql
SELECT e.name, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id;
```
**Result:** all 5 employees AND all 4 departments — Divya with `NULL` department,
Marketing with `NULL` employee. Nothing is dropped from either side.

> ⚠️ **MySQL does not support `FULL JOIN` directly.** Emulate it with `UNION`:
> ```sql
> SELECT e.name, d.dept_name FROM employees e LEFT JOIN departments d ON e.dept_id = d.dept_id
> UNION
> SELECT e.name, d.dept_name FROM employees e RIGHT JOIN departments d ON e.dept_id = d.dept_id;
> ```

## 5. `SELF JOIN` — joining a table to itself

Used when a table references itself — like `manager_id` pointing back to another row in
the same `employees` table.

```sql
SELECT emp.name AS employee, mgr.name AS manager
FROM employees emp
LEFT JOIN employees mgr ON emp.manager_id = mgr.emp_id;
```
**Result:**
| employee | manager |
|---|---|
| Asha | NULL |
| Rohan | NULL |
| Meera | Asha |
| Karan | Rohan |
| Divya | NULL |

Same table, two aliases (`emp` and `mgr`) — this is the only way SQL lets you treat one
table as if it were two for the purposes of a join. `LEFT JOIN` (not `INNER`) here so
employees with no manager (like Asha) still show up.

## 6. `CROSS JOIN` — every combination of both tables

```sql
SELECT e.name, d.dept_name
FROM employees e
CROSS JOIN departments d;
```
**Result:** 5 employees × 4 departments = **20 rows** — every possible pairing, no
matching condition at all. Rarely used directly in business queries, but useful for
generating combinations — e.g., every product × every size, or every day × every store
for a report template.

## 7. Joining 3+ Tables

```sql
CREATE TABLE projects (
    project_id   INT PRIMARY KEY,
    project_name VARCHAR(50),
    emp_id       INT
);
INSERT INTO projects VALUES
(1, 'Website Redesign', 1),
(2, 'CRM Migration', 2),
(3, 'Ad Campaign', 3);

SELECT e.name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON e.emp_id = p.emp_id;
```
Chain joins one after another — each new `JOIN` clause connects to any table already in
the query, not just the most recent one.

## 8. Join Types — Visual Summary

```
INNER JOIN:    only the overlap
LEFT JOIN:     all of left + overlap
RIGHT JOIN:    all of right + overlap
FULL JOIN:     all of left + all of right + overlap
CROSS JOIN:    every combination, no condition
SELF JOIN:     a table joined to itself (not a different "type", just a usage pattern)
```

## 9. Common Mistakes

```sql
-- MISTAKE: forgetting the ON condition — accidentally creates a CROSS JOIN
SELECT e.name, d.dept_name FROM employees e, departments d;
-- No WHERE/ON linking them = every combination (old-style implicit join syntax — avoid this)

-- MISTAKE: using INNER JOIN when you actually need LEFT JOIN
-- (silently drops rows with no match — easy to miss in larger datasets)
SELECT e.name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;
-- Divya disappears entirely here — intentional only if that's really what you want

-- MISTAKE: ambiguous column reference when both tables have a column with the same name
SELECT dept_id FROM employees e JOIN departments d ON e.dept_id = d.dept_id;
-- Error: ambiguous — must qualify as e.dept_id or d.dept_id
```

## 10. Self-check before Module 06

1. What's the key difference between `INNER JOIN` and `LEFT JOIN`?
2. How do you find rows in table A that have no matching row in table B?
3. Why does a `SELF JOIN` need table aliases?
4. What does `CROSS JOIN` produce, and when (rarely) would you actually want that?

---
**Previous:** [Module 04 — Queries & Filtering](../04-queries-filtering/README.md)
**Next:** [Module 06 — Aggregation](../06-aggregation/README.md) *(coming next)*