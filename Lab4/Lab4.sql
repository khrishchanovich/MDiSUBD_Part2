DROP TYPE xml_record;
CREATE TYPE xml_record IS TABLE OF VARCHAR2(1000);

DROP TABLE Students;
DROP TABLE Groups;

CREATE TABLE Groups (
    id NUMBER PRIMARY KEY NOT NULL,
    name VARCHAR2(20) NOT NULL,
    c_val NUMBER DEFAULT 0 NOT NULL
);

CREATE TABLE Students (
    id NUMBER PRIMARY KEY NOT NULL,
    name VARCHAR2(20) NOT NULL,
    group_id NUMBER NOT NULL
);

CREATE OR REPLACE TRIGGER update_students_value_in_groups 
    AFTER INSERT OR UPDATE OR DELETE ON Students FOR EACH ROW
BEGIN
    IF INSERTING THEN
        UPDATE Groups SET c_val = c_val + 1 WHERE id = :NEW.group_id;
    ELSIF UPDATING THEN
            UPDATE Groups SET c_val = c_val - 1 WHERE id = :OLD.group_id;
            UPDATE Groups SET c_val = c_val + 1 WHERE id = :NEW.group_id;
    ELSIF DELETING THEN
            UPDATE Groups SET c_val = c_val - 1 WHERE id = :OLD.group_id;
    END IF;
END;

DROP SEQUENCE id_auto_increment_for_groups;
DROP SEQUENCE id_auto_increment_for_students;

CREATE SEQUENCE id_auto_increment_for_groups 
    START WITH 1 
    INCREMENT BY 1 
    NOMAXVALUE;

CREATE SEQUENCE id_auto_increment_for_students 
    START WITH 1 
    INCREMENT BY 1 
    NOMAXVALUE;

CREATE OR REPLACE TRIGGER generate_students_id 
    BEFORE INSERT ON Students FOR EACH ROW
BEGIN
    SELECT  id_auto_increment_for_students.NEXTVAL 
        INTO :NEW.id FROM DUAL;
END;

CREATE OR REPLACE TRIGGER generate_groups_id 
    BEFORE INSERT ON Groups FOR EACH ROW
BEGIN
    SELECT id_auto_increment_for_groups.NEXTVAL 
        INTO :NEW.id FROM DUAL;
END;

INSERT INTO Groups(name) VALUES('001');
INSERT INTO Groups(name) VALUES('002');
INSERT INTO Groups(name) VALUES('003');

INSERT INTO Students(name, group_id) VALUES('A', 1);
INSERT INTO Students(name, group_id) VALUES('B', 2);
INSERT INTO Students(name, group_id) VALUES('C', 2);
INSERT INTO Students(name, group_id) VALUES('D', 1);
INSERT INTO Students(name, group_id) VALUES('E', 2);
INSERT INTO Students(name, group_id) VALUES('F', 1);
INSERT INTO Students(name, group_id) VALUES('G', 1);
INSERT INTO Students(name, group_id) VALUES('R', 3);

SELECT * FROM Students;
SELECT * FROM Groups;

DECLARE
    v_sql VARCHAR2(4000);
    cur sys_refcursor;
BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_select(DBMS_LOB.SUBSTR(read('select.xml'), 4000)));
    v_sql := xml_package.xml_select(DBMS_LOB.SUBSTR(read('select.xml'), 4000));
    open cur for v_sql;
    DBMS_SQL.RETURN_RESULT(cur);
END;

DECLARE
    v_sql CLOB;
    v_sql_string VARCHAR2(32767);
BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_create(DBMS_LOB.SUBSTR(read('create1.xml'), 4000)));
    v_sql := xml_package.xml_create(DBMS_LOB.SUBSTR(read('create1.xml'), 10000));

    v_sql_string := TO_CHAR(v_sql);
    EXECUTE IMMEDIATE v_sql_string;
END;

CREATE TABLE other_table( id NUMBER UNIQUE ,  col_1 NUMBER UNIQUE ,  col_2 NUMBER NOT NULL , CONSTRAINT other_table_pk PRIMARY KEY (col_2));
drop table other_table;
END;

SELECT students.id, students.name, groups.id FROM students LEFT JOIN groups ON
    groups.id = students.group_id WHERE students.id = 1;

SELECT name FROM groups WHERE c_val = 3;

SELECT students.id, students.name, groups.id FROM students LEFT JOIN groups ON
    groups.id = students.group_id WHERE students.id = 1 OR  groups.name IN 
        (SELECT name FROM groups WHERE c_val = 3  );
        
CREATE OR REPLACE DIRECTORY dir AS 'D:\6 semester\MDiSUBD_Part2\Lab4';

CREATE OR REPLACE FUNCTION read(fname VARCHAR2) 
    RETURN VARCHAR2
IS
    file UTL_FILE.FILE_TYPE;
    buff VARCHAR2(10000);
    str VARCHAR2(500);
