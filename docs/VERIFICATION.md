# Verification Record

Prepared on **29 October 2026**. The checks below distinguish executed local checks from database tests that still require the intended engines.

| Area | Actually performed | Result and limits |
| --- | --- | --- |
| Source inspection | Read the supplied SQL/JavaScript/text; extracted document text; visually read modelling PDFs and the relevant specification diagrams/reports; parsed all editable model XML. | Private inventory records source hashes, destinations, omissions and duplicate versions. No relevant archive was supplied or found in the model tree. |
| Model correspondence | Compared all 14 Data Modeler relational tables against baseline SQL. | Table and column names/order match. The current SQL overlay is documented separately. Native application reopening remains unverified. |
| Static transport fixture | Parsed literal insert values and checked identifiers, FKs against added reference data, roles, dates, optional revised costs, uniqueness and resource intervals. | 10 initial employees, 32 initial quotes, 20 jobs; fixture overlap corrected. Lifecycle additions/cancellation are reviewed separately and have runtime assertions. |
| Report expectations | Independently counted used/unused pairs and compared quoted/effective costs. | 10 used pairs, 3 unused, average 2 jobs per used pair; 2 high-use pairs. These are fixture calculations, not SQL query results. |
| Customer documents | Parsed checked-in JSON and independently reconstructed documents from SQL fixtures plus the retained lifecycle quote. | 6 customers, 33 quotes, 20 assigned jobs; counts and paid/unpaid effective totals agree. Original embedded customer identities were replaced by fresh synthetic reference data. |
| Waste fixture | Compared baseline model/SQL and checked identifiers, waste coverage, supply authority/dates and collection semantics in the literal fixture. | Historical supply price 55 retained; expected successful charge 11.16; overweight attempt has no collected weight. These are static calculations. |
| Script and documentation paths | Portable checker resolves local Markdown/image links and all `@@` SQL includes. | All checked targets resolve. GitHub's actual rendered pages are pending publication. |
| JavaScript | `node --check` on both mongosh files. | Syntax passes. This does not execute or simulate MongoDB. |
| JSON conversion | Exercised NDJSON-to-array conversion and rejection of malformed input. | Valid customer objects round-trip; invalid input fails. It is not an Oracle export test. |
| SQL parser review | Parsed the plain DDL/DML/report/JSON statements with sqlglot's Oracle dialect. | Supplemental syntax review only. Oracle-specific PL/SQL and client commands require Oracle; the parser treats one column-drop form as an unsupported command. |
| Public-content review | Reviewed text, staged paths and source diffs; scanned binary PDFs after decompression, metadata and attachments, model metadata and hidden files. | Private IDs, institutional access details and restricted documents are excluded. Generic credential-pattern scans are not a guarantee against all possible secrets. |
| Diagram cleanup | Redacted the two baseline PDFs, removed attachments/XML metadata, rewrote document properties, rendered PNG previews and visually inspected the cleaned diagrams. | Relationships, keys and technical legends retained. New current-relationship sources receive static review; native Mermaid rendering on GitHub is pending. |

## Not executed

- Oracle schema creation, data loading, negative constraint tests, sequence/DML execution, trigger compilation and additive migrations.
- Oracle reporting output, SQL/JSON execution and SQL*Plus/SQLcl spool behaviour.
- MongoDB insertion, filter/projection results, atomic update behaviour and runtime assertions.
- Native Oracle Data Modeler reopening of the renamed/sanitized project.
- GitHub upload, public visibility and rendered README/image checks until publication is authorized and performed.

Oracle clients, mongosh and a MongoDB server were unavailable. Docker was installed but its daemon was not running. No alternative relational engine was used to claim Oracle compatibility.

## Re-run checks

```sh
python3 tools/check_portfolio.py
node --check case-studies/transport-logistics/mongodb/customer-demo.mongodb.js
node --check case-studies/transport-logistics/mongodb/assertions.mongodb.js
```

The [setup guide](SETUP.md) gives the exact Oracle and MongoDB paths. Each Oracle setup runner invokes a fail-fast assertion script after preparing its fixture. Transport also verifies the lifecycle's intermediate quote/job states before cancellation. The [MongoDB assertions](../case-studies/transport-logistics/mongodb/assertions.mongodb.js) run after its demonstration.

The [historical waste transcript](../case-studies/waste-collection/verification/historical-schema-output.txt) reports the original baseline schema run and contains no `ORA-` diagnostics. It is supplied historical evidence, not a run of the corrected portfolio schema. The generator's summary is not treated as proof of business-rule correctness.
