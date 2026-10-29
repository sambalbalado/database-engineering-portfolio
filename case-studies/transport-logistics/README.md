# Transport Logistics: Quotes, Jobs and Customer Documents

An implementation-led case study for a moving business: prepare quotes, schedule approved truck/trailer combinations, assign staff, revise actual job charges without overwriting quotes, and analyse vehicle use. A document workflow turns customer quotes and job totals into nested JSON and MongoDB records.

The **business model was supplied**. The author's original contribution is the implementation across core DDL, sample data, DML, additive schema changes, reports, JSON generation and MongoDB operations. The unavailable supplied starter is replaced by clearly labelled portfolio support DDL and fresh synthetic reference data.

## Inspect the implementation

| Area | Evidence |
| --- | --- |
| Relational structure | [Current model and keys](design/current-model.md), [reference-table support](sql/01-reference-schema.sql), [author's core DDL](sql/02-core-schema.sql), [integrity corrections](sql/03-integrity.sql) |
| Synthetic fixtures | [Reference customers and fleet](sql/04-reference-data.sql), [employee/quote/job inserts](sql/05-sample-data.sql) |
| Booking lifecycle | [Sequences, dynamic lookups, creation, 20% revision and cancellation](sql/06-booking-lifecycle.sql) |
| Schema evolution | [Quote status and service/task/log tables](sql/07-schema-evolution.sql), [status trigger and service constraints](sql/08-evolution-integrity.sql) |
| Reporting | [High-value customers, employee dispatch totals and fleet utilization](sql/10-reporting.sql) |
| SQL/JSON | [Generation query](sql/11-customer-json.sql), [export settings](sql/export-json.sql), [synthetic example](examples/customers.json) |
| MongoDB | [Insert, filter, project and update](mongodb/customer-demo.mongodb.js), [runtime assertions](mongodb/assertions.mongodb.js) |

## Key choices and assumptions

Each quote has at most one job. A quote stores the offered price; `job_cost` stores a revision only when it differs. Reports deliberately distinguish quoted revenue from effective job charges. `NVL(job_cost, quote_cost)` handles unchanged prices.

Jobs reference an approved `(truck_vin, trailer_code)` pair. Employee foreign keys preserve identity but do not by themselves enforce dispatcher/driver/mechanic roles; the verification script audits those cross-table rules. The local employee check requires non-managers to reference another employee, while manager-role correctness is audited separately. Scheduling and journey durations are small synthetic examples, without production resource-locking guarantees.

Quote status is backfilled during an additive migration and maintained by a job-change trigger. Maintenance tasks form an extensible catalogue; each service/task pair has one mechanic and note. Open services can have no end time. Oracle DDL commits implicitly; the migration is not presented as one rollback-safe transaction.

Currency remains formatted strings in the JSON/MongoDB contract, preserving the original approach. Customers without quotes are omitted by the relational exporter; the document demo separately adds a customer with an empty array. The new customer's update changes summary fields and appends the quote in a single document operation. It assumes this customer has only that one quote; it is not a general statistics-maintenance engine.

## Run

Prerequisites: Oracle 19c+, SQL*Plus or SQLcl, and an empty dedicated `PORTFOLIO_TRANSPORT` user. MongoDB 7+ and mongosh are needed only for the document operations. [Exact setup, execution order, export and reset commands](../../docs/SETUP.md) are shared at the root.

```sql
@case-studies/transport-logistics/sql/setup.sql
@case-studies/transport-logistics/sql/export-json.sql
```

The guarded setup creates reference/core tables, applies integrity, loads reference/sample fixtures, runs the booking lifecycle, migrates schema, demonstrates maintenance, executes assertions and prints reports. [Reset](sql/reset.sql) is a separate confirmation step in the dedicated user.

Expected final fixture shape: 11 employees, 33 quotes, 20 jobs, 13 approved vehicle pairs (3 unused), and one service with two tasks. The lifecycle quote remains after its job is cancelled. Dispatcher 300 has zero active jobs; the employee report should display `0`. Quotes and jobs include five revised costs and fifteen quote-price fallbacks. These are static expectations; database execution remains outstanding.

The checked-in customer JSON is an independently constructed synthetic example reconciled against this fixture. [Example notes](examples/README.md) distinguish it from an Oracle export. See [corrections](../../docs/CORRECTIONS.md), [authorship](../../docs/AUTHORSHIP.md) and [actual verification](../../docs/VERIFICATION.md).
