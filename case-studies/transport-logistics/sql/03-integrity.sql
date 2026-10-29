-- Portfolio correction: preserve one job per quote and use an approved vehicle pairing.
ALTER TABLE job ADD CONSTRAINT job_quote_uq UNIQUE (quote_no);
ALTER TABLE job DROP CONSTRAINT trailer_job_fk;
ALTER TABLE job DROP CONSTRAINT truck_job_fk;
ALTER TABLE job ADD CONSTRAINT job_combination_fk FOREIGN KEY (truck_vin, trailer_code)
 REFERENCES combination(truck_vin, trailer_code);
ALTER TABLE quote ADD CONSTRAINT quote_dates_ck CHECK (quote_pref_start_date >= quote_prepared_date);
ALTER TABLE quote ADD CONSTRAINT quote_cost_ck CHECK (quote_cost > 0);
ALTER TABLE job ADD CONSTRAINT job_cost_ck CHECK (job_cost > 0);
ALTER TABLE employee ADD CONSTRAINT employee_reporting_ck CHECK
 ((emp_role = 'B' AND emp_no_manager IS NULL)
 OR (emp_role <> 'B' AND emp_no_manager IS NOT NULL AND emp_no_manager <> emp_no));
