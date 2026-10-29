-- Supply charges remain tied to the original agreement, even after a new contract starts.
SELECT b.bin_rfid, c.contract_no AS supplied_under_contract,
       bt.bin_supply_cost AS catalogue_cost, s.contract_bin_supply_cost AS historical_supply_cost
FROM bin b JOIN contract_bin_supply s ON b.contract_bin_supply_id = s.contract_bin_supply_id
JOIN contract c ON c.contract_no = s.contract_no
JOIN bin_type bt ON bt.waste_type_id = s.waste_type_id AND bt.bin_size = s.bin_size
ORDER BY b.bin_rfid;

-- Overweight attempts are retained but produce no weight-based charge.
SELECT r.collection_run_id, b.property_id, r.waste_type_id, bc.overweight,
       bc.collected_kgs,
       CASE WHEN bc.overweight = 'N' THEN bc.collected_kgs * c.collection_cost_per_kg ELSE 0 END AS collection_charge
FROM collection_run r JOIN bin_collection bc ON bc.collection_run_id = r.collection_run_id
JOIN bin b ON b.bin_rfid = bc.bin_rfid
JOIN contract_waste_collection c ON c.contract_no = r.contract_no AND c.waste_type_id = r.waste_type_id
ORDER BY r.collection_run_id, b.bin_rfid;
