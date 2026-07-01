# Module 11 — Transactions

A transaction groups multiple SQL statements into a single all-or-nothing unit. Either
**every** statement in it succeeds, or **none** of them take effect. This is what keeps
data consistent when something fails halfway through a multi-step operation — the
textbook example being a bank transfer.

Table used throughout:

```sql
CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    owner      VARCHAR(50),
    balance    DECIMAL(10,2) CHECK (balance >= 0)
);
INSERT INTO accounts VALUES (1, 'Asha', 1000), (2, 'Rohan', 500);
```

## 1. Why Transactions Exist — The Bank Transfer Problem

Transferring ₹200 from Asha to Rohan is really **two** separate updates:
```sql
UPDATE accounts SET balance = balance - 200 WHERE account_id = 1; -- Asha: -200
UPDATE accounts SET balance = balance + 200 WHERE account_id = 2; -- Rohan: +200
```
If the database crashes, the connection drops, or the second statement fails for any
reason **after** the first one succeeds — Asha has lost ₹200 that never arrived anywhere.
Money has vanished. A transaction prevents exactly this: it ensures both updates happen
together, or neither does.

## 2. `BEGIN`, `COMMIT`, `ROLLBACK` — The Core Three

| Command | Effect |
|---|---|
| `BEGIN` / `START TRANSACTION` | starts a transaction block |
| `COMMIT` | makes all changes in the transaction permanent |
| `ROLLBACK` | undoes all changes made since `BEGIN` |

### Scenario 1: A successful transaction
```sql
BEGIN;

UPDATE accounts SET balance = balance - 200 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 200 WHERE account_id = 2;

COMMIT;
```
After `COMMIT`, both changes are permanent and visible to every other connection.

### Scenario 2: A transaction you deliberately cancel
```sql
BEGIN;

UPDATE accounts SET balance = balance - 200 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 200 WHERE account_id = 2;

ROLLBACK;
```
After `ROLLBACK`, it's as if neither statement ever ran — balances return to their
pre-transaction values.

### Scenario 3: A transaction that fails partway — why ROLLBACK matters
```sql
BEGIN;

UPDATE accounts SET balance = balance - 200 WHERE account_id = 1; -- succeeds

UPDATE accounts SET balance = balance - 99999 WHERE account_id = 2;
-- ERROR: violates CHECK (balance >= 0) — Rohan can't go negative

ROLLBACK;  -- undo the first UPDATE too, since the transfer as a whole failed
```
Without the transaction wrapping both statements, Asha's balance would have been
deducted with no corresponding credit anywhere — exactly the bug transactions prevent.
Many client libraries auto-rollback on error, but explicitly understanding this flow
matters for writing correct application code.

## 3. `SAVEPOINT` — Partial Rollback Within a Transaction

A savepoint lets you roll back to a specific point *inside* a transaction, without
discarding everything.

### Scenario: Multi-step transaction with a savepoint
```sql
BEGIN;

UPDATE accounts SET balance = balance - 200 WHERE account_id = 1;

SAVEPOINT after_debit;

UPDATE accounts SET balance = balance + 200 WHERE account_id = 99; -- account doesn't exist, 0 rows affected but no error in this case

ROLLBACK TO after_debit;  -- undo only the second update, keep the first

UPDATE accounts SET balance = balance + 200 WHERE account_id = 2; -- correct account this time

COMMIT;
```
Savepoints are useful in long, multi-step transactions where you want the option to
back out of a *recent* mistake without losing everything done earlier in the same transaction.

## 4. ACID — The Four Guarantees

| Letter | Property | Meaning |
|---|---|---|
| **A** | Atomicity | All statements in a transaction succeed, or none do |
| **C** | Consistency | The database moves from one valid state to another — constraints always hold |
| **I** | Isolation | Concurrent transactions don't interfere with each other's intermediate state |
| **D** | Durability | Once committed, changes survive even a crash immediately after |

