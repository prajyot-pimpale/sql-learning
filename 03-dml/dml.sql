-- Module 03 — DML — Practice Queries

-- Setup (reuse from Module 02, recreate here for standalone practice)
CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL
);

CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    name        VARCHAR(50) NOT NULL,
    email       VARCHAR(100) UNIQUE,
    salary      DECIMAL(10,2) DEFAULT 0,
    hire_date   DATE NOT NULL,
    dept_id     INT
);

INSERT INTO departments VALUES (1, 'Sales'), (2, 'IT'), (3, 'HR');

-- 1. Insert a single full row
INSERT INTO employees (emp_id, name, email, salary, hire_date, dept_id)
VALUES (1, 'Asha', 'asha@co.com', 55000, '2021-03-01', 1);

-- 2. Insert skipping optional columns (salary defaults to 0)
INSERT INTO employees (emp_id, name, hire_date)
VALUES (2, 'Rohan', '2020-07-15');

-- 3. Insert multiple rows at once
INSERT INTO employees (emp_id, name, email, salary, hire_date, dept_id) VALUES
(3, 'Meera', 'meera@co.com', 58000, '2022-01-10', 1),
(4, 'Karan', 'karan@co.com', 65000, '2023-05-20', 2),
(5, 'Divya', 'divya@co.com', 49000, '2021-11-30', 3);

-- 4. Insert from another table's query result
CREATE TABLE sales_employees (
    emp_id INT,
    name   VARCHAR(50),
    salary DECIMAL(10,2)
);
INSERT INTO sales_employees (emp_id, name, salary)
SELECT emp_id, name, salary FROM employees WHERE dept_id = 1;

-- 5. UPDATE: single row
UPDATE employees SET salary = 60000 WHERE emp_id = 1;

-- 6. UPDATE: multiple columns
UPDATE employees SET salary = 60000, dept_id = 2 WHERE emp_id = 1;

-- 7. UPDATE: multiple rows with calculation
UPDATE employees SET salary = salary * 1.10 WHERE dept_id = 1;

-- 8. UPDATE: using subquery
UPDATE employees
SET salary = salary + 5000
WHERE dept_id = (SELECT dept_id FROM departments WHERE dept_name = 'IT');

-- 9. Safety habit: preview before update
SELECT * FROM employees WHERE dept_id = 1;          -- check first
UPDATE employees SET salary = salary * 1.05 WHERE dept_id = 1;  -- then run

-- 10. DELETE: specific row
DELETE FROM employees WHERE emp_id = 5;

-- 11. DELETE: condition-based
DELETE FROM employees WHERE salary < 50000;

-- 12. DELETE: using subquery
DELETE FROM employees
WHERE dept_id IN (SELECT dept_id FROM departments WHERE dept_name = 'HR');

-- 13. Try it yourself:
--    a) Insert 3 new employees in one statement
--    b) Give everyone in dept_id = 2 a 15% raise (preview with SELECT first!)
--    c) Delete any employee earning below 55000
--    d) Copy all employees earning above 60000 into a "top_earners" table you create