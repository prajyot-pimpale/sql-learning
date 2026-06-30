-- Module 09 — Constraints & Keys — Practice Queries

-- 1. PRIMARY KEY — single column
CREATE TABLE employees_pk_demo (
    emp_id INT PRIMARY KEY,
    name   VARCHAR(50)
);
INSERT INTO employees_pk_demo VALUES (1, 'Asha');
-- INSERT INTO employees_pk_demo VALUES (1, 'Rohan'); -- uncomment to see the error

-- 2. PRIMARY KEY — composite
CREATE TABLE enrollments (
    student_id  INT,
    course_id   INT,
    enrolled_on DATE,
    PRIMARY KEY (student_id, course_id)
);
INSERT INTO enrollments VALUES (1, 101, '2024-01-10');
INSERT INTO enrollments VALUES (1, 102, '2024-01-15'); -- fine, different course
-- INSERT INTO enrollments VALUES (1, 101, '2024-02-01'); -- uncomment: violates composite PK

-- 3. FOREIGN KEY basic setup
CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50)
);
INSERT INTO departments VALUES (1, 'Sales'), (2, 'IT');

CREATE TABLE employees (
    emp_id  INT PRIMARY KEY,
    name    VARCHAR(50) NOT NULL,
    email   VARCHAR(100) UNIQUE NOT NULL,
    salary  DECIMAL(10,2) CHECK (salary >= 0) DEFAULT 0,
    dept_id INT,
    status  VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive')),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id) ON DELETE SET NULL
);

INSERT INTO employees (emp_id, name, email, salary, dept_id) VALUES
(1, 'Asha', 'asha@co.com', 55000, 1),
(2, 'Rohan', 'rohan@co.com', 72000, 2);

-- 4. FOREIGN KEY violation demo
-- INSERT INTO employees (emp_id, name, email, dept_id) VALUES (3, 'Bad', 'bad@co.com', 99);
-- uncomment to see: ERROR, dept_id 99 doesn't exist

-- 5. ON DELETE SET NULL demo
DELETE FROM departments WHERE dept_id = 2;
SELECT * FROM employees; -- Rohan's dept_id is now NULL, row survives

-- 6. UNIQUE constraint demo
-- INSERT INTO employees (emp_id, name, email, dept_id) VALUES (4, 'Dup', 'asha@co.com', 1);
-- uncomment to see: ERROR, duplicate email

-- 7. NOT NULL demo
-- INSERT INTO employees (emp_id, email) VALUES (5, 'noname@co.com');
-- uncomment to see: ERROR, name cannot be NULL

-- 8. CHECK constraint demo
-- INSERT INTO employees (emp_id, name, email, salary, dept_id) VALUES (6, 'Neg', 'neg@co.com', -500, 1);
-- uncomment to see: ERROR, salary CHECK violated

-- 9. CHECK against fixed list demo
-- INSERT INTO employees (emp_id, name, email, dept_id, status) VALUES (7, 'X', 'x@co.com', 1, 'Retired');
-- uncomment to see: ERROR, status must be Active or Inactive

-- 10. DEFAULT values demo
INSERT INTO employees (emp_id, name, email, dept_id) VALUES (8, 'Karan', 'karan@co.com', 1);
SELECT * FROM employees WHERE emp_id = 8; -- salary = 0, status = 'Active' automatically

-- 11. Adding constraints to an existing table
ALTER TABLE employees ADD CONSTRAINT chk_name_length CHECK (LENGTH(name) > 1);

-- 12. Try it yourself:
--    a) Create a "bookings" table with a composite UNIQUE constraint on (room_id, booking_date)
--    b) Try inserting a duplicate booking and confirm it fails
--    c) Create a foreign key with ON DELETE CASCADE and observe child rows disappearing
--    d) Add a CHECK constraint ensuring an "age" column is between 18 and 65