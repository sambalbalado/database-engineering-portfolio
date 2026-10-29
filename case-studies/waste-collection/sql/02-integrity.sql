-- Portfolio addition: focused corrections to the preserved design baseline.
-- Permit streets longer than the baseline limit of 999.99 metres.
ALTER TABLE street MODIFY (length_metres NUMBER(8,2));
-- Derive a bin's type through its supply agreement; remove transitive duplication.
ALTER TABLE bin DROP CONSTRAINT bintype_bin_fk;
ALTER TABLE bin DROP (waste_type_id, bin_size);
ALTER TABLE contract_bin_supply ADD CONSTRAINT cbs_covered_waste_fk
 FOREIGN KEY (waste_type_id, contract_no)
 REFERENCES contract_waste_collection (waste_type_id, contract_no);
ALTER TABLE contract ADD CONSTRAINT contract_dates_ck CHECK (end_date >= start_date);
ALTER TABLE bin ADD CONSTRAINT bin_rfid_ck CHECK (REGEXP_LIKE(bin_rfid, '^[0-9A-F]{24}$', 'c'));
ALTER TABLE truck ADD CONSTRAINT waste_vin_ck
 CHECK (REGEXP_LIKE(collection_truck_vin, '^[A-HJ-NPR-Z0-9]{17}$', 'c'));
ALTER TABLE bin_collection ADD CONSTRAINT collection_weight_ck
 CHECK ((overweight = 'Y' AND collected_kgs IS NULL)
     OR (overweight = 'N' AND collected_kgs IS NOT NULL AND collected_kgs >= 0));
ALTER TABLE collection_run ADD CONSTRAINT collection_day_ck
 CHECK (date_of_collection = TRUNC(date_of_collection));
ALTER TABLE bin_type ADD CONSTRAINT bin_type_values_ck CHECK (bin_size > 0 AND bin_supply_cost >= 0);
ALTER TABLE contract_bin_supply ADD CONSTRAINT supply_cost_ck CHECK (contract_bin_supply_cost >= 0);
ALTER TABLE contract_waste_collection ADD CONSTRAINT collection_cost_ck CHECK (collection_cost_per_kg >= 0);
ALTER TABLE local_authority ADD CONSTRAINT authority_area_ck CHECK (total_area_sq_km > 0);
ALTER TABLE street ADD CONSTRAINT street_values_ck CHECK (length_metres > 0 AND lanes_no > 0);
COMMENT ON COLUMN bin_collection.collected_kgs IS 'Collected kilograms; NULL when an overweight bin was not collected';
COMMENT ON COLUMN collection_run.date_of_collection IS 'Collection calendar day, stored at midnight';
