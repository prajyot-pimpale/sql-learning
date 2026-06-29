-- Module 07 — Subqueries — Practice Queries

-- Setup
CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50)
);
INSERT INTO departments VALUES (1, 'Sales'), (2, 'IT'), (3, 'HR');

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
(5, 'Divya', 49000, 3, NULL),
(6, 'Tina',  81000, 2, 2);

-- 1. Scalar subquery in WHERE
SELECT name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- 2. Scalar subquery in SELECT list
SELECT name, salary,
       (SELECT AVG(salary) FROM employees) AS company_avg
FROM employees;

-- 3. Correlated scalar subquery — top earner per department
SELECT name, salary, dept_id
FROM employees e
WHERE salary = (
    SELECT MAX(salary) FROM employees WHERE dept_id = e.dept_id
);

-- 4. IN with subquery
SELECT name, dept_id
FROM employees
WHERE dept_id IN (
    SELECT dept_id FROM employees GROUP BY dept_id HAVING COUNT(*) > 1
);

-- 5. NOT IN with subquery (NULL-safe version)
SELECT name
FROM employees
WHERE emp_id NOT IN (
    SELECT manager_id FROM employees WHERE manager_id IS NOT NULL
);

-- 6. EXISTS — departments with at least one employee
SELECT d.dept_name
FROM departments d
WHERE EXISTS (
    SELECT 1 FROM employees e WHERE e.dept_id = d.dept_id
);

-- 7. NOT EXISTS — departments with no employees
SELECT d.dept_name
FROM departments d
WHERE NOT EXISTS (
    SELECT 1 FROM employees e WHERE e.dept_id = d.dept_id
);

-- 8. EXISTS — employees who manage someone
SELECT name
FROM employees m
WHERE EXISTS (
    SELECT 1 FROM employees e WHERE e.manager_id = m.emp_id
);

-- 9. Correlated subquery — above own department's average
SELECT name, salary
FROM employees e
WHERE salary > (SELECT AVG(salary) FROM employees WHERE dept_id = e.dept_id);

-- 10. Second-highest salary via correlated subquery
SELECT name, salary
FROM employees e1
WHERE 1 = (
    SELECT COUNT(*) FROM employees e2 WHERE e2.salary > e1.salary
);

-- 11. Derived table (subquery in FROM)
SELECT dept_id, avg_salary
FROM (
    SELECT dept_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY dept_id
) AS dept_averages
WHERE avg_salary > 60000;

-- 12. Try it yourself:
--    a) Find the 3rd-highest salary using the "count how many earn more" pattern
--    b) Find employees earning less than their own manager
--    c) Find departments where the average salary is above the company-wide average
--    d) Rewrite query #6 (EXISTS) using a JOIN instead — confirm you get the same result