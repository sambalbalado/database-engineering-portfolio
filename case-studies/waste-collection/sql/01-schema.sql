-- Author design baseline, generated with Oracle SQL Developer Data Modeler 24.3.1.
-- No reset operations. Apply 02-integrity.sql before loading examples.
CREATE TABLE BIN
    (
     bin_rfid               CHAR (24 CHAR)  NOT NULL ,
     supply_date            DATE  NOT NULL ,
     replacement_reason     VARCHAR2 (40) ,
     waste_type_id          CHAR (2 CHAR)  NOT NULL ,
     bin_size               NUMBER (3)  NOT NULL ,
     property_id            NUMBER (7)  NOT NULL ,
     contract_bin_supply_id NUMBER (7)  NOT NULL
    )
;

ALTER TABLE BIN
    ADD CONSTRAINT chk_replacementreason
    CHECK (replacement_reason IN ('Bin Failure', 'Damaged by Owner', 'Damaged during pickup of waste', 'Stolen'))
;

COMMENT ON COLUMN BIN.bin_rfid IS 'RFID tag of a bin '
;

COMMENT ON COLUMN BIN.supply_date IS 'Date of supply'
;

COMMENT ON COLUMN BIN.replacement_reason IS 'Reason of replacement
- Damage by owner
- Bin Failure
- Damaged during pickup of waste
- Stolen'
;

COMMENT ON COLUMN BIN.waste_type_id IS 'Waste type ID'
;

COMMENT ON COLUMN BIN.bin_size IS 'Bin size'
;

COMMENT ON COLUMN BIN.property_id IS 'Property ID'
;

COMMENT ON COLUMN BIN.contract_bin_supply_id IS 'Contract bin supply ID'
;

ALTER TABLE BIN
    ADD CONSTRAINT BIN_PK PRIMARY KEY ( bin_rfid ) ;

CREATE TABLE BIN_COLLECTION
    (
     collection_run_id NUMBER (7)  NOT NULL ,
     bin_rfid          CHAR (24 CHAR)  NOT NULL ,
     collected_kgs     NUMBER (5,2) ,
     overweight        CHAR (1)  NOT NULL
    )
;

ALTER TABLE BIN_COLLECTION
    ADD CONSTRAINT chk_overweight
    CHECK (overweight IN ('N', 'Y'))
;

COMMENT ON COLUMN BIN_COLLECTION.collection_run_id IS 'Collection run entity ID'
;

COMMENT ON COLUMN BIN_COLLECTION.bin_rfid IS 'RFID tag of a bin '
;

COMMENT ON COLUMN BIN_COLLECTION.collected_kgs IS 'Collected in kilograms'
;

COMMENT ON COLUMN BIN_COLLECTION.overweight IS 'Overweight of the bin
(Y) - flagged as overweight
(N) - flagged as not overweight'
;

ALTER TABLE BIN_COLLECTION
    ADD CONSTRAINT BIN_COLLECTION_PK PRIMARY KEY ( collection_run_id, bin_rfid ) ;

CREATE TABLE BIN_TYPE
    (
     waste_type_id   CHAR (2 CHAR)  NOT NULL ,
     bin_size        NUMBER (3)  NOT NULL ,
     bin_supply_cost NUMBER (7,2)  NOT NULL
    )
;

COMMENT ON COLUMN BIN_TYPE.waste_type_id IS 'Waste type ID'
;

COMMENT ON COLUMN BIN_TYPE.bin_size IS 'Bin size'
;

COMMENT ON COLUMN BIN_TYPE.bin_supply_cost IS 'Standard bin supply cost'
;

ALTER TABLE BIN_TYPE
    ADD CONSTRAINT BIN_TYPE_PK PRIMARY KEY ( waste_type_id, bin_size ) ;

