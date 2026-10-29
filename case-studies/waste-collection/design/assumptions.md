# Assumptions, participation and keys

Rewritten from the author's original assumptions and checked against the supplied business description. Performance claims were removed because no benchmarks were provided.

## Participation

| Relationship | Intended meaning | Enforcement |
| --- | --- | --- |
| Authority → contract | Authority may be recorded before a contract exists; each contract has one authority. | Child foreign key; no minimum child count. |
| Authority → street → property | A street may have no properties yet. Street IDs are unique within an authority. | Composite street key and property foreign key. |
| Property ↔ owner | Several owners may share a property. An owner can be entered before acquiring a property. | Associative key prevents duplicate links. |
| Property → bin | A newly added property can have no bins. A bin is recorded only when assigned to one property. | Non-null property foreign key on bin. |
| Contract → supply agreement | Supply terms may be completed after contract creation; no supply rows are required immediately. | Child foreign keys. |
| Waste/bin catalogue → agreements | Catalogue records can exist before an agreement references them. | Child foreign keys; no minimum usage count. |
| Contract → covered waste | An operational contract covers at least one waste type. | Baseline diagram expresses this, but a foreign key alone cannot require a child row; activation must audit participation. |
| Run → collection attempts | A run can be scheduled before collection attempts exist. Each attempt references one run and one bin. | Non-null foreign keys and composite primary key. |

The conceptual diagram requires at least one owner link for a property, whereas the logical baseline permits zero links. This is an original modelling inconsistency. For portfolio onboarding, a zero-owner draft property is permitted; operational properties must have ownership recorded before service. No draft/active state is stored, so that distinction remains an application/process rule, not an enforced database state. The synthetic properties have owners.

## Stable identifiers and natural-key protection

| Relation | Primary key | Additional protected key |
| --- | --- | --- |
| `LOCAL_AUTHORITY` | `authority_name` | — |
| `STREET` | `(street_id, authority_name)` | — |
| `PROPERTY` | `property_id` | `(street_id, authority_name, street_no)` |
| `OWNER` | `owner_id` | No email/name uniqueness is assumed. |
| `PROPERTY_OWNER` | `(property_id, owner_id)` | — |
| `WASTE_TYPE` | `waste_type_id` | Description is not assumed unique. |
| `BIN_TYPE` | `(waste_type_id, bin_size)` | — |
| `CONTRACT` | `contract_no` | — |
| `CONTRACT_WASTE_COLLECTION` | `(waste_type_id, contract_no)` | — |
| `CONTRACT_BIN_SUPPLY` | `contract_bin_supply_id` | `(contract_no, waste_type_id, bin_size)` |
| `BIN` | `bin_rfid` | Uppercase 24-character hexadecimal identifier. |
| `TRUCK` | `collection_truck_vin` | Registration is not a candidate key across replacement vehicles. |
| `COLLECTION_RUN` | `collection_run_id` | `(contract_no, waste_type_id, date_of_collection)` |
| `BIN_COLLECTION` | `(collection_run_id, bin_rfid)` | Stronger global daily rules require cross-table auditing. |

The original surrogate choices for property, supply agreement and collection run keep child foreign keys compact. Each natural business key remains unique. This is a structural tradeoff, with no claimed measured speedup. The schema does not generate these IDs automatically; the new fixture assigns explicit values.

## Time and cost rules

A collection run represents one contract/waste/day and uses one truck. That preserves the original model's chosen granularity; parallel runs for the same contract/waste/day would require a new run identity rule. Oracle `DATE` includes a time component, so the overlay requires collection dates to equal `TRUNC(date_of_collection)`.

Supply date and collection date are different facts. A supplied bin retains the price and type from its historical agreement, while a collection references the currently applicable contract rate. Contract supply prices are treated as immutable historical terms; the schema does not prevent manual price edits. A future operational implementation would version or protect price changes.

An overweight bin is not emptied: `overweight='Y'` implies no collected weight. A normal attempt requires a nonnegative collected weight. The model has no configured weight threshold, so it cannot derive the overweight flag itself.

Cross-table audit queries check authority alignment, agreement/supply dates, run dates and waste types. They also detect multiple attempts for a property/waste/day. Those checks are not concurrent-write enforcement or a replacement for a transactional service layer.
