-- Module 02 — DDL — Practice Queries

-- 1. Create database (skip in SQLite — a SQLite DB is just a file)
CREATE DATABASE company_db;

-- 2. Create a basic table
CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL
);

-- 3. Create a table with constraints + foreign key
CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    name        VARCHAR(50) NOT NULL,
    email       VARCHAR(100) UNIQUE,
    salary      DECIMAL(10,2) DEFAULT 0,
    hire_date   DATE NOT NULL,
    dept_id     INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- seed some data for practice
INSERT INTO departments VALUES (1, 'Sales'), (2, 'IT'), (3, 'HR');
INSERT INTO employees (emp_id, name, email, salary, hire_date, dept_id) VALUES
(1, 'Asha',  'asha@co.com',  55000, '2021-03-01', 1),
(2, 'Rohan', 'rohan@co.com', 72000, '2020-07-15', 2),
(3, 'Meera', 'meera@co.com', 58000, '2022-01-10', 1);

-- 4. Create a table from a query (snapshot)
CREATE TABLE sales_employees AS
SELECT * FROM employees WHERE dept_id = 1;

-- 5. Safe create (no error if exists)
CREATE TABLE IF NOT EXISTS departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50)
);

-- 6. ALTER: add a column
ALTER TABLE employees ADD COLUMN phone VARCHAR(15);

-- 7. ALTER: add a column with default
ALTER TABLE employees ADD COLUMN status VARCHAR(20) DEFAULT 'Active';

-- 8. ALTER: modify a column type (engine-specific — uncomment the one you use)
-- PostgreSQL:
-- ALTER TABLE employees ALTER COLUMN phone TYPE VARCHAR(20);
-- MySQL:
-- ALTER TABLE employees MODIFY COLUMN phone VARCHAR(20);

-- 9. ALTER: rename a column
ALTER TABLE employees RENAME COLUMN phone TO contact_number;

-- 10. ALTER: drop a column
ALTER TABLE employees DROP COLUMN status;

-- 11. ALTER: add a CHECK constraint
ALTER TABLE employees ADD CONSTRAINT chk_salary CHECK (salary >= 0);

-- 12. ALTER: rename whole table
ALTER TABLE employees RENAME TO staff;
ALTER TABLE staff RENAME TO employees; -- rename back for consistency

-- 13. TRUNCATE vs DELETE vs DROP demo
TRUNCATE TABLE sales_employees;          -- empties table, keeps structure
DELETE FROM employees WHERE dept_id = 3; -- deletes matching rows only
DROP TABLE IF EXISTS sales_employees;    -- removes table entirely

-- 14. Try it yourself:
--    a) Create a "projects" table with project_id (PK), project_name, start_date
--    b) Add a "budget" column with a default value of 0
--    c) Add a CHECK constraint ensuring budget >= 0
--    d) Truncate it, confirm the structure still exists, then drop it