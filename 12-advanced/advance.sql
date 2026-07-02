-- Module 12 — Advanced SQL — Practice Queries
-- Note: stored procedure / trigger syntax shown is PostgreSQL — MySQL syntax differs (see README)

-- Setup
CREATE TABLE employees (
    emp_id     INT PRIMARY KEY,
    name       VARCHAR(50),
    dept_id    INT,
    salary     DECIMAL(10,2),
    hire_date  DATE,
    manager_id INT
);
INSERT INTO employees VALUES
(1, 'Asha',  1, 55000, '2021-03-01', NULL),
(2, 'Rohan', 2, 72000, '2020-07-15', NULL),
(3, 'Meera', 1, 58000, '2022-01-10', 1),
(4, 'Karan', 2, 65000, '2023-05-20', 2),
(5, 'Divya', 3, 49000, '2021-11-30', NULL),
(6, 'Tina',  2, 81000, '2019-09-05', 2);

-- 1. Basic CTE
WITH dept_averages AS (
    SELECT dept_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY dept_id
)
SELECT e.name, e.salary, d.avg_salary
FROM employees e
JOIN dept_averages d ON e.dept_id = d.dept_id
WHERE e.salary > d.avg_salary;

-- 2. Multiple CTEs
WITH dept_averages AS (
    SELECT dept_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY dept_id
),
high_avg_depts AS (
    SELECT dept_id FROM dept_averages WHERE avg_salary > 60000
)
SELECT e.name, e.dept_id
FROM employees e
WHERE e.dept_id IN (SELECT dept_id FROM high_avg_depts);

-- 3. Recursive CTE — management chain
WITH RECURSIVE management_chain AS (
    SELECT emp_id, name, manager_id, 1 AS level
    FROM employees
    WHERE emp_id = 4

    UNION ALL

    SELECT e.emp_id, e.name, e.manager_id, mc.level + 1
    FROM employees e
    JOIN management_chain mc ON e.emp_id = mc.manager_id
)
SELECT * FROM management_chain;

-- 4. Window function: running total
SELECT name, salary,
    SUM(salary) OVER (ORDER BY emp_id) AS running_total
FROM employees;

-- 5. RANK / DENSE_RANK / ROW_NUMBER comparison
SELECT name, salary,
    RANK() OVER (ORDER BY salary DESC) AS rank_val,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rank_val,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_num
FROM employees;

-- 6. PARTITION BY — rank within each department
SELECT name, dept_id, salary,
    RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rank_in_dept
FROM employees;

-- 7. Top earner per department (ROW_NUMBER + CTE)
WITH ranked AS (
    SELECT name, dept_id, salary,
        ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rn
    FROM employees
)
SELECT name, dept_id, salary FROM ranked WHERE rn = 1;

-- 8. LAG / LEAD
SELECT name, hire_date,
    LAG(name) OVER (ORDER BY hire_date) AS hired_before,
    LEAD(name) OVER (ORDER BY hire_date) AS hired_after
FROM employees;

-- 9. Moving average
SELECT name, hire_date, salary,
    AVG(salary) OVER (ORDER BY hire_date ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS moving_avg
FROM employees;

-- 10. Stored procedure (PostgreSQL)
CREATE OR REPLACE PROCEDURE give_raise(p_emp_id INT, p_amount DECIMAL)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE employees SET salary = salary + p_amount WHERE emp_id = p_emp_id;
    COMMIT;
END;
$$;

CALL give_raise(1, 5000);
SELECT * FROM employees WHERE emp_id = 1;

-- 11. Trigger — auto-log salary changes (PostgreSQL)
CREATE TABLE salary_audit (
    audit_id   SERIAL PRIMARY KEY,
    emp_id     INT,
    old_salary DECIMAL,
    new_salary DECIMAL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_salary_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO salary_audit (emp_id, old_salary, new_salary)
    VALUES (OLD.emp_id, OLD.salary, NEW.salary);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_salary_change
AFTER UPDATE OF salary ON employees
FOR EACH ROW
EXECUTE FUNCTION log_salary_change();

-- Test the trigger:
UPDATE employees SET salary = salary + 1000 WHERE emp_id = 2;
SELECT * FROM salary_audit;

-- 12. Try it yourself:
--    a) Write a CTE that finds employees earning more than the company-wide average
--    b) Use ROW_NUMBER() to get the 2nd highest earner per department
--    c) Write a recursive CTE to find all employees under a given manager (downward, not upward)
--    d) Write a stored procedure that transfers an employee to a new department