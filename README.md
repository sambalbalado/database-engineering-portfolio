# Database Engineering Portfolio

Two personal database case studies by **Esaam Matudin**, exploring data modelling, Oracle integrity and transactions, and relational-to-document workflows. These originated as completed educational exercises and were curated for a portfolio with documented corrections and AI-assisted additions. They are demonstration systems with synthetic data.

| Case study | Business problem | Start here |
| --- | --- | --- |
| **Waste collection** | Track property ownership, RFID bins, historical contract prices and weight-based collection charges. | [Case study](case-studies/waste-collection/README.md) · [Normalisation](case-studies/waste-collection/design/normalisation.md) |
| **Transport logistics** | Move from a customer quote to a scheduled job, preserve price revisions, report vehicle usage and export customer documents. | [Case study](case-studies/transport-logistics/README.md) · [Oracle implementation](case-studies/transport-logistics/sql/) |

The domains have independent schemas and reset scripts. Shared conventions make the evidence easy to inspect without inventing a relationship between the businesses.

## Skills and evidence

| Skill | Concrete evidence |
| --- | --- |
| Conceptual and logical modelling | [Editable conceptual model](case-studies/waste-collection/models/conceptual-baseline.drawio), [Oracle Data Modeler project](case-studies/waste-collection/models/data-modeler/waste-collection-baseline.dmd), [model previews](case-studies/waste-collection/design/logical-baseline.png) |
| Normalisation and keys | [UNF through 3NF, dependencies and integration review](case-studies/waste-collection/design/normalisation.md) |
| Relational integrity | [Waste integrity overlay](case-studies/waste-collection/sql/02-integrity.sql), [approved transport combinations](case-studies/transport-logistics/sql/03-integrity.sql) |
| Oracle SQL and metadata | [Generated waste baseline DDL](case-studies/waste-collection/sql/01-schema.sql), [core transport DDL and column comments](case-studies/transport-logistics/sql/02-core-schema.sql) |
| Transactions and sequences | [Booking, rescheduling and cancellation](case-studies/transport-logistics/sql/06-booking-lifecycle.sql) |
| Schema evolution | [Quote status and maintenance tables](case-studies/transport-logistics/sql/07-schema-evolution.sql), [status synchronization](case-studies/transport-logistics/sql/08-evolution-integrity.sql) |
| Reporting and null handling | [Vehicle usage and customer reports](case-studies/transport-logistics/sql/10-reporting.sql), [historical supply costs](case-studies/waste-collection/sql/04-collection-report.sql) |
| SQL/JSON | [Nested customer JSON generation](case-studies/transport-logistics/sql/11-customer-json.sql), [synthetic document example](case-studies/transport-logistics/examples/customers.json) |
| MongoDB | [Embedded documents, filtering, projection and atomic updates](case-studies/transport-logistics/mongodb/customer-demo.mongodb.js) |
| Verification | [Portable static checks](tools/check_portfolio.py), [Oracle assertions](case-studies/transport-logistics/verification/assertions.sql), [MongoDB assertions](case-studies/transport-logistics/mongodb/assertions.mongodb.js) |

## Inspect or reproduce

Read either case study without installing a database. Open `.drawio` in diagrams.net, or open the `.dmd` with its entire adjacent directory in Oracle SQL Developer Data Modeler. The cleaned baseline PDFs and PNGs show the original design; the current-model notes explain the SQL overlay.

For execution, use **Oracle Database 19c or later** with SQL*Plus or SQLcl, and **MongoDB 7+ with mongosh** for the document demonstration. These are intended compatibility targets, not runtime-certified versions. The original generated waste DDL targeted Oracle 12c, but the portfolio JSON path uses CLOB generation supported by the chosen 19c baseline. [Oracle documents SQL/JSON generation and return types](https://docs.oracle.com/en/database/oracle/oracle-database/19/adjsn/generation.html).

[Setup and exact commands](docs/SETUP.md) cover two dedicated disposable Oracle users, separate reset commands, JSON export and MongoDB execution. From the repository root, run the database-independent checks with:

```sh
python3 tools/check_portfolio.py
node --check case-studies/transport-logistics/mongodb/customer-demo.mongodb.js
node --check case-studies/transport-logistics/mongodb/assertions.mongodb.js
```

## Verification status

The preparation review executed static fixture checks, model/SQL comparison, JSON reconciliation, script-path and documentation-link checks, JavaScript syntax checks, and a public-content scan. The exact results are recorded in [the verification report](docs/VERIFICATION.md).

**Oracle and MongoDB were unavailable during portfolio preparation.** Schema creation, PL/SQL compilation, client export behaviour, database constraints and MongoDB operations remain unexecuted. The supplied waste-schema transcript is kept as [historical evidence](case-studies/waste-collection/verification/historical-schema-output.txt), clearly separated from new checks. No runtime success or performance claims are made.

See [corrections](docs/CORRECTIONS.md) and [authorship and material boundaries](docs/AUTHORSHIP.md) for what came from the original work and what was added. No open-source licence is granted by this repository.