CREATE TABLE COLLECTION_RUN
    (
     collection_run_id    NUMBER (7)  NOT NULL ,
     date_of_collection   DATE  NOT NULL ,
     waste_type_id        CHAR (2 CHAR)  NOT NULL ,
     contract_no          NUMBER (8)  NOT NULL ,
     collection_truck_vin VARCHAR2 (20)  NOT NULL
    )
;

COMMENT ON COLUMN COLLECTION_RUN.collection_run_id IS 'Collection run entity ID'
;

COMMENT ON COLUMN COLLECTION_RUN.date_of_collection IS 'Date of collection'
;

COMMENT ON COLUMN COLLECTION_RUN.waste_type_id IS 'Waste type ID'
;

COMMENT ON COLUMN COLLECTION_RUN.contract_no IS 'Contract number '
;

COMMENT ON COLUMN COLLECTION_RUN.collection_truck_vin IS 'Collection trucks Vehicle Identification Number'
;

ALTER TABLE COLLECTION_RUN
    ADD CONSTRAINT COLLECTION_RUN_PK PRIMARY KEY ( collection_run_id ) ;

ALTER TABLE COLLECTION_RUN
    ADD CONSTRAINT COLLECTION_RUN_UK UNIQUE ( contract_no , waste_type_id , date_of_collection ) ;

CREATE TABLE CONTRACT
    (
     contract_no    NUMBER (8)  NOT NULL ,
     start_date     DATE  NOT NULL ,
     end_date       DATE  NOT NULL ,
     authority_name VARCHAR2 (50)  NOT NULL
    )
;

COMMENT ON COLUMN CONTRACT.contract_no IS 'Contract number '
;

COMMENT ON COLUMN CONTRACT.start_date IS 'Start date of the contract'
;

COMMENT ON COLUMN CONTRACT.end_date IS 'End date of the contract'
;

COMMENT ON COLUMN CONTRACT.authority_name IS 'Authority name '
;

ALTER TABLE CONTRACT
    ADD CONSTRAINT CONTRACT_PK PRIMARY KEY ( contract_no ) ;

CREATE TABLE CONTRACT_BIN_SUPPLY
    (
     contract_bin_supply_id   NUMBER (7)  NOT NULL ,
     contract_no              NUMBER (8)  NOT NULL ,
     waste_type_id            CHAR (2 CHAR)  NOT NULL ,
     bin_size                 NUMBER (3)  NOT NULL ,
     contract_bin_supply_cost NUMBER (7,2)  NOT NULL
    )
;

COMMENT ON COLUMN CONTRACT_BIN_SUPPLY.contract_bin_supply_id IS 'Contract bin supply ID'
;

COMMENT ON COLUMN CONTRACT_BIN_SUPPLY.contract_no IS 'Contract number '
;

COMMENT ON COLUMN CONTRACT_BIN_SUPPLY.waste_type_id IS 'Waste type ID'
;

COMMENT ON COLUMN CONTRACT_BIN_SUPPLY.bin_size IS 'Bin size'
;

COMMENT ON COLUMN CONTRACT_BIN_SUPPLY.contract_bin_supply_cost IS 'Supply cost of the various bin '
;

ALTER TABLE CONTRACT_BIN_SUPPLY
    ADD CONSTRAINT CONTRACT_BIN_SUPPLY_PK PRIMARY KEY ( contract_bin_supply_id ) ;

ALTER TABLE CONTRACT_BIN_SUPPLY
    ADD CONSTRAINT CONTRACT_BIN_SUPPLY_UK UNIQUE ( contract_no , bin_size , waste_type_id ) ;

CREATE TABLE CONTRACT_WASTE_COLLECTION
    (
     contract_no            NUMBER (8)  NOT NULL ,
     waste_type_id          CHAR (2 CHAR)  NOT NULL ,
     collection_cost_per_kg NUMBER (7,2)  NOT NULL ,
     collection_frequency   VARCHAR2 (50)  NOT NULL
    )
;

COMMENT ON COLUMN CONTRACT_WASTE_COLLECTION.contract_no IS 'Contract number '
;