BEGIN
    file := UTL_FILE.FOPEN('DIR', fname, 'R');

    IF NOT UTL_FILE.IS_OPEN(file) THEN
        DBMS_OUTPUT.PUT_LINE('File ' || fname || ' does not open!');
        RETURN NULL;
    END IF;

    LOOP
        BEGIN
            UTL_FILE.GET_LINE(file, str);
            buff := buff || str;
            
            EXCEPTION
                WHEN OTHERS THEN EXIT;
        END;
    END LOOP;
    
    UTL_FILE.FCLOSE(file);
    RETURN buff;
END read;

BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_insert(read('insert.xml')));
END;

BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_update(read('test_update.xml')));
END;

BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_delete(read('delete.xml')));
END;

BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_create(read('create.xml')));
END;

BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_create(read('create1.xml')));
END;

DECLARE
    v_sql CLOB;
    cur sys_refcursor;
BEGIN
    v_sql := xml_package.xml_create(DBMS_LOB.SUBSTR(read('create1.xml'), 10000));
    
    open cur for v_sql;
    EXECUTE IMMEDIATE cur;
    DBMS_OUTPUT.put_line('Таблица успешно создана.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.put_line('Ошибка при создании таблицы: ' || SQLERRM);
END;

CREATE TABLE mytable( col_1 NUMBER,  col_2 VARCHAR(100)  NOT NULL, CONSTRAINT mytable_pk PRIMARY KEY (col_1), CONSTRAINT mytable_other_table_fk Foreign Key(col_2) REFERENCES other_table(col_2));

BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_drop(read('drop.xml')));
END;

BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_create(read('create_t2.xml')));
END;

DECLARE
    v_sql VARCHAR2(4000);
    cur sys_refcursor;
BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_select(DBMS_LOB.SUBSTR(read('select_task.xml'), 4000)));
    v_sql := xml_package.xml_select(DBMS_LOB.SUBSTR(read('select_task.xml'), 4000));
    open cur for v_sql;
    DBMS_SQL.RETURN_RESULT(cur);
END;


BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_create(read('test_1.xml')));
END;
CREATE TABLE Users( UserId NUMBER,  UserName VARCHAR(50) NOT NULL ,  UserAge NUMBER NOT NULL , CONSTRAINT Users_pk PRIMARY KEY (UserId));
BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_create(read('test_2.xml')));
END;
CREATE TABLE Orders( OrderId NUMBER,  UserId NUMBER,  OrderDate DATE,  TotalAmount NUMBER(10,2), CONSTRAINT Orders_pk PRIMARY KEY (OrderId), CONSTRAINT Orders_Users_fk Foreign Key(UserId) REFERENCES Users(UserId));
BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_create(read('test_3.xml')));
END;
CREATE TABLE Products( ProductId NUMBER,  ProductName VARCHAR(2) NOT NULL ,  UserAge NUMBER(10,2) NOT NULL , CONSTRAINT Products_pk PRIMARY KEY (ProductId));

BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_insert(read('insert_test_1.xml')));
END;

INSERT INTO Users(UserId, UserName, UserAge) VALUES (1, 'John', 3);
INSERT INTO Users(UserId, UserName, UserAge) VALUES (2, 'Alice', 25);
INSERT INTO Users(UserId, UserName, UserAge) VALUES (3, 'Bob', 35);

BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_insert(read('insert_test_2.xml')));
END;
INSERT INTO Orders(OrderId, UserId, OrderDate, TotalAmount) VALUES (1, 1, TO_DATE('2024-01-15', 'YYYY-MM-DD'), 100.00);
INSERT INTO Orders(OrderId, UserId, OrderDate, TotalAmount) VALUES (2, 2, TO_DATE('2024-02-20', 'YYYY-MM-DD'), 150.00);
INSERT INTO Orders(OrderId, UserId, OrderDate, TotalAmount) VALUES (3, 3, TO_DATE('2024-03-25', 'YYYY-MM-DD'), 200.00);

INSERT INTO Products (ProductID, ProductName, Price) VALUES (101, 'Product A', 50.00);
INSERT INTO Products (ProductID, ProductName, Price) VALUES (102, 'Product B', 75.00);
INSERT INTO Products (ProductID, ProductName, Price) VALUES (103, 'Product C', 100.00);

DECLARE
    v_sql VARCHAR2(4000);
    cur sys_refcursor;
BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_select(DBMS_LOB.SUBSTR(read('test_4.xml'), 4000)));
    v_sql := xml_package.xml_select(DBMS_LOB.SUBSTR(read('test_4.xml'), 4000));
    open cur for v_sql;
    DBMS_SQL.RETURN_RESULT(cur);
END;

select * from users;
UPDATE Users SET UserName = 'Lola' WHERE Users.UserId = 2 OR  Users.UserName = 'Alice'  ;


CREATE SEQUENCE t1_pk_seq;
CREATE OR REPLACE TRIGGER t1 BEFORE INSERT ON t1 FOR EACH ROW 
BEGIN 
 IF inserting THEN 
 IF :NEW.ID IS NULL THEN 
 SELECT t1_pk_seq.nextval INTO :NEW.ID FROM dual; 
 END IF; 
 END IF; 
END;