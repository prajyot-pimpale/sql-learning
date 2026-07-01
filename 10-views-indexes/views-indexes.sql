-- Module 10 — Views & Indexes — Practice Queries

-- Setup
CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50)
);
INSERT INTO departments VALUES (1, 'Sales'), (2, 'IT'), (3, 'HR');

CREATE TABLE employees (
    emp_id    INT PRIMARY KEY,
    name      VARCHAR(50),
    email     VARCHAR(100) UNIQUE,
    salary    DECIMAL(10,2),
    dept_id   INT,
    hire_date DATE
);
INSERT INTO employees VALUES
(1, 'Asha',  'asha@co.com',  55000, 1, '2021-03-01'),
(2, 'Rohan', 'rohan@co.com', 72000, 2, '2020-07-15'),
(3, 'Meera', 'meera@co.com', 58000, 1, '2022-01-10'),
(4, 'Karan', 'karan@co.com', 65000, 2, '2023-05-20'),
(5, 'Divya', 'divya@co.com', 49000, 3, '2021-11-30');

-- 1. Simple view
CREATE VIEW high_earners AS
SELECT name, salary, dept_id
FROM employees
WHERE salary > 60000;

SELECT * FROM high_earners;
SELECT name FROM high_earners WHERE dept_id = 2;

-- 2. View joining multiple tables
CREATE VIEW employee_directory AS
SELECT e.name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_directory WHERE dept_name = 'Sales';

-- 3. View with aggregation
CREATE VIEW department_summary AS
SELECT d.dept_name, COUNT(*) AS headcount, AVG(e.salary) AS avg_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name;

SELECT * FROM department_summary;

-- 4. Replace a view's definition (PostgreSQL/MySQL)
CREATE OR REPLACE VIEW high_earners AS
SELECT name, salary, dept_id FROM employees WHERE salary > 65000;

-- 5. Update through a simple (non-aggregated) view
UPDATE high_earners SET salary = 70000 WHERE name = 'Rohan';
SELECT * FROM employees WHERE name = 'Rohan'; -- confirm the real table changed

-- 6. Drop a view
DROP VIEW IF EXISTS high_earners;

-- 7. Materialized view (PostgreSQL only)
-- CREATE MATERIALIZED VIEW department_summary_cached AS
-- SELECT d.dept_name, COUNT(*) AS headcount, AVG(e.salary) AS avg_salary
-- FROM employees e JOIN departments d ON e.dept_id = d.dept_id
-- GROUP BY d.dept_name;
-- REFRESH MATERIALIZED VIEW department_summary_cached;

-- 8. Basic index
CREATE INDEX idx_employees_dept_id ON employees(dept_id);

-- 9. Composite index
CREATE INDEX idx_employees_dept_salary ON employees(dept_id, salary);

-- 10. Unique index
CREATE UNIQUE INDEX idx_employees_email ON employees(email);

-- 11. Check query plan (confirm index usage)
EXPLAIN SELECT * FROM employees WHERE dept_id = 1;

-- 12. View existing indexes
-- PostgreSQL:
-- SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'employees';
-- MySQL:
-- SHOW INDEX FROM employees;

-- 13. Drop an index
-- PostgreSQL: DROP INDEX idx_employees_dept_id;
-- MySQL: DROP INDEX idx_employees_dept_id ON employees;

-- 14. Try it yourself:
--    a) Create a view showing only employees hired before 2022
--    b) Create an index on hire_date and run EXPLAIN to confirm it's used when filtering by date
--    c) Try updating through the department_summary view — confirm it fails (it's aggregated)
--    d) Create a composite index on (dept_id, hire_date) and think through which queries it helps