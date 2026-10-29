@@../sql/00-guard.sql
SET SERVEROUTPUT ON
DECLARE
 n NUMBER;
 PROCEDURE expect_rejected(stmt VARCHAR2, expected NUMBER) IS
 BEGIN
  SAVEPOINT negative_case;
  BEGIN
   EXECUTE IMMEDIATE stmt;
   ROLLBACK TO negative_case;
   RAISE_APPLICATION_ERROR(-20100, 'Invalid data was accepted: ' || stmt);
  EXCEPTION WHEN OTHERS THEN
   IF SQLCODE <> expected THEN RAISE; END IF;
   ROLLBACK TO negative_case;
  END;
 END;
BEGIN
 SELECT COUNT(*) INTO n FROM user_tables;
 IF n <> 14 THEN RAISE_APPLICATION_ERROR(-20101, 'Expected fourteen demo tables'); END IF;
 SELECT COUNT(*) INTO n FROM bin b JOIN contract_bin_supply s ON s.contract_bin_supply_id = b.contract_bin_supply_id
 WHERE b.bin_rfid = 'AAAABBBBCCCCDDDDEEEE0001' AND s.contract_no = 101 AND s.contract_bin_supply_cost = 55;
 IF n <> 1 THEN RAISE_APPLICATION_ERROR(-20102, 'Historical supply price lost'); END IF;
 SELECT COUNT(*) INTO n FROM bin_collection WHERE overweight = 'Y' AND collected_kgs IS NULL;
 IF n <> 1 THEN RAISE_APPLICATION_ERROR(-20103, 'Expected an uncollected overweight attempt'); END IF;
 expect_rejected(q'[INSERT INTO contract_bin_supply VALUES (99, 101, 'LF', 240, 50)]', -2291);
 expect_rejected(q'[INSERT INTO bin VALUES ('NOT-A-VALID-RFID', DATE '2026-02-01', NULL, 1, 1)]', -2290);
 expect_rejected(q'[UPDATE contract SET end_date = DATE '2020-01-01' WHERE contract_no = 101]', -2290);
 expect_rejected(q'[INSERT INTO property VALUES (99, 1, 'Demo Shire', 10)]', -1);
 expect_rejected(q'[INSERT INTO collection_run VALUES (99, DATE '2026-03-05', 'GW', 102, '1HSJRSCR9EJ419702')]', -1);
 expect_rejected(q'[UPDATE bin_collection SET collected_kgs = 20 WHERE overweight = 'Y']', -2290);
 -- Cross-table business rules audited here, not enforced for arbitrary writes.
 SELECT COUNT(*) INTO n FROM bin b JOIN contract_bin_supply s ON s.contract_bin_supply_id=b.contract_bin_supply_id
 JOIN contract c ON c.contract_no=s.contract_no JOIN property p ON p.property_id=b.property_id
 WHERE c.authority_name <> p.authority_name OR b.supply_date < c.start_date OR b.supply_date >= TRUNC(c.end_date)+1;
 IF n <> 0 THEN RAISE_APPLICATION_ERROR(-20104, 'Invalid bin assignment'); END IF;
 SELECT COUNT(*) INTO n FROM bin_collection bc JOIN collection_run r ON r.collection_run_id=bc.collection_run_id
 JOIN bin b ON b.bin_rfid=bc.bin_rfid JOIN contract_bin_supply s ON s.contract_bin_supply_id=b.contract_bin_supply_id
 JOIN property p ON p.property_id=b.property_id JOIN contract c ON c.contract_no=r.contract_no
 WHERE s.waste_type_id <> r.waste_type_id OR p.authority_name <> c.authority_name
 OR r.date_of_collection < c.start_date OR r.date_of_collection >= TRUNC(c.end_date)+1 OR r.date_of_collection < TRUNC(b.supply_date);
 IF n <> 0 THEN RAISE_APPLICATION_ERROR(-20105, 'Invalid collection assignment'); END IF;
 SELECT COUNT(*) INTO n FROM (
  SELECT b.property_id, r.waste_type_id, TRUNC(r.date_of_collection)
  FROM bin_collection bc JOIN bin b ON bc.bin_rfid=b.bin_rfid JOIN collection_run r ON r.collection_run_id=bc.collection_run_id
  GROUP BY b.property_id, r.waste_type_id, TRUNC(r.date_of_collection) HAVING COUNT(*) > 1);
 IF n <> 0 THEN RAISE_APPLICATION_ERROR(-20106, 'Duplicate daily property/waste collection'); END IF;
 SELECT COUNT(*) INTO n FROM user_objects WHERE status='INVALID';
 IF n <> 0 THEN RAISE_APPLICATION_ERROR(-20107, 'Invalid schema objects'); END IF;
 DBMS_OUTPUT.PUT_LINE('Waste runtime assertions passed');
END;
/
