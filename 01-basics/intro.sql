-- Module 01 — Basics — Practice Queries
-- Run these top to bottom in your SQL engine of choice (SQLite/MySQL/PostgreSQL)

 
-- Show all databases currently on this MySQL server
SHOW DATABASES;
 
-- Create a new database called "organization"
CREATE DATABASE organization;
 
-- Tell MySQL we want to work inside the "organization" database
-- (every command after this runs against "organization" until you USE another db)
USE organization;
 
-- Show all tables inside the currently selected database
-- (will be empty right now since we haven't created any tables yet)
SHOW TABLES;
 
-- Bonus: check which database you're currently using
SELECT DATABASE();
 
-- Bonus: see the MySQL version you're running
SELECT VERSION();
 
-- Bonus: drop the database (ONLY run this if you want to delete "organization" and start over)
-- DROP DATABASE organization;
 

-- 1. Setup: create table and seed data
CREATE TABLE employees (
    emp_id     INT PRIMARY KEY,
    name       VARCHAR(50),
    department VARCHAR(50),
    salary     DECIMAL(10,2),
    hire_date  DATE,
    manager_id INT
);

INSERT INTO employees (emp_id, name, department, salary, hire_date, manager_id) VALUES
(1, 'Prajyot',  'Recon', 55000, '2021-03-01', NULL),
(2, 'Rohan', 'UAC',    72000, '2020-07-15', NULL),
(3, 'Tushar', 'Recon', 58000, '2022-01-10', 1),
(4, 'Vedant', 'Switch',    65000, '2023-05-20', 2),
(5, 'Kartik', 'Switch',    49000, '2021-11-30', NULL);

-- 2. Select everything
SELECT * FROM employees;

-- 3. Select specific columns
SELECT name, salary FROM employees;

-- 4. Alias columns
SELECT name AS employee_name, salary AS monthly_salary FROM employees;

-- 5. Calculated column
SELECT name, salary, salary * 12 AS annual_salary FROM employees;

-- 6. Filter with WHERE
SELECT name, department FROM employees WHERE department = 'Recon';

-- 7. Distinct values
SELECT DISTINCT department FROM employees;

-- 8. Combine filter + alias + calculation
SELECT name AS employee, department, salary * 12 AS annual_pay
FROM employees
WHERE salary > 50000;

-- 9. NULL handling — the WRONG way (returns nothing, common beginner trap)
SELECT * FROM employees WHERE manager_id = NULL;

-- 10. NULL handling — the CORRECT way
SELECT * FROM employees WHERE manager_id IS NULL;
SELECT * FROM employees WHERE manager_id IS NOT NULL;

-- 11. Try it yourself:
--    a) Select name and hire_date for everyone in Recon
--    b) Select distinct managers (manager_id) ignoring NULLs
--    c) Compute a 10% bonus column (salary * 0.10) for every employee