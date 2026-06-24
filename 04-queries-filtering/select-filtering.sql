-- Module 04 — Queries & Filtering — Practice Queries

-- Setup
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

-- 1. Comparison operators
SELECT * FROM employees WHERE department = 'IT';
SELECT * FROM employees WHERE department <> 'IT';
SELECT name, salary FROM employees WHERE salary > 60000;

-- 2. Logical operators
SELECT * FROM employees WHERE department = 'IT' AND salary > 70000;
SELECT * FROM employees WHERE department = 'HR' OR salary > 80000;
SELECT * FROM employees WHERE NOT department = 'Sales';
SELECT * FROM employees
WHERE department = 'Sales' AND (salary > 50000 OR hire_date < '2022-01-01');

-- 3. BETWEEN
SELECT name, salary FROM employees WHERE salary BETWEEN 50000 AND 70000;
SELECT name, hire_date FROM employees WHERE hire_date BETWEEN '2021-01-01' AND '2022-12-31';
SELECT name, salary FROM employees WHERE salary NOT BETWEEN 50000 AND 70000;

-- 4. IN / NOT IN
SELECT * FROM employees WHERE department IN ('Sales', 'HR');
SELECT * FROM employees WHERE department NOT IN ('IT');
SELECT * FROM employees
WHERE manager_id IN (SELECT emp_id FROM employees WHERE department = 'IT');

-- 5. LIKE pattern matching
SELECT * FROM employees WHERE name LIKE 'A%';
SELECT * FROM employees WHERE name LIKE '%a';
SELECT * FROM employees WHERE name LIKE '%an%';
SELECT * FROM employees WHERE name LIKE '____';

-- 6. NULL checks
SELECT * FROM employees WHERE manager_id IS NULL;
SELECT * FROM employees WHERE manager_id IS NOT NULL;

-- 7. ORDER BY
SELECT name, salary FROM employees ORDER BY salary;
SELECT name, salary FROM employees ORDER BY salary DESC;
SELECT name, department, salary FROM employees ORDER BY department ASC, salary DESC;

-- 8. LIMIT / OFFSET
SELECT name, salary FROM employees ORDER BY salary DESC LIMIT 3;
SELECT name, salary FROM employees ORDER BY salary DESC LIMIT 3 OFFSET 3;

-- 9. Combined real-world query
SELECT name, department, salary
FROM employees
WHERE department IN ('IT', 'Sales')
  AND salary > 50000
  AND manager_id IS NOT NULL
ORDER BY department ASC, salary DESC
LIMIT 5;

-- 10. Try it yourself:
--    a) Find all employees hired after 2021-01-01 earning less than 60000
--    b) Find employees whose name contains the letter 'i'
--    c) Get the 2nd highest paid employee using ORDER BY + LIMIT + OFFSET
--    d) Find employees in Sales OR IT, but NOT earning between 50000 and 70000