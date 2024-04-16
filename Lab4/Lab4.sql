DROP TYPE xml_record;
CREATE TYPE xml_record IS TABLE OF VARCHAR2(1000);

DROP TABLE Students;
DROP TABLE Groups;

CREATE TABLE Groups (
    id NUMBER PRIMARY KEY NOT NULL,
    name VARCHAR2(20) NOT NULL,
    c_val NUMBER DEFAULT 0 NOT NULL -- number of Students in the group
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
    DBMS_OUTPUT.put_line(xml_package.xml_update(read('update.xml')));
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
    DBMS_OUTPUT.put_line(xml_package.xml_create(read('create_t1.xml')));
END;
CREATE TABLE t1( id NUMBER,  num NUMBER,  var VARCHAR(100), CONSTRAINT t1_pk PRIMARY KEY (id));

BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_create(read('create_t2.xml')));
END;
CREATE TABLE t2( id NUMBER,  num NUMBER,  var VARCHAR(100),  t1_k NUMBER, CONSTRAINT t2_pk PRIMARY KEY (id), CONSTRAINT t2_t1_fk Foreign Key(t1_k) REFERENCES t1(id));

DECLARE
    v_sql VARCHAR2(4000);
    cur sys_refcursor;
BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_select(DBMS_LOB.SUBSTR(read('select_task.xml'), 4000)));
    v_sql := xml_package.xml_select(DBMS_LOB.SUBSTR(read('select_task.xml'), 4000));
    open cur for v_sql;
    DBMS_SQL.RETURN_RESULT(cur);
END;
