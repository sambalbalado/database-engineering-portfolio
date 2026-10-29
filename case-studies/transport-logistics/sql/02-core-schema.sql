-- Core tables from the author's implementation; integrity corrections are separate.

-- EMPLOYEE
create table employee (
    emp_no         number(3) not null,
    emp_gname      varchar2(30) not null,
    emp_fname      varchar2(30) not null,
    emp_contact_no char(10) not null,
    emp_licenceno  varchar2(11),
    emp_role       char(1) not null,
    emp_no_manager number(3)
);

comment on column employee.emp_no is
    'Employee number';

comment on column employee.emp_gname is
    'Employee given name';

comment on column employee.emp_fname is
    'Employee family name';

comment on column employee.emp_contact_no is
    'Employee contact number';

comment on column employee.emp_licenceno is
    'Employee licence number (only for drivers)';

comment on column employee.emp_role is
    'Employee role - Manager (B), Truck Dispatcher (T), Mechanic (M), or Driver (D)';

comment on column employee.emp_no_manager is
    'Employee number of the manager';

-- ASSUMPTION (EMPLOYEE):
-- Driver Licence Requirement: It is assumed that all employees assigned the Driver role must possess a valid driver's licence number.

-- JOB
create table job (
    job_no                  number(5) not null,
    job_pickup_dt           date not null,
    job_intended_dropoff_dt date not null,
    job_cost                number(6,2),
    job_payment_made        char(1) not null,
    quote_no                number(5) not null,
    sched_emp_no            number(3) not null,
    driver_emp_no           number(3) not null,
    trailer_code            char(5) not null,
    truck_vin               char(17) not null
);

comment on column job.job_no is
    'Job number';

comment on column job.job_pickup_dt is
    'Job scheduled pick up date and time';

comment on column job.job_intended_dropoff_dt is
    'Job intended drop-off date and time';

comment on column job.job_cost is
    'The actual job cost (if different from the quote cost)';

comment on column job.job_payment_made is
    'Flag to note whether the job has been paid (Y or N)';

comment on column job.quote_no is
    'Quote number for this job';

comment on column job.sched_emp_no is
    'Employee number who scheduled the job';

comment on column job.driver_emp_no is
    'Employee number who drives the truck for the job';

comment on column job.trailer_code is
    'Trailer code allocated to the job';

comment on column job.truck_vin is
    'Truck VIN allocated to the job';

-- QUOTE
create table quote (
    quote_no              number(5) not null,
    quote_prepared_date   date not null,
    quote_pref_start_date date not null,
    quote_start_location  varchar2(50) not null,
    quote_end_location    varchar2(60) not null,
    quote_cost            number(6,2) not null,
    cust_no               number(4) not null,
    emp_no                number(3) not null
);

comment on column quote.quote_no is
    'Quote number';

comment on column quote.quote_prepared_date is
    'The date the quote was prepared';

comment on column quote.quote_pref_start_date is
    'The preferred start date for the quote';

comment on column quote.quote_start_location is
    'The start location for the quote';

comment on column quote.quote_end_location is
    'The end location (destination) for the quote';

comment on column quote.quote_cost is
    'The quoted cost';

comment on column quote.cust_no is
    'Customer number';

comment on column quote.emp_no is
    'Employee number which prepared the quote';

-- ASSUMPTIONS (QUOTE):
-- Chronological Order of Quote Creation: It is assumed that quote_pref_start_date must be on or after quote_prepared_date.
-- Quote Cost Valuation Rule: It is assumed that quote_cost must be greater than zero for all quotes.

-- Employee Constraints
alter table employee add constraint employee_pk primary key ( emp_no );
alter table employee add constraint employee_contact_uq unique ( emp_contact_no );
alter table employee add constraint employee_licence_uq unique ( emp_licenceno );
alter table employee
    add constraint employee_driver_licence_chk
        check ( ( emp_role = 'D'
           and emp_licenceno is not null )
            or ( emp_role in ( 'B',
                               'T',
                               'M' )
           and emp_licenceno is null ) );
alter table employee
    add constraint employee_role_chk
        check ( emp_role in ( 'B',
                              'T',
                              'M',
                              'D' ) );

-- Job Constraints
alter table job add constraint job_pk primary key ( job_no );
alter table job
    add constraint job_payment_chk check ( job_payment_made in ( 'Y',
                                                                 'N' ) );
alter table job add constraint job_date_chk check ( job_intended_dropoff_dt > job_pickup_dt
);

-- ASSUMPTION (JOB):
-- Chronological Date Integrity: It is assumed that a job's intended drop-off date must be later than its pickup date.

-- Quote Constraints
alter table quote add constraint quote_pk primary key ( quote_no );

-- Referential integrity

-- FK employee
alter table employee
    add constraint employee_manager_fk foreign key ( emp_no_manager )
        references employee ( emp_no );

-- FK job
alter table job
    add constraint quote_job_fk foreign key ( quote_no )
        references quote ( quote_no );

alter table job
    add constraint employee_sched_job_fk foreign key ( sched_emp_no )
        references employee ( emp_no );

alter table job
    add constraint employee_driver_job_fk foreign key ( driver_emp_no )
        references employee ( emp_no );

alter table job
    add constraint trailer_job_fk foreign key ( trailer_code )
        references trailer ( trailer_code );

alter table job
    add constraint truck_job_fk foreign key ( truck_vin )
        references truck ( truck_vin );

-- FK quote

alter table quote
    add constraint customer_quote_fk foreign key ( cust_no )
        references customer ( cust_no );

alter table quote
    add constraint employee_quote_fk foreign key ( emp_no )
        references employee ( emp_no );
