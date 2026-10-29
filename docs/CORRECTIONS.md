# Corrections and additions

These changes affect the portfolio copies. Cleaned baseline models remain available as evidence of the original design; they are explicitly labelled as baselines.

## Waste collection

- **Remove duplicated bin type.** `BIN` originally stored `waste_type_id` and `bin_size` as well as `contract_bin_supply_id`. The supply ID already determines both values. The overlay removes these columns and their direct type foreign key; queries derive type through the supply agreement. This removes a transitive dependency and prevents a bin from identifying two different types.
- **Constrain covered waste.** A composite foreign key from a bin supply agreement to `CONTRACT_WASTE_COLLECTION` prevents supplying a type absent from that contract.
- **Validate identifiers and measurements.** Added uppercase 24-character hexadecimal RFID validation, 17-character VIN validation, nonnegative prices and weights, positive bin sizes/area/street dimensions, and contract date ordering. Street length precision is widened from `NUMBER(5,2)` to `NUMBER(8,2)`, removing the original 999.99 metre cap. Collection dates are calendar days. An overweight attempt has no collected weight; a successful collection requires a nonnegative weight.
- **Keep historical pricing.** A bin continues to reference the original supply agreement, even when collection occurs under a later contract. Registration plates remain nonunique because they can move to a replacement truck; VIN remains the truck key.
- **Disclose cross-table limits.** Assignment authority/date checks, one collection per property/waste/day, and minimum participation are audited by queries rather than fully enforced for arbitrary concurrent writes. The current notes do not claim those rules are guaranteed by the schema.

## Transport logistics

- **Complete the setup.** Added original portfolio support DDL for four reference tables and fresh customer/fleet/combination fixtures. The missing supplied starter is neither copied nor represented as the author's design.
- **Repair integrity gaps.** Added one job per quote, a composite foreign key to approved truck/trailer combinations, positive quote/revised-job costs, quote date ordering, and local reporting-line checks. A foreign key to an employee alone does not enforce that employee's role; role audits are explicit.
- **Preserve quoted prices.** Unchanged job prices now use `NULL` in `job_cost`, with `NVL(job_cost, quote_cost)` supplying the effective charge. Five revised costs remain explicit. The rescheduling example increases only the job cost from 1,000 to 1,200 and keeps the quote at 1,000.
- **Repair an overlapping fixture.** Job 7 previously occupied the same truck and trailer as job 8 during an overlapping interval. Its end date is moved from 19 May to 18 May 2026. Date-only fixtures are interpreted as half-open intervals; no journey-duration or driver-hours compliance claim is made.
- **Stabilize the lifecycle.** A session bind captures `quote_seq.currval` in a permitted SELECT list and links the newly created quote to its job and later changes. Dynamic manager/dispatcher/driver lookups remain. Added assertions at creation, revision and cancellation. Sequences are initialized once during fresh setup; they are not dropped in the lifecycle.
- **Maintain quote status.** Retained the additive status-column migration and its existing-data backfill. Added a job-change trigger to keep status synchronized after inserts, deletions and quote reassignment. Direct manual edits to the status field remain possible and are caught by the audit.
- **Strengthen maintenance records.** Added uniqueness of truck/start time, nonnegative odometer readings and a synthetic two-task service demonstration. The original `(service_id, task_code)` key still permits one assigned mechanic per task per service.
- **Fix report output.** A dispatcher with zero jobs now displays `0`. Other employee roles remain blank in that column. Vehicle reports retain unused approved combinations and deliberately total original quoted prices. Classification uses the average across combinations used at least once.
- **Produce clean JSON.** Removed trailing commas, added CLOB return types and client export settings, and made date/number locale explicit through the guarded setup/export path. One-job-per-quote prevents joined rows from duplicating quote counts. Customers with no quotes are outside this exporter; the MongoDB creation example still demonstrates an empty quote array.
- **Reconcile document fixtures.** Rebuilt the checked-in example from the curated synthetic reference data and the retained quotes/jobs. It is labelled as an independently constructed example, not newly executed Oracle output. MongoDB keeps the original filter/projection and `$set`/`$push` approach, adds a dedicated-database/reset guard and guards against duplicate insertion of the example quote.

## Presentation and verification

Descriptive filenames, two independent setup paths, explicit resets, cleaned editable sources, redacted baseline PDFs and previews, rewritten assumptions/normalisation, current-model diagrams, provenance, static checks and executable runtime assertions were added. Historical SQL output is labelled and scrubbed. Text whitespace is normalized for consistent review. No benchmark or new database execution result was invented.
