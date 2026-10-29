@@../sql/00-guard.sql
SET SERVEROUTPUT ON
DECLARE
 n NUMBER;
 PROCEDURE equal_count(actual NUMBER, expected NUMBER, message VARCHAR2) IS
 BEGIN IF actual <> expected THEN RAISE_APPLICATION_ERROR(-20200, message); END IF; END;
 PROCEDURE expect_rejected(stmt VARCHAR2, expected NUMBER) IS
 BEGIN
  SAVEPOINT negative_case;
  BEGIN
   EXECUTE IMMEDIATE stmt;
   ROLLBACK TO negative_case;
   RAISE_APPLICATION_ERROR(-20201, 'Invalid data was accepted: ' || stmt);
  EXCEPTION WHEN OTHERS THEN
   IF SQLCODE <> expected THEN RAISE; END IF;
   ROLLBACK TO negative_case;
  END;
 END;
BEGIN
 SELECT COUNT(*) INTO n FROM employee; equal_count(n,11,'Expected original staff plus new dispatcher');
 SELECT COUNT(*) INTO n FROM quote; equal_count(n,33,'Quotes must survive cancellation and migration');
 SELECT COUNT(*) INTO n FROM job; equal_count(n,20,'Only the demo lifecycle job should be cancelled');
 SELECT COUNT(*) INTO n FROM job WHERE job_cost IS NULL; equal_count(n,15,'Unchanged costs use quote fallback');
 SELECT COUNT(*) INTO n FROM job j JOIN quote q ON q.quote_no=j.quote_no WHERE j.job_cost<>q.quote_cost; equal_count(n,5,'Expected five revised costs');
 SELECT COUNT(*) INTO n FROM quote WHERE quote_no=300 AND quote_cost=1000 AND quote_status='N'; equal_count(n,1,'Cancelled quote must be intact');
 SELECT COUNT(*) INTO n FROM quote q WHERE q.quote_status <> CASE WHEN EXISTS
  (SELECT 1 FROM job j WHERE j.quote_no=q.quote_no) THEN 'Y' ELSE 'N' END;
 equal_count(n,0,'Stored quote status is inconsistent');
 SELECT COUNT(*) INTO n FROM combination c WHERE NOT EXISTS
  (SELECT 1 FROM job j WHERE j.truck_vin=c.truck_vin AND j.trailer_code=c.trailer_code);
 equal_count(n,3,'Expected three unused approved vehicle pairs');
 SELECT COUNT(*) INTO n FROM service_log; equal_count(n,2,'Expected two maintenance tasks');
 -- Cross-table roles are audited rather than enforced by foreign keys.
 SELECT COUNT(*) INTO n FROM employee e JOIN employee m ON m.emp_no=e.emp_no_manager WHERE m.emp_role<>'B';
 equal_count(n,0,'Non-manager used as manager');
 SELECT COUNT(*) INTO n FROM quote q JOIN employee e ON e.emp_no=q.emp_no WHERE e.emp_role<>'T'; equal_count(n,0,'Quote author must be a dispatcher');
 SELECT COUNT(*) INTO n FROM job j JOIN employee d ON d.emp_no=j.driver_emp_no JOIN employee s ON s.emp_no=j.sched_emp_no
 WHERE d.emp_role<>'D' OR s.emp_role<>'T'; equal_count(n,0,'Invalid job personnel roles');
 SELECT COUNT(*) INTO n FROM service_log l JOIN employee e ON e.emp_no=l.emp_no WHERE e.emp_role<>'M'; equal_count(n,0,'Service task must use mechanic');
 SELECT COUNT(*) INTO n FROM user_objects WHERE status='INVALID'; equal_count(n,0,'Invalid compiled object');
 expect_rejected(q'[UPDATE quote SET quote_cost=-1 WHERE quote_no=1]', -2290);
 expect_rejected(q'[UPDATE quote SET quote_pref_start_date=DATE '2020-01-01' WHERE quote_no=1]', -2290);
 expect_rejected(q'[UPDATE job SET truck_vin='1HGBH41JXMN109186', trailer_code='TRL02' WHERE job_no=1]', -2291);
 expect_rejected(q'[UPDATE job SET quote_no=1 WHERE job_no=2]', -1);
 expect_rejected(q'[UPDATE employee SET emp_licenceno=NULL WHERE emp_no=30]', -2290);
 expect_rejected(q'[UPDATE service SET service_kms=-1 WHERE service_id=1]', -2290);
 -- Exercise synchronization after the migration without changing the final fixture.
 SAVEPOINT status_case;
 DELETE FROM job WHERE job_no=1;
 SELECT COUNT(*) INTO n FROM quote WHERE quote_no=1 AND quote_status='N'; equal_count(n,1,'Cancellation status trigger failed');
 ROLLBACK TO status_case;
 UPDATE job SET quote_no=21 WHERE job_no=1;
 SELECT COUNT(*) INTO n FROM quote WHERE (quote_no=1 AND quote_status='N') OR (quote_no=21 AND quote_status='Y');
 equal_count(n,2,'Reassignment status trigger failed');
 ROLLBACK TO status_case;
 DBMS_OUTPUT.PUT_LINE('Transport runtime assertions passed');
END;
/