COMMENT ON COLUMN CONTRACT_WASTE_COLLECTION.waste_type_id IS 'Waste type ID'
;

COMMENT ON COLUMN CONTRACT_WASTE_COLLECTION.collection_cost_per_kg IS 'Collection cost per kilogram for the waste types to be collected under this contract'
;

COMMENT ON COLUMN CONTRACT_WASTE_COLLECTION.collection_frequency IS 'Collection frequency '
;

ALTER TABLE CONTRACT_WASTE_COLLECTION
    ADD CONSTRAINT CONTRACT_WASTE_COLLECTION_PK PRIMARY KEY ( waste_type_id, contract_no ) ;

CREATE TABLE LOCAL_AUTHORITY
    (
     authority_name   VARCHAR2 (50)  NOT NULL ,
     ceo_given_name   VARCHAR2 (20)  NOT NULL ,
     ceo_family_name  VARCHAR2 (20)  NOT NULL ,
     contact_no       VARCHAR2 (15)  NOT NULL ,
     total_area_sq_km NUMBER (8,2)  NOT NULL ,
     authority_type   CHAR (1)  NOT NULL
    )
;

ALTER TABLE LOCAL_AUTHORITY
    ADD CONSTRAINT chk_authoritytype
    CHECK (authority_type IN ('B', 'C', 'D', 'S', 'T'))
;

COMMENT ON COLUMN LOCAL_AUTHORITY.authority_name IS 'Authority name '
;

COMMENT ON COLUMN LOCAL_AUTHORITY.ceo_given_name IS 'CEO given name'
;

COMMENT ON COLUMN LOCAL_AUTHORITY.ceo_family_name IS 'CEO Family name'
;

COMMENT ON COLUMN LOCAL_AUTHORITY.contact_no IS 'contact telephone number'
;

COMMENT ON COLUMN LOCAL_AUTHORITY.total_area_sq_km IS 'Total area in square kilometres'
;

COMMENT ON COLUMN LOCAL_AUTHORITY.authority_type IS 'Local Authorities are classified into the following fixed types:
- B as Borough
- C as City
- D as District Council
- S as Shire
- T as Town'
;

ALTER TABLE LOCAL_AUTHORITY
    ADD CONSTRAINT LOCAL_AUTHORITY_PK PRIMARY KEY ( authority_name ) ;

CREATE TABLE OWNER
    (
     owner_id       NUMBER (7)  NOT NULL ,
     owner_name     VARCHAR2 (50)  NOT NULL ,
     owner_email    VARCHAR2 (50)  NOT NULL ,
     owner_phone_no VARCHAR2 (15)  NOT NULL
    )
;

COMMENT ON COLUMN OWNER.owner_id IS 'Owner''s ID'
;

COMMENT ON COLUMN OWNER.owner_name IS 'Owner name'
;

COMMENT ON COLUMN OWNER.owner_email IS 'Owner email'
;

COMMENT ON COLUMN OWNER.owner_phone_no IS 'Owner telephone number'
;

ALTER TABLE OWNER
    ADD CONSTRAINT OWNER_PK PRIMARY KEY ( owner_id ) ;

CREATE TABLE PROPERTY
    (
     property_id    NUMBER (7)  NOT NULL ,
     street_id      NUMBER (4)  NOT NULL ,
     authority_name VARCHAR2 (50)  NOT NULL ,
     street_no      NUMBER (5)  NOT NULL
    )
;

COMMENT ON COLUMN PROPERTY.property_id IS 'Property ID'
;

COMMENT ON COLUMN PROPERTY.street_id IS 'Street ID'
;

COMMENT ON COLUMN PROPERTY.authority_name IS 'Authority name '
;

COMMENT ON COLUMN PROPERTY.street_no IS 'Street number'
;

ALTER TABLE PROPERTY
    ADD CONSTRAINT PROPERTY_PK PRIMARY KEY ( property_id ) ;

