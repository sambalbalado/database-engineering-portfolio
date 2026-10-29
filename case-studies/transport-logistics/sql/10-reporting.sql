-- (;) at the end of this answer

-- Identify customers who have more than one quote and whose average quoted
-- cost is greater than the overall average cost of all quotes in the system.
-- Used to target high-value, frequent customers.
select c.cust_no,
       nvl(
           c.cust_bname,
           c.cust_gname
           || ' '
           || c.cust_fname
       ) as "CUSTOMER_NAME",
       count(q.quote_no) as "NUM_QUOTES",
       to_char(
           avg(q.quote_cost),
           '$999,999.00'
       ) as "AVG_QUOTED_COST"
  from customer c
  join quote q
on c.cust_no = q.cust_no
 group by c.cust_no,
          c.cust_bname,
          c.cust_gname,
          c.cust_fname
having count(q.quote_no) > 1
   and avg(q.quote_cost) > (
    select avg(quote_cost)
      from quote
)
 order by avg(q.quote_cost) desc,
          c.cust_no asc;

-- (;) at the end of this answer

-- Retrieve a full list of all employees, their roles in plain English,
-- and the name of their manager. Includes a count of jobs dispatched
-- for employees assigned the 'Truck Dispatcher' role.
select e.emp_no,
       e.emp_gname
       || ' '
       || e.emp_fname as emp_name,
       case e.emp_role
           when 'T' then
               'Truck Dispatcher'
           when 'B' then
               'Manager'
           when 'M' then
               'Mechanic'
           when 'D' then
               'Driver'
           else
               'Unknown'
       end as emp_role_full,
       case
           when e.emp_no_manager is null then
               'No Manager'
           else
               m.emp_gname
               || ' '
               || m.emp_fname
       end as manager_name,
       case when e.emp_role = 'T' then to_char(count(j.job_no))
            else null end as jobs_dispatched
  from employee e
  left outer join employee m
on e.emp_no_manager = m.emp_no
  left outer join job j
on e.emp_no = j.sched_emp_no
 group by e.emp_no,
          e.emp_gname,
          e.emp_fname,
          e.emp_role,
          e.emp_no_manager,
          m.emp_gname,
          m.emp_fname
 order by e.emp_no;

-- (;) at the end of this answer

-- Generate a report on truck and trailer usage.
-- Includes formatting for currency and alignment,
-- and classifies usage frequency based on the average number of jobs
-- compared to the global average across all truck/trailer combinations.
select t.truck_vin,
       rpad(
           t.truck_rego,
           12,
           ' '
       ) as truck_rego,
       rpad(
           tr.trailer_code,
           14,
           ' '
       ) as trailer_code,
       lpad(
           to_char(
               tr.trailer_purchase_cost,
               '$999,990.00'
           ),
           21,
           ' '
       ) as trailer_purchase_cost,
       count(j.job_no) as num_jobs,
       lpad(
           nvl(
               to_char(
                   sum(q.quote_cost),
                   '$999,990.00'
               ),
               'No jobs'
           ),
           17,
           ' '
       ) as total_quoted_cost,
       case
           when count(j.job_no) = 0 then
               'Never Used'
           when count(j.job_no) > (
               select avg(count(job_no))
                 from job
                group by truck_vin,
                         trailer_code
           )                   then
               'High Use'
           else
               'Standard Use'
       end as usage
  from truck t
  join combination c
on t.truck_vin = c.truck_vin
  join trailer tr
on c.trailer_code = tr.trailer_code
  left outer join job j
on t.truck_vin = j.truck_vin
   and c.trailer_code = j.trailer_code
  left outer join quote q
on j.quote_no = q.quote_no
 group by t.truck_vin,
          t.truck_rego,
          tr.trailer_code,
          tr.trailer_purchase_cost
 order by count(j.job_no) desc,
          t.truck_vin,
          tr.trailer_code;
