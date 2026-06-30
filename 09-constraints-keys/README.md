# Module 09 — Constraints & Keys

Constraints are rules enforced *by the database itself* — not by your application code.
This matters: even if a bug in your app tries to insert bad data, the database refuses
it. This module goes deep on every constraint type and the key concepts behind them.

## 1. `PRIMARY KEY` — Uniquely Identifies Each Row

Rules: unique across all rows, **cannot be NULL**, and a table can have only **one**
primary key (though it can span multiple columns — a composite key).

### Scenario 1: Single-column primary key
```sql
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    name   VARCHAR(50)
);
```

### Scenario 2: Composite primary key (spans multiple columns)
```sql
CREATE TABLE enrollments (
    student_id INT,
    course_id  INT,
    enrolled_on DATE,
    PRIMARY KEY (student_id, course_id)
);
```
A student can take many courses, and a course has many students — but the *combination*
of `(student_id, course_id)` must be unique. This is the standard pattern for many-to-many
relationship tables (you'll see this again in Module 12 with junction tables).

### Scenario 3: What happens when you violate it
```sql
INSERT INTO employees VALUES (1, 'Asha');
INSERT INTO employees VALUES (1, 'Rohan');  -- ERROR: duplicate primary key value
```

## 2. `FOREIGN KEY` — Links Rows Between Tables

A foreign key column's values must match an existing value in another table's primary
(or unique) key — or be `NULL`, if the column allows it. This is what makes data
**relational** rather than a pile of disconnected tables.

### Scenario 1: Basic foreign key
```sql
CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50)
);

CREATE TABLE employees (
    emp_id  INT PRIMARY KEY,
    name    VARCHAR(50),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
```

### Scenario 2: What happens when you violate it
```sql
INSERT INTO employees VALUES (1, 'Asha', 99);
-- ERROR: dept_id 99 doesn't exist in departments — foreign key constraint fails
```

### Scenario 3: `ON DELETE` behavior — what happens to children when the parent is deleted
```sql
CREATE TABLE employees (
    emp_id  INT PRIMARY KEY,
    name    VARCHAR(50),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id) ON DELETE CASCADE
);
```

| Option | Effect when parent row is deleted |
|---|---|
| `ON DELETE CASCADE` | child rows are automatically deleted too |
| `ON DELETE SET NULL` | child's foreign key column is set to `NULL` |
| `ON DELETE RESTRICT` (default in most engines) | deletion is **blocked** if children exist |
| `ON DELETE NO ACTION` | similar to RESTRICT — blocks the deletion |

### Scenario 4: Real difference in practice
```sql
-- With ON DELETE RESTRICT (default):
DELETE FROM departments WHERE dept_id = 1;
-- ERROR if any employees still reference dept_id = 1

-- With ON DELETE CASCADE:
DELETE FROM departments WHERE dept_id = 1;
-- Succeeds — and ALL employees in that department are deleted too (be very careful with this)

-- With ON DELETE SET NULL:
DELETE FROM departments WHERE dept_id = 1;
-- Succeeds — employees survive, but their dept_id becomes NULL
```
> Choose deliberately. `CASCADE` is powerful but dangerous in production — a single
> delete can silently wipe far more data than intended if the relationship chain is deep.

## 3. `UNIQUE` — No Duplicate Values, But NULLs Allowed

Difference from `PRIMARY KEY`: a table can have *multiple* `UNIQUE` columns, and (in most
engines) `UNIQUE` columns *can* contain `NULL` — multiple NULLs are typically allowed too,
since `NULL` is never considered equal to another `NULL`.

### Scenario 1: Single unique column
```sql
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    email  VARCHAR(100) UNIQUE
);
```

### Scenario 2: Violation
```sql
INSERT INTO employees VALUES (1, 'asha@co.com');
INSERT INTO employees VALUES (2, 'asha@co.com');  -- ERROR: duplicate email
```

### Scenario 3: Composite UNIQUE constraint
```sql
CREATE TABLE bookings (
    booking_id INT PRIMARY KEY,
    room_id    INT,
    booking_date DATE,
    UNIQUE (room_id, booking_date)  -- a room can only be booked once per date
);
```

## 4. `NOT NULL` — Value Is Mandatory

### Scenario 1: Required field
```sql
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    name   VARCHAR(50) NOT NULL,
    email  VARCHAR(100)  -- optional, NULL allowed
);
```

### Scenario 2: Violation
```sql
INSERT INTO employees (emp_id, email) VALUES (1, 'a@co.com');
-- ERROR: name cannot be NULL
```

## 5. `CHECK` — Custom Validation Rule

### Scenario 1: Numeric range check
```sql
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    salary DECIMAL(10,2) CHECK (salary >= 0)
);
```

### Scenario 2: Violation
```sql
INSERT INTO employees VALUES (1, -500);
-- ERROR: CHECK constraint violated
```

### Scenario 3: Check involving multiple columns
```sql
CREATE TABLE bookings (
    booking_id  INT PRIMARY KEY,
    start_date  DATE,
    end_date    DATE,
    CHECK (end_date > start_date)
);
```

### Scenario 4: Check against a fixed list (when ENUM isn't available/desired)
```sql
CREATE TABLE employees (
    emp_id  INT PRIMARY KEY,
    status  VARCHAR(20) CHECK (status IN ('Active', 'Inactive', 'On Leave'))
);
```

## 6. `DEFAULT` — Auto-Fill When No Value Given

Not strictly a "constraint" in the validation sense, but grouped here since it's defined
alongside constraints in `CREATE TABLE`.

```sql
CREATE TABLE employees (
    emp_id   INT PRIMARY KEY,
    status   VARCHAR(20) DEFAULT 'Active',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO employees (emp_id) VALUES (1);
-- status becomes 'Active', joined_at becomes the current timestamp automatically
```

## 7. All Constraints Together — Realistic Table

```sql
CREATE TABLE employees (
    emp_id     INT PRIMARY KEY,
    name       VARCHAR(50) NOT NULL,
    email      VARCHAR(100) UNIQUE NOT NULL,
    salary     DECIMAL(10,2) CHECK (salary >= 0) DEFAULT 0,
    dept_id    INT,
    status     VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive')),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id) ON DELETE SET NULL
);
```
Reading this top to bottom: every employee must have a name and a unique, mandatory
email; salary defaults to 0 and can never go negative; department is optional and
survives even if the department is deleted (becomes NULL); status defaults to 'Active'
and can only ever be one of two values.

## 8. Adding Constraints to Existing Tables (recap from Module 02, applied here)

```sql
ALTER TABLE employees ADD CONSTRAINT uq_email UNIQUE (email);
ALTER TABLE employees ADD CONSTRAINT chk_salary CHECK (salary >= 0);
ALTER TABLE employees ADD CONSTRAINT fk_dept FOREIGN KEY (dept_id) REFERENCES departments(dept_id);
```
Naming constraints explicitly (`uq_email`, `chk_salary`, `fk_dept`) makes them easy to
find and drop later: `ALTER TABLE employees DROP CONSTRAINT chk_salary;`

## 9. Common Mistakes

```sql
-- MISTAKE: trying to give a table two PRIMARY KEYs
CREATE TABLE x (a INT PRIMARY KEY, b INT PRIMARY KEY);
-- ERROR: only one primary key per table (use a composite key instead)

-- MISTAKE: assuming UNIQUE blocks NULLs like PRIMARY KEY does
CREATE TABLE x (email VARCHAR(100) UNIQUE);
INSERT INTO x VALUES (NULL);
INSERT INTO x VALUES (NULL); -- usually allowed — NULL != NULL in most engines

-- MISTAKE: forgetting ON DELETE behavior, then being surprised
DELETE FROM departments WHERE dept_id = 1;
-- ERROR (default RESTRICT) if employees still reference it — not a bug, it's protecting your data
```

## 10. Self-check before Module 10

1. What's the core difference between `PRIMARY KEY` and `UNIQUE`?
2. What are the four `ON DELETE` behaviors, and which is riskiest in production?
3. When would you use a composite primary key instead of a single-column one?
4. Why might `CHECK (status IN (...))` be preferable to relying only on app-level validation?

---
**Previous:** [Module 08 — Functions](../08-functions/README.md)
**Next:** [Module 10 — Views & Indexes](../10-views-indexes/README.md) *(coming next)*