# SQL Learning Repository

A from-scratch, structured path to learn SQL — concepts + queries, no GUI tools required.
Every folder is a module. Each module has a `README.md` with theory + multiple worked
scenarios, and a `queries.sql` file with runnable practice queries.

## How to practice (no GUI needed)
You only need a SQL engine you can talk to from a terminal. Pick one:

- **SQLite** — zero install pain, file-based. `sqlite3 mydb.db` then start typing SQL.
- **MySQL** — `mysql -u root -p` after installing `mysql-server`.
- **PostgreSQL** — `psql -U postgres` after installing `postgresql`.

For this course, examples are written in **standard ANSI SQL** with notes wherever a
database (MySQL/PostgreSQL/SQLite/SQL Server) does something differently.

## Roadmap

| # | Module | Status |
|---|--------|--------|
| 01 | [Basics](./01-basics/README.md) — what SQL is, RDBMS concepts, SQL sublanguages | ✅ |
| 02 | [DDL](./02-ddl/README.md) — CREATE, ALTER, DROP, TRUNCATE | ✅ |
| 03 | [DML](./03-dml/README.md) — INSERT, UPDATE, DELETE | ✅ |
| 04 | [Queries & Filtering](./04-queries-filtering/README.md) — SELECT, WHERE, ORDER BY, LIMIT | ✅  |
| 05 | [Joins](./05-joins/README.md) — INNER, LEFT, RIGHT, FULL, SELF, CROSS | ✅ |
| 06 | [Aggregation](./06-aggregation/README.md) — GROUP BY, HAVING, aggregate functions | ✅ |
| 07 | [Subqueries](./07-subqueries/README.md) — scalar, correlated, EXISTS, IN | ✅ |
| 08 | [Functions](./08-functions/) — string, numeric, date, conditional | ✅ |
| 09 | [Constraints & Keys](./09-constraints-keys/) — PK, FK, UNIQUE, CHECK, NOT NULL | ✅ |
| 10 | [Views & Indexes](./10-views-indexes/README.md) | ✅ |
| 11 | [Transactions](./11-transactions/README.md) — COMMIT, ROLLBACK, ACID, isolation | ✅ |
| 12 | Advanced — window functions, CTEs, stored procedures, triggers | ⏳ |
| 13 | Set Operations & Extras — UNION, INTERSECT, EXCEPT, pivoting, GRANT/REVOKE | ⏳ |
| 14 | Database Design Basics — normalization, ER modeling | ⏳ |
<!--
| 12 | [Advanced](./12-advanced/README.md) — window functions, CTEs, stored procedures, triggers | ✅ |
| 13 | [Set Operations & Extras](./13-set-operations-extras/README.md) — UNION, INTERSECT, EXCEPT, pivoting, GRANT/REVOKE | ✅ |
| 14 | [Database Design Basics](./14-database-design/README.md) — normalization, ER modeling | ✅ |
 
📄 Also see [notes.md](./notes.md) — a condensed cheat sheet covering every module.
📄 [Interview Prep — 64 Questions](./interview-prep/sql-interview-questions.md) — covers every module, with answers and example queries.
 -->
**Status: all 09 modules complete.** 🎉
 
## Suggested daily workflow
1. Read the module's `README.md` fully (concept first, then examples).
2. Open `queries.sql`, run every query yourself — don't just read it.
3. Modify each example with your own table/data to confirm you understand *why*, not just *what*.
4. Commit your modified queries.sql to your fork as your "practice log."

---
*This repo is built incrementally — one module fully completed before moving to the next.*