-- Module 08 — Functions — Practice Queries
-- Note: date function syntax differs by engine; PostgreSQL/MySQL variants both shown where relevant

-- Setup
CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    first_name  VARCHAR(50),
    last_name   VARCHAR(50),
    email       VARCHAR(100),
    salary      DECIMAL(10,2),
    hire_date   DATE,
    manager_id  INT
);
INSERT INTO employees VALUES
(1, 'Asha',  'Mehta',  'asha.mehta@co.com',  55250.456, '2021-03-01', NULL),
(2, 'Rohan', 'Verma',  'rohan.verma@co.com', 72000.00,  '2020-07-15', NULL),
(3, 'Meera', 'Iyer',   'meera.iyer@co.com',  58000.00,  '2022-01-10', 1);

-- 1. String functions
SELECT CONCAT(first_name, ' ', last_name) AS full_name FROM employees;
SELECT UPPER(first_name) AS upper_name, LOWER(email) AS lower_email FROM employees;
SELECT first_name, LENGTH(first_name) AS name_length FROM employees;
SELECT email, SUBSTRING(email, 1, 4) AS first_four_chars FROM employees;
SELECT REPLACE(email, '@co.com', '@newdomain.com') AS updated_email FROM employees;
SELECT CONCAT(UPPER(first_name), ' ', UPPER(last_name)) AS full_name_caps FROM employees;

-- 2. Numeric functions
SELECT salary, ROUND(salary, 2) AS rounded_salary FROM employees;
SELECT salary, ROUND(salary, -3) AS nearest_thousand FROM employees;
SELECT salary, CEIL(salary / 1000) AS ceil_thousands, FLOOR(salary / 1000) AS floor_thousands FROM employees;
SELECT ABS(-150) AS abs_value;
SELECT emp_id, emp_id % 2 AS remainder FROM employees;

-- 3. Date functions (PostgreSQL syntax — swap for MySQL equivalents in comments)
SELECT CURRENT_DATE;
SELECT name, hire_date, EXTRACT(YEAR FROM hire_date) AS hire_year FROM employees;
-- MySQL equivalent: SELECT name, YEAR(hire_date) AS hire_year FROM employees;

SELECT hire_date, hire_date + INTERVAL '30 days' AS thirty_days_later FROM employees;
-- MySQL equivalent: SELECT hire_date, DATE_ADD(hire_date, INTERVAL 30 DAY) AS thirty_days_later FROM employees;

SELECT first_name, CURRENT_DATE - hire_date AS days_employed FROM employees;
-- MySQL equivalent: SELECT first_name, DATEDIFF(CURDATE(), hire_date) AS days_employed FROM employees;

-- 4. CASE WHEN
SELECT first_name, salary,
    CASE
        WHEN salary >= 70000 THEN 'High'
        WHEN salary >= 55000 THEN 'Medium'
        ELSE 'Low'
    END AS salary_band
FROM employees;

-- 5. CASE inside aggregate (conditional counting)
SELECT
    COUNT(CASE WHEN salary >= 60000 THEN 1 END) AS high_earners,
    COUNT(CASE WHEN salary < 60000 THEN 1 END) AS low_earners
FROM employees;

-- 6. NULL-handling functions
SELECT first_name, COALESCE(manager_id, 0) AS manager_id_or_zero FROM employees;
SELECT first_name, NULLIF(salary, 0) AS salary_or_null FROM employees;

-- 7. Combined real-world query
SELECT
    CONCAT(UPPER(first_name), ' ', last_name) AS employee_name,
    ROUND(salary, 0) AS salary_rounded,
    EXTRACT(YEAR FROM hire_date) AS hire_year,
    CASE
        WHEN salary >= 70000 THEN 'Senior Pay'
        WHEN salary >= 55000 THEN 'Mid Pay'
        ELSE 'Entry Pay'
    END AS pay_tier
FROM employees
ORDER BY salary DESC;

-- 8. Try it yourself:
--    a) Build a full email "display name" like "Asha Mehta <asha.mehta@co.com>" using CONCAT
--    b) Count how many employees were hired in each year using CASE + COUNT
--    c) Round every salary up to the nearest 500 using CEIL
--    d) Use COALESCE to show "No Manager" instead of NULL for manager_id (hint: needs a join to manager name)