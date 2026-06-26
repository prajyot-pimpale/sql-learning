-- Module 05 — Joins — Practice Queries

-- Setup
CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50)
);

INSERT INTO departments VALUES
(1, 'Sales'),
(2, 'IT'),
(3, 'HR'),
(4, 'Marketing');

CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    name        VARCHAR(50),
    salary      DECIMAL(10,2),
    dept_id     INT,
    manager_id  INT
);

INSERT INTO employees VALUES
(1, 'Asha',  55000, 1, NULL),
(2, 'Rohan', 72000, 2, NULL),
(3, 'Meera', 58000, 1, 1),
(4, 'Karan', 65000, 2, 2),
(5, 'Divya', 49000, NULL, NULL);

CREATE TABLE projects (
    project_id   INT PRIMARY KEY,
    project_name VARCHAR(50),
    emp_id       INT
);
INSERT INTO projects VALUES
(1, 'Website Redesign', 1),
(2, 'CRM Migration', 2),
(3, 'Ad Campaign', 3);

-- 1. INNER JOIN
SELECT e.name, e.salary, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- 2. INNER JOIN with filter
SELECT e.name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;

-- 3. LEFT JOIN
SELECT e.name, e.dept_id, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;

-- 4. Find employees with no department (LEFT JOIN + IS NULL pattern)
SELECT e.name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;

-- 5. RIGHT JOIN
SELECT e.name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- 6. Same result as RIGHT JOIN, using LEFT JOIN with swapped tables (preferred style)
SELECT e.name, d.dept_name
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id;

-- 7. Find departments with zero employees
SELECT d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;

-- 8. FULL JOIN (PostgreSQL/SQL Server; for MySQL use the UNION version below)
SELECT e.name, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id;

-- 8b. FULL JOIN emulation for MySQL
SELECT e.name, d.dept_name FROM employees e LEFT JOIN departments d ON e.dept_id = d.dept_id
UNION
SELECT e.name, d.dept_name FROM employees e RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- 9. SELF JOIN — employee to manager
SELECT emp.name AS employee, mgr.name AS manager
FROM employees emp
LEFT JOIN employees mgr ON emp.manager_id = mgr.emp_id;

-- 10. CROSS JOIN
SELECT e.name, d.dept_name
FROM employees e
CROSS JOIN departments d;

-- 11. Joining 3 tables
SELECT e.name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON e.emp_id = p.emp_id;

-- 12. Try it yourself:
--    a) List every department with its employee count (hint: needs Module 06 — try anyway)
--    b) Find all employees who are NOT assigned to any project
--    c) List every employee with their manager's name AND their department name (3-way join)
--    d) Find departments that have employees earning above 60000