-- smth

drop table dev_schema.t1;
drop table dev_schema.t2;
drop table dev_schema.t3;

create table dev_schema.t1(
    id number not null primary key,
    fk number not null
);
/
create table dev_schema.t2(
    id number not null primary key,
    fk number not null
);
/
create table dev_schema.t3(
    id number not null primary key, 
    fk number not null
);

ALTER TABLE dev_schema.aa
    ADD CONSTRAINT a_b_fk FOREIGN KEY ( bb_id )
        REFERENCES dev_schema.bb ( id );

alter table dev_schema.t1 add constraint t3_id_fk foreign key (fk) references dev_schema.t3(id);
alter table dev_schema.t3 add CONSTRAINT t2_id_fk FOREIGN KEY ( fk ) REFERENCES dev_schema.t2 ( id );

-- DEV

DROP TABLE dev_schema.table3;

DROP TABLE dev_schema.table2;

DROP TABLE dev_schema.table1;

CREATE TABLE dev_schema.table1 (
    id   NUMBER NOT NULL,
    name VARCHAR(20) NOT NULL,
    CONSTRAINT table1_id_pk PRIMARY KEY ( id )
);

CREATE TABLE dev_schema.table2 (
    id        NUMBER NOT NULL,
    name      VARCHAR(20) NOT NULL,
    table1_id NUMBER NOT NULL,
    CONSTRAINT table2_id_pk PRIMARY KEY ( id ),
    CONSTRAINT table1_id_fk FOREIGN KEY ( table1_id )
        REFERENCES dev_schema.table1 ( id )
);

CREATE TABLE dev_schema.table3 (
    id        NUMBER NOT NULL,
    name      VARCHAR(20) NOT NULL,
    table2_id NUMBER NOT NULL,
    CONSTRAINT table3_id_pk PRIMARY KEY ( id ),
    CONSTRAINT table2_id_fk FOREIGN KEY ( table2_id )
        REFERENCES dev_schema.table2 ( id )
);

--  DEV Loop

CREATE TABLE dev_schema.aa (
    id    NUMBER NOT NULL,
    name  VARCHAR(20) NOT NULL,
    bb_id NUMBER NOT NULL,
    CONSTRAINT aa_id_pk PRIMARY KEY ( id )
);

CREATE TABLE dev_schema.bb (
    id    NUMBER NOT NULL,
    name  VARCHAR(20) NOT NULL,
    cc_id NUMBER NOT NULL,
    CONSTRAINT bb_id_pk PRIMARY KEY ( id )
);

CREATE TABLE dev_schema.cc (
    id    NUMBER NOT NULL,
    name  VARCHAR(20) NOT NULL,
    aa_id NUMBER NOT NULL,
    CONSTRAINT cc_id_pk PRIMARY KEY ( id )
);

DROP TABLE dev_schema.aa;

DROP TABLE dev_schema.bb;

DROP TABLE dev_schema.cc;

ALTER TABLE dev_schema.aa
    ADD CONSTRAINT a_b_fk FOREIGN KEY ( bb_id )
        REFERENCES dev_schema.bb ( id );

ALTER TABLE dev_schema.bb
    ADD CONSTRAINT b_c_fk FOREIGN KEY ( cc_id )
        REFERENCES dev_schema.cc ( id );

ALTER TABLE dev_schema.cc
    ADD CONSTRAINT c_a_fk FOREIGN KEY ( aa_id )
        REFERENCES dev_schema.aa ( id );

ALTER TABLE dev_schema.aa DROP CONSTRAINT a_b_fk;

ALTER TABLE dev_schema.bb DROP CONSTRAINT b_c_fk;

ALTER TABLE dev_schema.cc DROP CONSTRAINT c_a_fk;

-- PROD 

DROP TABLE prod_schema.table3;

DROP TABLE prod_schema.table2;

DROP TABLE prod_schema.table1;

CREATE TABLE prod_schema.table1 (
    id   NUMBER NOT NULL,
    name VARCHAR(20) NOT NULL,
    CONSTRAINT table1_id_pk PRIMARY KEY ( id )
);

CREATE TABLE prod_schema.table2 (
    id        NUMBER NOT NULL,
    name      VARCHAR(20) NOT NULL,
    table1_id NUMBER NOT NULL,
    CONSTRAINT table2_id_pk PRIMARY KEY ( id ),
    CONSTRAINT table1_id_fk FOREIGN KEY ( table1_id ) REFERENCES prod_schema.table1 ( id )
);

create table prod_schema.smth(
    id number not null primary key
);

CREATE TABLE prod_schema.table3 (
    id        NUMBER NOT NULL,
    name      VARCHAR(20) NOT NULL,
    table2_id NUMBER NOT NULL,
    CONSTRAINT table3_id_pk PRIMARY KEY ( id ),
    CONSTRAINT table2_id_fk FOREIGN KEY ( table2_id )REFERENCES prod_schema.table2 ( id )
);

ALTER TABLE prod_schema.table3 ADD empty_row NUMBER;

ALTER TABLE prod_schema.table3 DROP COLUMN empty_row;

CREATE INDEX prod_schema.ya_ne_sdala ON prod_schema.table3 (name);

DROP INDEX prod_schema.table3_name_idx;

SELECT
    index_name,
    table_name
FROM
    all_indexes
WHERE
    owner = 'DEV_SCHEMA';