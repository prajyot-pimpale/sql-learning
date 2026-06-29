-- Module 06 — Aggregation — Practice Queries

-- Setup
CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50)
);
INSERT INTO departments VALUES (1, 'Sales'), (2, 'IT'), (3, 'HR'), (4, 'Marketing');

CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    name        VARCHAR(50),
    salary      DECIMAL(10,2),
    dept_id     INT,
    hire_date   DATE
);
INSERT INTO employees VALUES
(1, 'Asha',  55000, 1, '2021-03-01'),
(2, 'Rohan', 72000, 2, '2020-07-15'),
(3, 'Meera', 58000, 1, '2022-01-10'),
(4, 'Karan', 65000, 2, '2023-05-20'),
(5, 'Divya', 49000, 3, '2021-11-30'),
(6, 'Tina',  81000, 2, '2019-09-05'),
(7, 'Sam',   47000, 1, '2023-02-14');

-- 1. Basic aggregates
SELECT COUNT(*) FROM employees;
SELECT COUNT(dept_id) FROM employees;
SELECT COUNT(DISTINCT dept_id) FROM employees;
SELECT SUM(salary) FROM employees;
SELECT AVG(salary) FROM employees;
SELECT MIN(salary) AS lowest, MAX(salary) AS highest FROM employees;

-- 2. Multiple aggregates in one query
SELECT
    COUNT(*)      AS total_employees,
    SUM(salary)   AS total_payroll,
    AVG(salary)   AS avg_salary,
    MIN(salary)   AS min_salary,
    MAX(salary)   AS max_salary
FROM employees;

-- 3. GROUP BY — count per department
SELECT dept_id, COUNT(*) AS employee_count
FROM employees
GROUP BY dept_id;

-- 4. GROUP BY — total and average salary per department
SELECT dept_id, SUM(salary) AS total_salary, AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id;

-- 5. GROUP BY with JOIN — readable department names
SELECT d.dept_name, COUNT(*) AS employee_count, AVG(e.salary) AS avg_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name;

-- 6. HAVING — departments with more than 1 employee
SELECT dept_id, COUNT(*) AS employee_count
FROM employees
GROUP BY dept_id
HAVING COUNT(*) > 1;

-- 7. HAVING — average salary above threshold
SELECT dept_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id
HAVING AVG(salary) > 60000;

-- 8. WHERE + GROUP BY + HAVING combined
SELECT dept_id, AVG(salary) AS avg_salary
FROM employees
WHERE salary > 45000
GROUP BY dept_id
HAVING AVG(salary) > 55000;

-- 9. Full combined real-world query
SELECT d.dept_name, COUNT(*) AS headcount, AVG(e.salary) AS avg_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 45000
GROUP BY d.dept_name
HAVING COUNT(*) >= 2
ORDER BY avg_salary DESC;

-- 10. Try it yourself:
--    a) Find the department with the highest total payroll
--    b) Find departments where the minimum salary is below 50000
--    c) Count how many employees were hired in each year (hint: needs date functions — preview for Module 08)
--    d) Find departments with average salary above 55000, considering only employees hired after 2020