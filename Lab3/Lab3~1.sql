DROP TABLE C##LABDEV.UNI;
DROP TABLE C##LABDEV.GROUPS;
DROP TABLE C##LABDEV.STUDENTS;

DROP TABLE C##LABPROD.UNI;
DROP TABLE C##LABPROD.GROUPS;
DROP TABLE C##LABPROD.STUDENTS;

CREATE TABLE c##labdev.uni (
    uni_id NUMBER NOT NULL,
    uni_name VARCHAR2(20) NOT NULL,
    CONSTRAINT uni_id_pk PRIMARY KEY (uni_id)
);
/
CREATE TABLE c##labdev.groups (
    gr_id NUMBER NOT NULL,
    gr_name VARCHAR2(20) NOT NULL,
    uni_id NUMBER NOT NULL,
    CONSTRAINT gr_id_pk PRIMARY KEY (gr_id),
    CONSTRAINT uni_id_fk FOREIGN KEY (uni_id) REFERENCES c##labdev.uni (uni_id)
);
/
CREATE TABLE c##labdev.students (
    st_id NUMBER NOT NULL,
    st_name VARCHAR2(20) NOT NULL,
    gr_id NUMBER NOT NULL,
    CONSTRAINT st_id_pk PRIMARY KEY (st_id),
    CONSTRAINT gr_id_fk FOREIGN KEY (gr_id) REFERENCES c##labdev.groups (gr_id)
);
/
CREATE TABLE c##labprod.uni (
    uni_id NUMBER NOT NULL,
    uni_name VARCHAR2(20) NOT NULL,
    CONSTRAINT uni_id_pk PRIMARY KEY (uni_id)
);

SELECT OBJECT_NAME
FROM ALL_OBJECTS
WHERE OBJECT_TYPE = 'PROCEDURE'
AND OWNER = 'C##LABDEV';
/
CREATE TABLE c##labprod.groups (
    gr_id NUMBER NOT NULL,
    gr_name VARCHAR2(20) NOT NULL,
    uni_id NUMBER NOT NULL,
    st_count NUMBER NOT NULL,
    CONSTRAINT gr_id_pk PRIMARY KEY (gr_id),
    CONSTRAINT uni_id_fk FOREIGN KEY (uni_id) REFERENCES c##labprod.uni (uni_id)
);
/
CREATE TABLE c##labprod.students (
    st_id NUMBER NOT NULL,
    st_name VARCHAR2(20) NOT NULL,
    st_surname VARCHAR2(20) NOT NULL,
    gr_id NUMBER NOT NULL,
    CONSTRAINT st_id_pk PRIMARY KEY (st_id),
    CONSTRAINT gr_id_fk FOREIGN KEY (gr_id) REFERENCES c##labprod.groups (gr_id)
);

CREATE TABLE C##LABdev.aa (
    id NUMBER PRIMARY KEY,
    b_id NUMBER NOT NULL
);

CREATE TABLE C##LABdev.bb (
    id NUMBER PRIMARY KEY,
    c_id NUMBER NOT NULL
);

CREATE TABLE C##LABdev.cc (
    id NUMBER PRIMARY KEY,
    a_id NUMBER NOT NULL
);

ALTER TABLE C##LABDEV.AA DROP CONSTRAINT FK_A_B;
ALTER TABLE C##LABDEV.BB DROP CONSTRAINT FK_B_C;
ALTER TABLE C##LABDEV.CC DROP CONSTRAINT FK_C_A;

ALTER TABLE C##LABdev.aa ADD CONSTRAINT fk_a_b FOREIGN KEY (b_id) REFERENCES C##LABdev.bb (id);

ALTER TABLE C##LABdev.bb ADD CONSTRAINT fk_b_c FOREIGN KEY (c_id) REFERENCES C##LABdev.cc (id);

ALTER TABLE C##LABdev.cc ADD CONSTRAINT fk_c_a FOREIGN KEY (a_id) REFERENCES C##LABdev.aa (id);


