# Reproduce the demonstrations

## Oracle prerequisites

Use Oracle Database **19c or later** and SQL*Plus or SQLcl. The scripts use Oracle `NUMBER`, `VARCHAR2`, `DATE`, sequences, `NVL`, dictionary comments, SQL/JSON, anonymous PL/SQL assertion blocks and a trigger. SQL Developer's Run Script mode is useful for inspection, but the exact commands below use a command-line client. No other database engine validates this implementation.

Have a database administrator create **two dedicated disposable users**, `PORTFOLIO_WASTE` and `PORTFOLIO_TRANSPORT`, each with `CREATE SESSION`, `CREATE TABLE`, `CREATE SEQUENCE`, `CREATE TRIGGER`, and a quota on its default tablespace. No administrator privileges are needed by the demonstration itself. Provision passwords privately; do not place them in repository files or shell commands.

Run from the repository root. These examples assume a local Oracle service `FREEPDB1` on port 1521; substitute your actual host/service. The client prompts for the password.

```sh
sqlplus portfolio_waste@//localhost:1521/FREEPDB1
```

At the SQL prompt:

```sql
@case-studies/waste-collection/sql/setup.sql
```

Open a separate client connection for transport:

```sh
sqlplus portfolio_transport@//localhost:1521/FREEPDB1
```

```sql
@case-studies/transport-logistics/sql/setup.sql
```

Each runner checks the logged-in user and current schema, sets deterministic language/number settings, creates objects in an empty schema, loads synthetic data and runs assertions. It stops on SQL errors. DDL commits implicitly in Oracle, so failure can leave a partially prepared schema; inspect the error, then reset the dedicated environment and rerun. An assertion script prints a success message only when it actually runs successfully.

### Exact Oracle order

| Waste collection | Transport logistics |
| --- | --- |
| `00-guard.sql` | `00-guard.sql` |
| `01-schema.sql` | `01-reference-schema.sql` |
| `02-integrity.sql` | `02-core-schema.sql` |
| `03-demo-data.sql` | `03-integrity.sql` |
| `verification/assertions.sql` | `04-reference-data.sql` |
| `04-collection-report.sql` | `05-sample-data.sql` |
| | `06-booking-lifecycle.sql` |
| | `07-schema-evolution.sql` |
| | `08-evolution-integrity.sql` |
| | `09-maintenance-demo.sql` |
| | `verification/assertions.sql` |
| | `10-reporting.sql` |

These filenames are relative to each case study's `sql/` directory except the verification entries. Prefer `setup.sql`, whose `@@` references are relative to the containing script. The transport lifecycle is a one-time ordered demonstration with several explicit business-transaction commits. Its quote/job creation is one transaction. Run the whole setup against a fresh schema rather than replaying individual lifecycle steps.

### Explicit reset

Within the corresponding dedicated connection:

```sql
@case-studies/waste-collection/sql/reset.sql
```

or:

```sql
@case-studies/transport-logistics/sql/reset.sql
```

Reset prompts for the exact confirmation token displayed, checks the schema, and drops only that case study's named objects. It is destructive and intended for the disposable users above. Both domains contain a `TRUCK` table, which is why their users must remain separate.

## Export Oracle customer documents

After transport setup, in its SQL client:

```sql
@case-studies/transport-logistics/sql/export-json.sql
```

This writes `customers.ndjson` in the client's working directory. The query emits one CLOB JSON object per customer with quotes. Then, from the repository root:

```sh
python3 tools/ndjson_to_array.py customers.ndjson customers-generated.json
```

A malformed or client-wrapped export fails JSON parsing. The SQL client sets a 32,767-character line width; this small fixture fits within that limit. For larger documents, use a CLOB-capable programmatic client rather than treating these spool settings as an unlimited exporter. Generated exports are ignored by Git.

## MongoDB prerequisites and execution

Use **MongoDB 7 or later** with **mongosh**. These scripts use a disposable `portfolio_transport` database and no credentials in the examples. Do not point them at a shared database. From the repository root, use the checked-in independent synthetic example:

```sh
PORTFOLIO_RESET=YES mongosh 'mongodb://localhost:27017/portfolio_transport'   --file case-studies/transport-logistics/mongodb/customer-demo.mongodb.js   --file case-studies/transport-logistics/mongodb/assertions.mongodb.js
```

To exercise your actual Oracle export instead:

```sh
PORTFOLIO_RESET=YES PORTFOLIO_CUSTOMERS=customers-generated.json   mongosh 'mongodb://localhost:27017/portfolio_transport'   --file case-studies/transport-logistics/mongodb/customer-demo.mongodb.js   --file case-studies/transport-logistics/mongodb/assertions.mongodb.js
```

The demonstration resets **only `brm_customers`**, inserts the six customers, filters Melbourne customers with multiple quotes, inserts a new customer, and adds one paid quote atomically with its summary. Fixed assertions expect this documented fixture, not arbitrary imported data. Re-running the full demonstration resets it; there is no database-wide drop. [MongoDB documents script-file execution](https://www.mongodb.com/docs/mongodb-shell/reference/options/).

Currency is retained as formatted strings to preserve the original document contract. This is suitable for display examples; an analytical document model should use a numeric money representation and an explicit payment state per embedded job. Those would be schema changes beyond this portfolio cleanup.

## Independent checks

```sh
python3 tools/check_portfolio.py
node --check case-studies/transport-logistics/mongodb/customer-demo.mongodb.js
node --check case-studies/transport-logistics/mongodb/assertions.mongodb.js
```

The portable check uses only Python's standard library. It inspects fixture consistency, joins and identifiers, documentation/script paths, model XML and blocked public-content patterns. It does not execute Oracle or MongoDB.
