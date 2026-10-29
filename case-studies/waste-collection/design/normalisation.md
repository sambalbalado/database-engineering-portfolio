# Collection Report Normalisation: UNF to 3NF

This is a clean transcription and review of the author's original report decomposition. Relation names and the sequence of decompositions are preserved. The report has a contract/waste header, repeating collection runs, and repeating bin observations within each run. The original report artwork is not redistributed.

## UNF

```text
CONTRACT_WASTE_COLLECTION(
  contract_no, waste_type_id, waste_type_desc, collection_frequency,
  { date_of_collection, collection_truck_vin, truck_rego,
    truck_make, truck_model, truck_year,
    { bin_rfid, collected_kgs, overweight } }
)
```

Braces identify repeating groups. `collected_kgs` can be absent when the bin is rejected as overweight.

## 1NF: separate repeating groups

| Relation | Attributes | Report-scoped key used in the original work |
| --- | --- | --- |
| `CONTRACT_WASTE_COLLECTION` | `contract_no, waste_type_id, waste_type_desc, collection_frequency` | `(contract_no, waste_type_id)` |
| `COLLECTION_RUN` | `contract_no, waste_type_id, date_of_collection, collection_truck_vin, truck_rego, truck_make, truck_model, truck_year` | `(contract_no, waste_type_id, date_of_collection)` |
| `BIN_COLLECTION` | `contract_no, waste_type_id, date_of_collection, bin_rfid, collected_kgs, overweight` | `(contract_no, waste_type_id, date_of_collection, bin_rfid)` |

The stated partial dependency is:

```text
waste_type_id -> waste_type_desc
```

The other two relations have no partial dependency under the original report-scoped dependency set. They still carry run/vehicle context and report-scope identity rather than the integrated bin catalogue.

## 2NF: remove the waste description dependency

```text
CONTRACT_WASTE_COLLECTION(contract_no, waste_type_id, collection_frequency)
COLLECTION_RUN(contract_no, waste_type_id, date_of_collection,
               collection_truck_vin, truck_rego, truck_make, truck_model, truck_year)
BIN_COLLECTION(contract_no, waste_type_id, date_of_collection,
               bin_rfid, collected_kgs, overweight)
WASTE_TYPE(waste_type_id, waste_type_desc)
```

The remaining transitive dependency in the run relation is:

```text
collection_truck_vin -> truck_rego, truck_make, truck_model, truck_year
```

`CONTRACT_WASTE_COLLECTION`, `BIN_COLLECTION` and `WASTE_TYPE` have no transitive dependency under that scoped set.

## 3NF: separate truck facts

```text
CONTRACT_WASTE_COLLECTION(contract_no, waste_type_id, collection_frequency)
COLLECTION_RUN(contract_no, waste_type_id, date_of_collection, collection_truck_vin)
BIN_COLLECTION(contract_no, waste_type_id, date_of_collection,
               bin_rfid, collected_kgs, overweight)
WASTE_TYPE(waste_type_id, waste_type_desc)
TRUCK(collection_truck_vin, truck_rego, truck_make, truck_model, truck_year)
```

Full dependencies recorded in the original work:

```text
contract_no, waste_type_id -> collection_frequency
contract_no, waste_type_id, date_of_collection -> collection_truck_vin
contract_no, waste_type_id, date_of_collection, bin_rfid -> collected_kgs, overweight
waste_type_id -> waste_type_desc
collection_truck_vin -> truck_rego, truck_make, truck_model, truck_year
```

The decomposition separates waste description and vehicle details on their identifiers. Joining those determinants back reconstructs the corresponding report facts without repeating them per observation. Registration is not unique over the fleet's history: a plate can move to another VIN. A model name does not determine a make, because manufacturers can reuse model names.

## Key minimality and scope review

The original document labelled all three 1NF keys as candidate keys. The four-part bin-observation key is an identifying **report-scoped superkey**; it should not be presented as proof of minimality once the wider domain is included. A bin has one property/type, and the business permits a property/waste collection only once per day. With those rules, `(bin_rfid, date_of_collection)` can identify an observation globally. The implementation retains the author's `(collection_run_id, bin_rfid)` primary key and separately audits the stronger property/waste/day rule through joins.

The original run key also assumes one truck/run per contract/waste/day. The supplied examples support that interpretation but do not establish a scalable multi-truck scheduling model. These assumptions are explicit in the portfolio rather than inferred from a few sample rows.

## Integration into the complete schema

The conceptual model contributes `collection_cost_per_kg`; the report contributes `collection_frequency`. Both depend on the contract/waste pair and belong in `CONTRACT_WASTE_COLLECTION`. The final schema adds stable surrogate IDs for run, property and supply agreement, while protecting their natural keys with unique constraints. Surrogates are an implementation step after report decomposition.

A further integration defect existed in the original logical model:

```text
bin_rfid -> contract_bin_supply_id -> waste_type_id, bin_size
```

The baseline `BIN` duplicated the type columns determined by its supply agreement. The [integrity overlay](../sql/02-integrity.sql) removes those duplicate columns. Supply agreements reference both a valid bin type and a covered contract/waste pair. See the [current model](current-model.md) and [assumptions/key inventory](assumptions.md) for the full 14-table design and the remaining cross-table enforcement limits.