CREATE OR REPLACE PROCEDURE COMPARE_SCHEM(
    DEV IN VARCHAR2,
    PROD IN VARCHAR2
) 
AS
    TYPE LIST_OF_ELEMENTS IS TABLE OF VARCHAR2(200);
    
    TABLES_DEV LIST_OF_ELEMENTS := LIST_OF_ELEMENTS();
    TABLES_PROD LIST_OF_ELEMENTS := LIST_OF_ELEMENTS();
    TABLES_SORTED LIST_OF_ELEMENTS := LIST_OF_ELEMENTS();
    TABLES_CHECKED LIST_OF_ELEMENTS := LIST_OF_ELEMENTS();
    
    PROC_DEV LIST_OF_ELEMENTS := LIST_OF_ELEMENTS();
    PROC_PROD LIST_OF_ELEMENTS := LIST_OF_ELEMENTS();
    PROC_SORTED LIST_OF_ELEMENTS := LIST_OF_ELEMENTS();
    PROC_CHECKED LIST_OF_ELEMENTS := LIST_OF_ELEMENTS();
    
    COUNTER NUMBER;
    
    PROCEDURE DFS_SORT_TABLES(
        P_TABLE_NAME IN VARCHAR2,
        P_COUNTER IN OUT NUMBER
    ) IS
        C_CHILD_TABLE VARCHAR2(200);
        
        CURSOR FK_CURSOR IS
        SELECT CC.TABLE_NAME AS CHILD_TABLE
        FROM ALL_CONSTRAINTS PC
            JOIN ALL_CONSTRAINTS CC
            ON PC.CONSTRAINT_NAME = CC.R_CONSTRAINT_NAME
        WHERE PC.CONSTRAINT_TYPE = 'P'
        AND CC.CONSTRAINT_TYPE = 'R'
        AND PC.OWNER = DEV
        AND CC.OWNER = DEV
        AND PC.TABLE_NAME = P_TABLE_NAME;
        
    BEGIN
        IF P_TABLE_NAME NOT MEMBER OF TABLES_CHECKED THEN
            TABLES_CHECKED.EXTEND;
            TABLES_CHECKED(TABLES_CHECKED.LAST) := P_TABLE_NAME;
            
            FOR i IN FK_CURSOR LOOP
                C_CHILD_TABLE := i.CHILD_TABLE;
                IF C_CHILD_TABLE NOT MEMBER OF TABLES_CHECKED THEN
                    DFS_SORT_TABLES(C_CHILD_TABLE, P_COUNTER);
                ELSE
                    DBMS_OUTPUT.PUT_LINE('LOOPED CONNECTIONS DETECTED');
                END IF;
            END LOOP;
            
            TABLES_SORTED.EXTEND;
            P_COUNTER := P_COUNTER + 1;
            TABLES_SORTED(TABLES_SORTED.LAST) := P_TABLE_NAME;
        END IF;
    END DFS_SORT_TABLES;

    PROCEDURE DFS_SORT_PROCS(
        P_PROC_NAME IN VARCHAR2,
        P_COUNTER IN OUT NUMBER
    ) IS
        CURSOR DEP_CURSOR IS
        SELECT REFERENCED_NAME
        FROM ALL_DEPENDENCIES
        WHERE NAME = P_PROC_NAME
        AND TYPE = 'PROCEDURE'
        AND OWNER = DEV;
        
    BEGIN
        IF P_PROC_NAME NOT MEMBER OF PROC_CHECKED THEN
            PROC_CHECKED.EXTEND;
            PROC_CHECKED(PROC_CHECKED.LAST) := P_PROC_NAME;
            
            FOR i IN DEP_CURSOR LOOP
                IF i.REFERENCED_NAME NOT MEMBER OF PROC_CHECKED THEN
                    DFS_SORT_PROCS(i.REFERENCED_NAME, P_COUNTER);
                ELSE
                    DBMS_OUTPUT.PUT_LINE('LOOPED CONNECTIONS DETECTED');
                END IF;
            END LOOP;
            
            PROC_SORTED.EXTEND;
            P_COUNTER := P_COUNTER + 1;
            PROC_SORTED(PROC_SORTED.LAST) := P_PROC_NAME;
        END IF;
    END DFS_SORT_PROCS;

BEGIN
    COUNTER := 0;
    -- Compare Tables
    SELECT TABLE_NAME BULK COLLECT INTO TABLES_DEV
    FROM ALL_TABLES
    WHERE OWNER = DEV;
    
    SELECT TABLE_NAME BULK COLLECT INTO TABLES_PROD
    FROM ALL_TABLES
    WHERE OWNER = PROD;
    
    FOR i IN 1..TABLES_DEV.COUNT LOOP
        DFS_SORT_TABLES(TABLES_DEV(i), COUNTER);
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'TABLES IN ' || DEV || ' SCHEMA BUT NOT IN ' || PROD);
    FOR i IN REVERSE 1..TABLES_SORTED.COUNT LOOP
        IF TABLES_SORTED(i) NOT MEMBER OF TABLES_PROD THEN
            DBMS_OUTPUT.PUT_LINE(TABLES_SORTED(i));
        ELSE
            DBMS_OUTPUT.PUT_LINE(TABLES_SORTED(i) || ' (DIFF STRUCTURE)');
        END IF;
    END LOOP;

    -- Compare Procedures
    COUNTER := 0;

    SELECT OBJECT_NAME BULK COLLECT INTO PROC_DEV
    FROM ALL_OBJECTS
    WHERE OBJECT_TYPE = 'PROCEDURE'
    AND OWNER = DEV
    AND OBJECT_NAME NOT IN (
        SELECT OBJECT_NAME FROM ALL_OBJECTS WHERE OBJECT_NAME LIKE 'SYS.%' OR OBJECT_NAME LIKE 'DBMS_%'
    );
    
    SELECT OBJECT_NAME BULK COLLECT INTO PROC_PROD
    FROM ALL_OBJECTS
    WHERE OBJECT_TYPE = 'PROCEDURE'
    AND OWNER = PROD
    AND OBJECT_NAME NOT IN (
        SELECT OBJECT_NAME FROM ALL_OBJECTS WHERE OBJECT_NAME LIKE 'SYS.%' OR OBJECT_NAME LIKE 'DBMS_%'
    );
    
    FOR i IN 1..PROC_DEV.COUNT LOOP
        DFS_SORT_PROCS(PROC_DEV(i), COUNTER);
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'USER-DEFINED PROCEDURES IN ' || DEV || ' SCHEMA BUT NOT IN ' || PROD);
    FOR i IN REVERSE 1..PROC_SORTED.COUNT LOOP
        IF PROC_SORTED(i) NOT MEMBER OF PROC_PROD THEN
            DBMS_OUTPUT.PUT_LINE(PROC_SORTED(i));
        ELSE
            DBMS_OUTPUT.PUT_LINE(PROC_SORTED(i) || ' (DIFF IMPLEMENTATION)');
        END IF;
    END LOOP;
END COMPARE_SCHEM;





CALL COMPARE_SCHEM('C##LABDEV', 'C##LABPROD');
