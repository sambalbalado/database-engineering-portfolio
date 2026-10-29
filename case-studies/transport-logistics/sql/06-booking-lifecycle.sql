-- Portfolio addition: capture the new quote in a SQL*Plus/SQLcl bind variable.
VARIABLE booking_quote_no NUMBER

-- Create sequences for employee, quote and job tables
create sequence employee_seq start with 300 increment by 5;

create sequence quote_seq start with 300 increment by 5;

create sequence job_seq start with 300 increment by 5;

commit;

-- Add a new employee 'Aurello Brown' to the database,
-- setting his role and manager based on the existing employee directory.
insert into employee (
    emp_no,
    emp_gname,
    emp_fname,
    emp_contact_no,
    emp_licenceno,
    emp_role,
    emp_no_manager
) values ( employee_seq.nextval,
           'Aurello',
           'Brown',
           '0001952053',
           null, -- This is null as Truck Dispatcher does not require license
           'T',
           (
               select emp_no
                 from employee
                where upper(emp_gname) = upper('Sarah')
                  and upper(emp_fname) = upper('Mitchell')
                  and emp_role = 'B'
           ) );

commit;

-- Step 1 : Create a new quote record for the Flintstone Store.
insert into quote (
    quote_no,
    quote_prepared_date,
    quote_pref_start_date,
    quote_start_location,
    quote_end_location,
    quote_cost,
    cust_no,
    emp_no
) values ( quote_seq.nextval,
           to_date('17 May 2026','DD Mon YYYY','NLS_DATE_LANGUAGE=English'),
           to_date('25 May 2026','DD Mon YYYY','NLS_DATE_LANGUAGE=English'),
           '29 Kuranda Road, Adelaide SA 5030',
           '9 Albatros Drive, Mount Gambier SA 5270',
           1000.00,
           (
               select cust_no
                 from customer
                where upper(cust_gname) = upper('VICTORIA')
                  and upper(cust_fname) = upper('ELLA')
                  and upper(cust_bname) = upper('Flintstone Store')
           ),
           (
               select emp_no
                 from employee
                where upper(emp_gname) = upper('Aurello')
                  and upper(emp_fname) = upper('Brown')
                  and emp_role = 'T'
           ) );

-- Capture CURRVAL in a permitted SELECT list, then use a stable bind in predicates.
BEGIN
 SELECT quote_seq.currval INTO :booking_quote_no FROM dual;
END;
/

-- Step 2: Convert the quote into a job record.

-- Assumption: Since Victoria agreed to the quoted cost with no renegotiation, the job
-- effective cost equals the quote cost, so no revision is stored.
insert into job (
    job_no,
    job_pickup_dt,
    job_intended_dropoff_dt,
    job_cost,
    job_payment_made,
    quote_no,
    sched_emp_no,
    driver_emp_no,
    trailer_code,
    truck_vin
) values ( job_seq.nextval,
           to_date('25 May 2026 09:00','DD Mon YYYY HH24:MI','NLS_DATE_LANGUAGE=English'),
           to_date('25 May 2026 14:00','DD Mon YYYY HH24:MI','NLS_DATE_LANGUAGE=English'),
           null, -- unchanged cost: NVL(job_cost, quote_cost) supplies the effective charge
           'Y',
           :booking_quote_no,

           (
               select emp_no
                 from employee
                where upper(emp_gname) = upper('Aurello')
                  and upper(emp_fname) = upper('Brown')
                  and emp_role = 'T'
           ),
           (
               select emp_no
                 from employee
                where upper(emp_gname) = upper('Michael')
                  and upper(emp_fname) = upper('Johnson')
                  and emp_role = 'D'
           ),
           'TRL08',
           '1HGBH41JXMN109186' );

commit;

-- Portfolio verification addition: check the newly scheduled job before changing it.
DECLARE n NUMBER;
BEGIN
 SELECT COUNT(*) INTO n FROM job j JOIN quote q ON q.quote_no = j.quote_no
 WHERE j.quote_no = :booking_quote_no AND j.job_cost IS NULL
 AND q.quote_cost = 1000 AND j.job_intended_dropoff_dt - j.job_pickup_dt = 5/24;
 IF n <> 1 THEN RAISE_APPLICATION_ERROR(-20010, 'Booking creation assertion failed'); END IF;
END;
/

-- Reschedule the job for the Flintstone Store by updating pickup and dropoff times.
-- Apply a 20% cost increase to the associated job record.
-- Travel Duration Consistency: It is assumed that any change to the pickup time requires the drop-off time to be adjusted accordingly to maintain the 5-hour travel duration.

update job
   set job_pickup_dt = to_date('25 May 2026 14:00','DD Mon YYYY HH24:MI','NLS_DATE_LANGUAGE=English'),
       job_intended_dropoff_dt = to_date('25 May 2026 19:00','DD Mon YYYY HH24:MI','NLS_DATE_LANGUAGE=English'),
       job_cost = (
           select q.quote_cost * 1.20
             from quote q
            where q.quote_no = job.quote_no
       )
 where quote_no = :booking_quote_no;

commit;

-- Portfolio verification addition: revised cost must not rewrite the accepted quote.
DECLARE n NUMBER;
BEGIN
 SELECT COUNT(*) INTO n FROM job j JOIN quote q ON q.quote_no = j.quote_no
 WHERE j.quote_no = :booking_quote_no AND j.job_cost = 1200 AND q.quote_cost = 1000
 AND j.job_intended_dropoff_dt - j.job_pickup_dt = 5/24;
 IF n <> 1 THEN RAISE_APPLICATION_ERROR(-20011, 'Reschedule assertion failed'); END IF;
END;
/

-- Remove the scheduled job from the database for the specified quote.
-- Job Deletion Scope: It is assumed that deleting a job removes only the corresponding JOB record while retaining the related QUOTE record.
delete from job
 where quote_no = :booking_quote_no;

commit;

-- Portfolio verification addition: cancellation retains the original quote.
DECLARE n NUMBER;
BEGIN
 SELECT COUNT(*) INTO n FROM quote q WHERE q.quote_no = :booking_quote_no
 AND q.quote_cost = 1000 AND NOT EXISTS (SELECT 1 FROM job j WHERE j.quote_no = q.quote_no);
 IF n <> 1 THEN RAISE_APPLICATION_ERROR(-20012, 'Cancellation assertion failed'); END IF;
END;
/