ALTER TABLE PROPERTY
    ADD CONSTRAINT PROPERTY_UK UNIQUE ( street_no , authority_name , street_id ) ;

CREATE TABLE PROPERTY_OWNER
    (
     owner_id    NUMBER (7)  NOT NULL ,
     property_id NUMBER (7)  NOT NULL
    )
;

COMMENT ON COLUMN PROPERTY_OWNER.owner_id IS 'Owner''s ID'
;

COMMENT ON COLUMN PROPERTY_OWNER.property_id IS 'Property ID'
;

ALTER TABLE PROPERTY_OWNER
    ADD CONSTRAINT PROPERTY_OWNER_PK PRIMARY KEY ( property_id, owner_id ) ;

CREATE TABLE STREET
    (
     street_id         NUMBER (4)  NOT NULL ,
     authority_name    VARCHAR2 (50)  NOT NULL ,
     street_name       VARCHAR2 (50)  NOT NULL ,
     length_metres     NUMBER (5,2)  NOT NULL ,
     road_surface_type CHAR (1)  NOT NULL ,
     lanes_no          NUMBER (3)  NOT NULL
    )
;

ALTER TABLE STREET
    ADD CONSTRAINT chk_roadsurfacetype
    CHECK (road_surface_type IN ('A', 'C', 'U'))
;

COMMENT ON COLUMN STREET.street_id IS 'Street ID'
;

COMMENT ON COLUMN STREET.authority_name IS 'Authority name '
;

COMMENT ON COLUMN STREET.street_name IS 'Street name '
;

COMMENT ON COLUMN STREET.length_metres IS 'Street length in metres'
;

COMMENT ON COLUMN STREET.road_surface_type IS 'Type of road surface
- A as Asphalt
- C as Concrete
- U as Unsealed'
;

COMMENT ON COLUMN STREET.lanes_no IS 'number of lanes'
;

ALTER TABLE STREET
    ADD CONSTRAINT STREET_PK PRIMARY KEY ( street_id, authority_name ) ;

CREATE TABLE TRUCK
    (
     collection_truck_vin VARCHAR2 (20)  NOT NULL ,
     truck_rego           VARCHAR2 (10)  NOT NULL ,
     truck_make           VARCHAR2 (10)  NOT NULL ,
     truck_year           NUMBER (4)  NOT NULL ,
     truck_model          VARCHAR2 (30)  NOT NULL
    )
;

COMMENT ON COLUMN TRUCK.collection_truck_vin IS 'Collection trucks Vehicle Identification Number'
;

COMMENT ON COLUMN TRUCK.truck_rego IS 'Truck Rego'
;

COMMENT ON COLUMN TRUCK.truck_make IS 'Truck make '
;

COMMENT ON COLUMN TRUCK.truck_year IS 'Truck Year'
;

COMMENT ON COLUMN TRUCK.truck_model IS 'Model of truck'
;

ALTER TABLE TRUCK
    ADD CONSTRAINT TRUCK_PK PRIMARY KEY ( collection_truck_vin ) ;

CREATE TABLE WASTE_TYPE
    (
     waste_type_id   CHAR (2 CHAR)  NOT NULL ,
     waste_type_desc VARCHAR2 (20)  NOT NULL
    )
;

COMMENT ON COLUMN WASTE_TYPE.waste_type_id IS 'Waste type ID'
;

COMMENT ON COLUMN WASTE_TYPE.waste_type_desc IS 'Waste type description'
;

ALTER TABLE WASTE_TYPE
    ADD CONSTRAINT WASTE_TYPE_PK PRIMARY KEY ( waste_type_id ) ;

ALTER TABLE BIN_COLLECTION
    ADD CONSTRAINT bin_bincollection_fk FOREIGN KEY
    (
     bin_rfid
    )
    REFERENCES BIN
    (
     bin_rfid
    )
;

