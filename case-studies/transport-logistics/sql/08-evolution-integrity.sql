-- Portfolio addition: preserve natural service identity and nonnegative odometer readings.
ALTER TABLE service ADD CONSTRAINT service_event_uq UNIQUE (truck_vin, service_start_datetime);
ALTER TABLE service ADD CONSTRAINT service_kms_ck CHECK (service_kms >= 0);

-- Keep the materialized quote flag synchronized with changes to the single related job.
CREATE OR REPLACE TRIGGER job_quote_status_trg
AFTER INSERT OR DELETE OR UPDATE OF quote_no ON job
FOR EACH ROW
BEGIN
 IF DELETING OR UPDATING THEN
  UPDATE quote SET quote_status = 'N' WHERE quote_no = :OLD.quote_no;
 END IF;
 IF INSERTING OR UPDATING THEN
  UPDATE quote SET quote_status = 'Y', quote_reasoning = NULL WHERE quote_no = :NEW.quote_no;
 END IF;
END;
/
SHOW ERRORS
