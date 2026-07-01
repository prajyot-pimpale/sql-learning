-- Module 11 — Transactions — Practice Queries

-- Setup
CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    owner      VARCHAR(50),
    balance    DECIMAL(10,2) CHECK (balance >= 0)
);
INSERT INTO accounts VALUES (1, 'Asha', 1000), (2, 'Rohan', 500);

-- 1. Successful transaction — transfer 200 from Asha to Rohan
BEGIN;
UPDATE accounts SET balance = balance - 200 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 200 WHERE account_id = 2;
COMMIT;

SELECT * FROM accounts; -- Asha: 800, Rohan: 700

-- 2. Deliberately cancelled transaction
BEGIN;
UPDATE accounts SET balance = balance - 200 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 200 WHERE account_id = 2;
ROLLBACK;

SELECT * FROM accounts; -- unchanged from before this block

-- 3. Transaction that fails partway (CHECK constraint stops a negative balance)
BEGIN;
UPDATE accounts SET balance = balance - 200 WHERE account_id = 1;
-- This next line intentionally tries to overdraw and should error:
-- UPDATE accounts SET balance = balance - 99999 WHERE account_id = 2;
ROLLBACK; -- run this if the above errored, to undo the first UPDATE too

-- 4. SAVEPOINT example
BEGIN;
UPDATE accounts SET balance = balance - 200 WHERE account_id = 1;
SAVEPOINT after_debit;
UPDATE accounts SET balance = balance + 200 WHERE account_id = 99; -- no such account, 0 rows affected
ROLLBACK TO after_debit;
UPDATE accounts SET balance = balance + 200 WHERE account_id = 2; -- correct account
COMMIT;

SELECT * FROM accounts;

-- 5. Setting isolation level (PostgreSQL/MySQL)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN;
SELECT * FROM accounts;
COMMIT;

-- 6. Try it yourself:
--    a) Write a transaction transferring money between 3 accounts (A->B->C) atomically
--    b) Deliberately trigger a CHECK violation mid-transaction and confirm ROLLBACK restores state
--    c) Use a SAVEPOINT to undo only the last of 3 updates, keeping the first two
--    d) Research your engine's default isolation level and explain what it allows/prevents