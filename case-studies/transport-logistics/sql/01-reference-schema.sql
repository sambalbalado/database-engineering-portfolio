-- Portfolio support code, newly written to replace an unavailable supplied starter.
-- The reference-table design was supplied in the original exercise; this DDL is a reconstruction.
CREATE TABLE customer (
 cust_no NUMBER(4) CONSTRAINT customer_pk PRIMARY KEY,
 cust_gname VARCHAR2(30), cust_fname VARCHAR2(30), cust_bname VARCHAR2(40),
 cust_contact_no CHAR(10) NOT NULL, cust_street VARCHAR2(40) NOT NULL,
 cust_town VARCHAR2(30) NOT NULL, cust_pcode CHAR(4) NOT NULL,
 CONSTRAINT customer_name_ck CHECK (cust_gname IS NOT NULL OR cust_fname IS NOT NULL OR cust_bname IS NOT NULL)
);
CREATE TABLE truck (
 truck_vin CHAR(17) CONSTRAINT truck_pk PRIMARY KEY,
 truck_rego CHAR(6) NOT NULL, truck_kms NUMBER(6) NOT NULL,
 truck_last_service_kms NUMBER(6) NOT NULL, truck_purchase_cost NUMBER(8,2) NOT NULL,
 truck_date_purchased DATE NOT NULL,
 CONSTRAINT truck_values_ck CHECK (truck_kms >= 0 AND truck_last_service_kms >= 0
   AND truck_last_service_kms <= truck_kms AND truck_purchase_cost > 0)
);
CREATE TABLE trailer (
 trailer_code CHAR(5) CONSTRAINT trailer_pk PRIMARY KEY,
 trailer_purchase_cost NUMBER(8,2) NOT NULL, trailer_date_purchased DATE NOT NULL,
 CONSTRAINT trailer_cost_ck CHECK (trailer_purchase_cost > 0)
);
CREATE TABLE combination (
 truck_vin CHAR(17) NOT NULL, trailer_code CHAR(5) NOT NULL,
 CONSTRAINT combination_pk PRIMARY KEY (truck_vin, trailer_code),
 CONSTRAINT combination_truck_fk FOREIGN KEY (truck_vin) REFERENCES truck(truck_vin),
 CONSTRAINT combination_trailer_fk FOREIGN KEY (trailer_code) REFERENCES trailer(trailer_code)
);
COMMENT ON COLUMN customer.cust_no IS 'Synthetic customer identifier';
COMMENT ON COLUMN customer.cust_gname IS 'Customer given name';
COMMENT ON COLUMN customer.cust_fname IS 'Customer family name';
COMMENT ON COLUMN customer.cust_bname IS 'Optional business name';
COMMENT ON COLUMN customer.cust_contact_no IS 'Non-contactable demonstration phone number';
COMMENT ON COLUMN customer.cust_street IS 'Synthetic street address';
COMMENT ON COLUMN customer.cust_town IS 'Town or city';
COMMENT ON COLUMN customer.cust_pcode IS 'Postal code';
COMMENT ON COLUMN truck.truck_vin IS 'Synthetic 17-character vehicle identifier';
COMMENT ON COLUMN truck.truck_rego IS 'Vehicle registration';
COMMENT ON COLUMN truck.truck_kms IS 'Current odometer reading';
COMMENT ON COLUMN truck.truck_last_service_kms IS 'Odometer reading at last service';
COMMENT ON COLUMN truck.truck_purchase_cost IS 'Truck purchase cost';
COMMENT ON COLUMN truck.truck_date_purchased IS 'Truck purchase date';
COMMENT ON COLUMN trailer.trailer_code IS 'Trailer identifier';
COMMENT ON COLUMN trailer.trailer_purchase_cost IS 'Trailer purchase cost';
COMMENT ON COLUMN trailer.trailer_date_purchased IS 'Trailer purchase date';
COMMENT ON COLUMN combination.truck_vin IS 'Truck in the approved pairing';
COMMENT ON COLUMN combination.trailer_code IS 'Trailer in the approved pairing';