ALTER TABLE BIN
    ADD CONSTRAINT bintype_bin_fk FOREIGN KEY
    (
     waste_type_id,
     bin_size
    )
    REFERENCES BIN_TYPE
    (
     waste_type_id,
     bin_size
    )
;

ALTER TABLE CONTRACT_BIN_SUPPLY
    ADD CONSTRAINT bintype_contractbinsupply_fk FOREIGN KEY
    (
     waste_type_id,
     bin_size
    )
    REFERENCES BIN_TYPE
    (
     waste_type_id,
     bin_size
    )
;

ALTER TABLE BIN_COLLECTION
    ADD CONSTRAINT collectionrun_bincollection_fk FOREIGN KEY
    (
     collection_run_id
    )
    REFERENCES COLLECTION_RUN
    (
     collection_run_id
    )
;

ALTER TABLE COLLECTION_RUN
    ADD CONSTRAINT collectionrun_truck_fk FOREIGN KEY
    (
     collection_truck_vin
    )
    REFERENCES TRUCK
    (
     collection_truck_vin
    )
;

ALTER TABLE BIN
    ADD CONSTRAINT contbinsupply_bin_fk FOREIGN KEY
    (
     contract_bin_supply_id
    )
    REFERENCES CONTRACT_BIN_SUPPLY
    (
     contract_bin_supply_id
    )
;

ALTER TABLE CONTRACT_BIN_SUPPLY
    ADD CONSTRAINT contract_contractbinsupply_fk FOREIGN KEY
    (
     contract_no
    )
    REFERENCES CONTRACT
    (
     contract_no
    )
;

ALTER TABLE CONTRACT_WASTE_COLLECTION
    ADD CONSTRAINT contract_cwc_fk FOREIGN KEY
    (
     contract_no
    )
    REFERENCES CONTRACT
    (
     contract_no
    )
;

ALTER TABLE COLLECTION_RUN
    ADD CONSTRAINT cwc_cr_fk FOREIGN KEY
    (
     waste_type_id,
     contract_no
    )
    REFERENCES CONTRACT_WASTE_COLLECTION
    (
     waste_type_id,
     contract_no
    )
;

ALTER TABLE CONTRACT
    ADD CONSTRAINT localauthority_contract_fk FOREIGN KEY
    (
     authority_name
    )
    REFERENCES LOCAL_AUTHORITY
    (
     authority_name
    )
;

ALTER TABLE STREET
    ADD CONSTRAINT localauthority_street_fk FOREIGN KEY
    (
     authority_name
    )
    REFERENCES LOCAL_AUTHORITY
    (
     authority_name
    )
;

ALTER TABLE PROPERTY_OWNER
    ADD CONSTRAINT owner_propertyowner_fk FOREIGN KEY
    (
     owner_id
    )
    REFERENCES OWNER
    (
     owner_id
    )
;

ALTER TABLE BIN
    ADD CONSTRAINT property_bin_fk FOREIGN KEY
    (
     property_id
    )
    REFERENCES PROPERTY
    (
     property_id
    )
;

ALTER TABLE PROPERTY_OWNER
    ADD CONSTRAINT property_propertyowner_fk FOREIGN KEY
    (
     property_id
    )
    REFERENCES PROPERTY
    (
     property_id
    )
;

ALTER TABLE PROPERTY
    ADD CONSTRAINT street_property_fk FOREIGN KEY
    (
     street_id,
     authority_name
    )
    REFERENCES STREET
    (
     street_id,
     authority_name
    )
;

ALTER TABLE BIN_TYPE
    ADD CONSTRAINT wastetype_bintype_fk FOREIGN KEY
    (
     waste_type_id
    )
    REFERENCES WASTE_TYPE
    (
     waste_type_id
    )
;

ALTER TABLE CONTRACT_WASTE_COLLECTION
    ADD CONSTRAINT wastetype_cwc_fk FOREIGN KEY
    (
     waste_type_id
    )
    REFERENCES WASTE_TYPE
    (
     waste_type_id
    )
;
