-- Add status tracking columns to the QUOTE table to monitor
-- assignment progress and record reasons for non-conversion.
alter table quote add (
    quote_status    char(1) default 'N' not null, -- Every quote must have status
    quote_reasoning varchar2(200) -- Assumption: quote_reasoning may be NULL to allow blank reasons and support existing records during schema modification
);

alter table quote
    add constraint chk_quote_status check ( quote_status in ( 'Y',
                                                              'N' ) );

-- Synchronize existing records that converted into a job
update quote
   set
    quote_status = 'Y'
 where quote_no in (
    select quote_no
      from job
);

-- Synchronize existing records that have not been converted into a job
-- Assumption: any quote without a matching job record is classified as unassigned ('N')
update quote
   set
    quote_status = 'N'
 where quote_no not in (
    select quote_no
      from job
     where quote_no is not null
);

-- Define comments for new columns to provide data dictionary metadata.
comment on column quote.quote_status is
    'Flag indicating if the quote was converted to a job (Y = Yes, N = No). Default is N.'
    ;
comment on column quote.quote_reasoning is
    'Free-text field capturing why an unfulfilled quote passed its preferred start date.'
    ;

-- Verify
DESC QUOTE;

select quote_no,
       quote_status,
       quote_reasoning
  from quote;

commit;

-- Create tables to manage truck services, including tasks performed
-- and mechanic assignment details.
create table service_task (
    task_code        char(5) not null,
    task_name        varchar2(50) not null,
    task_description varchar2(200) not null
);

-- Define comments for new columns to provide data dictionary metadata.
comment on column service_task.task_code is
    'Unique identifier for a maintenance task type';

comment on column service_task.task_name is
    'The standard name of the maintenance activity';

comment on column service_task.task_description is
    'Detailed description of what the task involves';

-- Table and column comments for unique service occurence
create table service (
    service_id             number(6) not null,  -- Assumption: service_id is used as a surrogate primary key to simplify indexing and relationships
    truck_vin              char(17) not null,
    service_start_datetime date not null,
    service_end_datetime   date,           -- Assumption: service_end_datetime may be NULL while service is ongoing
    service_kms            number(6) not null -- Assumption: service_kms must be recorded for each service to support maintenance interval tracking
);

-- Define comments for new columns to provide data dictionary metadata.
comment on column service.service_id is
    'Surrogate primary key for unique service events';

comment on column service.truck_vin is
    'Vehicle Identification Number (VIN) of the truck serviced';

comment on column service.service_start_datetime is
    'The calendar date and time when the service started';

comment on column service.service_end_datetime is
    'The calendar date and time when the service concluded';

comment on column service.service_kms is
    'The odometer reading of the truck at the time of service';

-- Bridging entity for the many-to-many relationship
create table service_log (
    service_id       number(6) not null,
    task_code        char(5) not null,
    emp_no           number(3) not null, -- Assumption: mechanics are identified using emp_no from EMPLOYEE table
    service_log_note varchar2(200) not null
);

-- Define comments for new columns to provide data dictionary metadata.
comment on column service_log.service_id is
    'Surrogate key linking back to the parent service event';

comment on column service_log.task_code is
    'Lookup key identifying the task type performed';

comment on column service_log.emp_no is
    'The employee number of the mechanic who performed this task';

comment on column service_log.service_log_note is
    'Free text note explaining details of the task execution';

-- Service_task contraints
alter table service_task add constraint service_task_pk primary key ( task_code );
alter table service_task add constraint service_task_uq unique ( task_name );

-- Service constraints
alter table service add constraint service_pk primary key ( service_id );

alter table service add constraint chk_service_dates check ( service_end_datetime >= service_start_datetime
);

-- Service_log constraints
alter table service_log add constraint service_log_pk primary key ( service_id,
                                                                    task_code );

-- FK Constraints
alter table service
    add constraint truck_service_fk foreign key ( truck_vin )
        references truck ( truck_vin );

alter table service_log
    add constraint service_service_log_fk foreign key ( service_id )
        references service ( service_id );

alter table service_log
    add constraint service_task_service_log_fk foreign key ( task_code )
        references service_task ( task_code );

alter table service_log
    add constraint employee_service_log_fk foreign key ( emp_no )
        references employee ( emp_no );

-- Verification

DESC service_task;
DESC service;
DESC service_log;

select *
  from service_task;
select *
  from service;
select *
  from service_log;

commit;