This is the theoretical backbone of why transactions are trustworthy — every major
relational database is designed around guaranteeing these four properties for committed
transactions.

## 5. Isolation Levels — How Much Concurrent Transactions Can See of Each Other

Two transactions running at the same time can interact in surprising ways without
isolation. SQL defines four standard levels, from loosest to strictest:

| Level | Prevents | Allows |
|---|---|---|
| `READ UNCOMMITTED` | nothing | can see another transaction's *uncommitted* changes ("dirty read") |
| `READ COMMITTED` | dirty reads | re-reading the same row mid-transaction can show different values |
| `REPEATABLE READ` | dirty reads, non-repeatable reads | new rows matching your query can still appear ("phantom read") |
| `SERIALIZABLE` | everything above | transactions behave as if run one at a time — strictest, slowest |

### Scenario: Setting the isolation level
```sql
-- PostgreSQL / MySQL
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN;
-- ... statements ...
COMMIT;
```
> Default isolation level differs by engine: PostgreSQL defaults to `READ COMMITTED`,
> MySQL (InnoDB) defaults to `REPEATABLE READ`. Most applications never need to change
> this — it matters mainly for high-concurrency systems (e.g., financial ledgers,
> inventory systems with simultaneous orders).

## 6. Autocommit — What Happens If You Don't Use BEGIN at All

By default, most database clients run in **autocommit mode**: every single statement is
its own transaction, committed immediately. This is why all your queries in earlier
modules "just worked" without ever typing `BEGIN`/`COMMIT` — each one was automatically
wrapped and committed individually.

```sql
-- In autocommit mode, this single UPDATE commits instantly, on its own:
UPDATE accounts SET balance = balance - 200 WHERE account_id = 1;
-- No way to roll this back once it runs, unless you explicitly started a transaction first
```
This is precisely why multi-step operations that must be atomic (like the bank transfer)
**require** explicit `BEGIN ... COMMIT/ROLLBACK` — autocommit treats each statement
independently and won't protect you across multiple statements.

## 7. Putting It All Together — Realistic Transfer Function Logic

```sql
BEGIN;

-- Step 1: check sender has enough balance (application logic would check this result)
SELECT balance FROM accounts WHERE account_id = 1;

-- Step 2: debit sender
UPDATE accounts SET balance = balance - 200 WHERE account_id = 1;

-- Step 3: credit receiver
UPDATE accounts SET balance = balance + 200 WHERE account_id = 2;

-- Step 4: only commit if both steps succeeded without error
COMMIT;
```
In real application code, this whole block sits inside a try/catch: on any error, the
code calls `ROLLBACK` instead of `COMMIT`.

## 8. Common Mistakes

```sql
-- MISTAKE: forgetting to COMMIT — changes sit "pending" and may lock rows for other users
BEGIN;
UPDATE accounts SET balance = balance - 200 WHERE account_id = 1;
-- ... forgot to COMMIT or ROLLBACK — connection left hanging, blocking other transactions

-- MISTAKE: assuming DDL is always transactional
BEGIN;
DROP TABLE accounts;
ROLLBACK;
-- In MySQL, DDL often auto-commits regardless — the table may already be gone.
-- PostgreSQL DOES support transactional DDL (this would actually be rolled back there).

-- MISTAKE: running unrelated statements inside one transaction "just in case"
-- Keep transactions focused and short — long-running transactions hold locks longer,
-- increasing contention for other users.
```

## 9. Self-check before Module 12

1. Why does the bank transfer example require a transaction instead of two separate statements?
2. What does each letter in ACID guarantee?
3. What's the difference between a "dirty read" and a "phantom read"?
4. Why doesn't `BEGIN ... ROLLBACK` always undo `DROP TABLE` in MySQL?

---
**Previous:** [Module 10 — Views & Indexes](../10-views-indexes/README.md)
**Next:** [Module 12 — Advanced](../12-advanced/README.md) *(coming next — final module)*