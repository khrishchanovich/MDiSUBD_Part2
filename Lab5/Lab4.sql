-- TASK 1
DROP TABLE Groups CASCADE CONSTRAINT;
DROP TABLE Students;
DROP TABLE Classes;

CREATE TABLE Groups (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(20) NOT NULL,
    group_date TIMESTAMP DEFAULT SYSDATE
);
/
CREATE TABLE Students (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(20) NOT NULL,
    group_id NUMBER,

    CONSTRAINT fk_student_to_group FOREIGN KEY(group_id) REFERENCES Groups(id)
);
/
CREATE TABLE Classes (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(20) NOT NULL,
    class_date TIMESTAMP DEFAULT SYSDATE,
    group_id NUMBER,

    CONSTRAINT fk_class_to_group FOREIGN KEY(group_id) REFERENCES Groups(id)
);

select * from groups;

INSERT INTO Groups(name) VALUES('001');
INSERT INTO Groups(name) VALUES('002');

UPDATE GROUPS
SET NAME = '003'
WHERE ID = 3;

UPDATE Groups
SET group_date = SYSTIMESTAMP;

INSERT INTO Groups(name) VALUES('003');
INSERT INTO Groups(name) VALUES('004');
INSERT INTO Groups(name) VALUES('005');
INSERT INTO Groups(name) VALUES('006');
INSERT INTO Groups(name) VALUES('007');
SELECT * FROM Groups;

INSERT INTO Students(name, group_id) VALUES('A', 7);
INSERT INTO Students(name, group_id) VALUES('B', 8);

select * from students;
UPDATE STUDENTS
SET NAME = 'C'
WHERE ID = 3;

INSERT INTO Students(name, group_id) VALUES('C', 2);
INSERT INTO Students(name, group_id) VALUES('D', 1);
INSERT INTO Students(name, group_id) VALUES('E', 2);
INSERT INTO Students(name, group_id) VALUES('F', 1);
INSERT INTO Students(name, group_id) VALUES('G', 1);
INSERT INTO Students(name, group_id) VALUES('R', 3);
SELECT * FROM Students;

INSERT INTO Classes(name, group_id) VALUES('Math', 2);

UPDATE Classes
SET NAME = 'SMTH'
WHERE ID = 1;

INSERT INTO Classes(name, group_id) VALUES('Programming', 1);
INSERT INTO Classes(name, group_id) VALUES('Data Bases', 3);
SELECT * FROM Classes;

-- TASK 2
DROP TABLE History;

CREATE TABLE History ( 
    id NUMBER  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_time TIMESTAMP NOT NULL, 
    description VARCHAR2(10) NOT NULL,
    table_name VARCHAR2(10) NOT NULL,

    -- students
    new_st_name VARCHAR2(20), 
    old_st_name VARCHAR2(20), 
    new_st_group_id NUMBER, 
    old_st_group_id NUMBER,

    -- classes
    new_class_name VARCHAR2(20), 
    old_class_name VARCHAR2(20), 
    new_class_date TIMESTAMP, 
    old_class_date TIMESTAMP, 
    new_class_group_id NUMBER, 
    old_class_group_id NUMBER,

    -- groups
    new_group_name VARCHAR2(20), 
    old_group_name VARCHAR2(20),
    new_group_date TIMESTAMP, 
    old_group_date TIMESTAMP
);

CREATE OR REPLACE TRIGGER students_logger 
    AFTER INSERT OR UPDATE OR DELETE ON Students FOR EACH ROW 
BEGIN
    CASE
        WHEN INSERTING THEN
            INSERT INTO History(date_time, description, table_name, new_st_name, old_st_name, new_st_group_id, old_st_group_id,
                                new_class_name, old_class_name, new_class_date, old_class_date, new_class_group_id, old_class_group_id,
                                new_group_name, old_group_name, new_group_date, old_group_date)
                VALUES (SYSTIMESTAMP, 'INSERTING', 'STUDENTS',
                        :NEW.name, NULL, :NEW.group_id, NULL, 
                        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
                        
        WHEN UPDATING THEN
            INSERT INTO History(date_time, description, table_name, new_st_name, old_st_name, new_st_group_id, old_st_group_id,
                                new_class_name, old_class_name, new_class_date, old_class_date, new_class_group_id, old_class_group_id,
                                new_group_name, old_group_name, new_group_date, old_group_date)
                VALUES (SYSTIMESTAMP, 'UPDATING', 'STUDENTS',
                        :NEW.name, :OLD.name, :NEW.group_id, :OLD.group_id, 
                        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
                        
        WHEN DELETING THEN
            INSERT INTO History(date_time, description, table_name, new_st_name, old_st_name, new_st_group_id, old_st_group_id,
                                new_class_name, old_class_name, new_class_date, old_class_date, new_class_group_id, old_class_group_id,
                                new_group_name, old_group_name, new_group_date, old_group_date)
                VALUES (SYSTIMESTAMP, 'DELETING', 'STUDENTS',
                        NULL, :OLD.name, NULL, :OLD.group_id, 
                        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
    END CASE;
END;
/
CREATE OR REPLACE TRIGGER classes_logger 
    AFTER INSERT OR UPDATE OR DELETE ON Classes FOR EACH ROW 
BEGIN
    CASE
        WHEN INSERTING THEN
            INSERT INTO History(date_time, description, table_name, new_st_name, old_st_name, new_st_group_id, old_st_group_id,
                                new_class_name, old_class_name, new_class_date, old_class_date, new_class_group_id, old_class_group_id,
                                new_group_name, old_group_name, new_group_date, old_group_date)
                VALUES (SYSTIMESTAMP, 'INSERTING', 'CLASSES', NULL, NULL, NULL, NULL,
                        :NEW.name, NULL, :NEW.class_date, NULL, :NEW.group_id, NULL, 
                        NULL, NULL, NULL, NULL);
                        
        WHEN UPDATING THEN
            INSERT INTO History(date_time, description, table_name, new_st_name, old_st_name, new_st_group_id, old_st_group_id,
                                new_class_name, old_class_name, new_class_date, old_class_date, new_class_group_id, old_class_group_id,
                                new_group_name, old_group_name, new_group_date, old_group_date)
                VALUES (SYSTIMESTAMP, 'UPDATING', 'CLASSES', NULL, NULL, NULL, NULL,
                        :NEW.name, :OLD.name, :NEW.class_date, :OLD.class_date, :NEW.group_id, :OLD.group_id,
                        NULL, NULL, NULL, NULL);
                        
        WHEN DELETING THEN
            INSERT INTO History(date_time, description, table_name, new_st_name, old_st_name, new_st_group_id, old_st_group_id,
                                new_class_name, old_class_name, new_class_date, old_class_date, new_class_group_id, old_class_group_id,
                                new_group_name, old_group_name, new_group_date, old_group_date)
                VALUES (SYSTIMESTAMP, 'DELETING', 'CLASSES', NULL, NULL, NULL, NULL,
                        NULL, :OLD.name, NULL, :OLD.class_date, NULL, :OLD.group_id,
                        NULL, NULL, NULL, NULL);
    END CASE;
END;
/
CREATE OR REPLACE TRIGGER groups_logger 
    AFTER INSERT OR UPDATE OR DELETE ON Groups FOR EACH ROW 
BEGIN
    CASE
        WHEN INSERTING THEN
            INSERT INTO History(date_time, description, table_name, new_st_name, old_st_name, new_st_group_id, old_st_group_id,
                                new_class_name, old_class_name, new_class_date, old_class_date, new_class_group_id, old_class_group_id,
                                new_group_name, old_group_name, new_group_date, old_group_date)
                VALUES (SYSTIMESTAMP, 'INSERTING', 'GROUPS',
                        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
                        :NEW.name, NULL, :NEW.group_date, NULL);
                        
        WHEN UPDATING THEN
            INSERT INTO History(date_time, description, table_name, new_st_name, old_st_name, new_st_group_id, old_st_group_id,
                                new_class_name, old_class_name, new_class_date, old_class_date, new_class_group_id, old_class_group_id,
                                new_group_name, old_group_name, new_group_date, old_group_date)
                VALUES (SYSTIMESTAMP, 'UPDATING', 'GROUPS',
                        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
                        :NEW.name, :OLD.name, :NEW.group_date, :OLD.group_date);
                        
        WHEN DELETING THEN
            INSERT INTO History(date_time, description, table_name, new_st_name, old_st_name, new_st_group_id, old_st_group_id,
                                new_class_name, old_class_name, new_class_date, old_class_date, new_class_group_id, old_class_group_id,
                                new_group_name, old_group_name, new_group_date, old_group_date)
                VALUES (SYSTIMESTAMP, 'DELETING', 'GROUPS',
                        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
                        NULL, :OLD.name, NULL, :OLD.group_date);
    END CASE;
END;

SELECT * FROM History;

-- TASK 3
ALTER TRIGGER students_logger DISABLE;
ALTER TRIGGER classes_logger DISABLE;
ALTER TRIGGER groups_logger DISABLE;

ALTER TRIGGER students_logger ENABLE;
ALTER TRIGGER classes_logger ENABLE;
ALTER TRIGGER groups_logger ENABLE;

CREATE OR REPLACE PACKAGE rollback_package
AS
    PROCEDURE rollback_changes (rollback_time IN TIMESTAMP);
    PROCEDURE rollback_changes (rollback_interval IN NUMBER);
END rollback_package;

CREATE OR REPLACE PACKAGE BODY rollback_package
AS
    PROCEDURE restore_students (rec IN History%rowtype)
    IS
    BEGIN
        IF rec.description = 'INSERTING' AND rec.table_name = 'STUDENTS' 
        THEN
            DELETE FROM Students WHERE name=rec.new_st_name;
        ELSIF rec.description = 'UPDATING' AND rec.table_name = 'STUDENTS'  
        THEN
            UPDATE Students SET name=rec.old_st_name, group_id=rec.old_st_group_id
                WHERE name=rec.new_st_name;
        ELSIF rec.description = 'DELETING' AND rec.table_name = 'STUDENTS' 
        THEN
            INSERT INTO Students(name, group_id) VALUES(rec.old_st_name, rec.old_st_group_id);
        END IF;
    END restore_students;

    PROCEDURE restore_classes (rec IN History%rowtype)
    IS
    BEGIN
        IF rec.description = 'INSERTING' AND rec.table_name = 'CLASSES' 
        THEN
            DELETE FROM Classes WHERE name=rec.new_class_name;
        ELSIF rec.description = 'UPDATING' AND rec.table_name = 'CLASSES'  
        THEN
            UPDATE Classes SET name=rec.old_class_name, class_date=rec.old_class_date, group_id=rec.old_class_group_id
                WHERE name=rec.new_class_name;
        ELSIF rec.description = 'DELETING' AND rec.table_name = 'CLASSES' 
        THEN
            INSERT INTO Classes(name, class_date, group_id) VALUES(rec.old_class_name, rec.old_class_date, rec.old_class_group_id);
        END IF;
    END restore_classes;

    PROCEDURE restore_groups (rec IN History%rowtype)
    IS
    BEGIN
        IF rec.description = 'INSERTING' AND rec.table_name = 'GROUPS' 
        THEN
            DELETE FROM Groups WHERE name=rec.new_group_name;
        ELSIF rec.description = 'UPDATING' AND rec.table_name = 'GROUPS'  
        THEN
            UPDATE Groups SET name=rec.old_group_name, group_date=rec.old_group_date
                WHERE name=rec.new_group_name;
        ELSIF rec.description = 'DELETING' AND rec.table_name = 'GROUPS' 
        THEN
            INSERT INTO Groups(name, group_date) VALUES(rec.old_group_name, rec.old_group_date);
        END IF;
    END restore_groups;

    PROCEDURE rollback_changes (rollback_time IN TIMESTAMP)
    IS
        CURSOR hist(h_date History.date_time%TYPE)
        IS
        SELECT * FROM History
        WHERE date_time >= h_date
        ORDER BY id DESC;
    
        min_insert_time TIMESTAMP;
    BEGIN
    
    SELECT MIN(date_time)
    INTO min_insert_time
    FROM History;
    
    IF min_insert_time > rollback_time then
        DELETE FROM STUDENTS;
        DELETE FROM CLASSES;
        DELETE FROM GROUPS;
        DELETE FROM HISTORY;
    ELSE
        for rec in hist(rollback_time)
        LOOP
            IF rec.table_name = 'STUDENTS'
            THEN
                restore_students(rec);
            ELSIF rec.table_name = 'CLASSES'
            THEN
                restore_classes(rec);
            ELSIF rec.table_name = 'GROUPS'
            THEN
                restore_groups(rec);
            END IF;
            
            DELETE FROM History WHERE id=rec.id;
        END LOOP;
    END IF;
    END rollback_changes;


    PROCEDURE rollback_changes (rollback_interval IN NUMBER)
    IS
    BEGIN
        rollback_changes(SYSDATE - NUMTODSINTERVAL(rollback_interval / 1000, 'SECOND'));
    END rollback_changes;
END rollback_package;

-- TASK 4
CREATE OR REPLACE DIRECTORY dir AS 'D:\6 semester\MDiSUBD_Part2\Lab4';

GRANT WRITE ON DIRECTORY dir TO C##LAB4;

DECLARE
    file UTL_FILE.FILE_TYPE;
BEGIN
    file := UTL_FILE.fopen('DIR', 'report.html', 'W');
END;

CREATE OR REPLACE PROCEDURE generate_report (desired_date TIMESTAMP)
IS
    file UTL_FILE.file_type;
    buff VARCHAR(1000);

    students_insert_count number;
    students_delete_count number;
    students_update_count number;

    classes_insert_count number;
    classes_delete_count number;
    classes_update_count number;

    groups_insert_count number;
    groups_delete_count number;
    groups_update_count number;
BEGIN
    file := UTL_FILE.fopen('DIR', 'report.html', 'W');

    IF NOT UTL_FILE.IS_OPEN(file) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error: File report.html does not open!');
    END IF;

    buff := HTF.HTMLOPEN || CHR(10) || HTF.headopen || CHR(10) || HTF.title('Report')
        || CHR(10) || HTF.headclose || CHR(10) ||HTF.bodyopen || CHR(10);

    SELECT COUNT(*) INTO students_insert_count FROM History
        WHERE description = 'INSERTING' AND table_name = 'STUDENTS' AND date_time >= desired_date;

    SELECT COUNT(*) INTO students_update_count FROM History
        WHERE description = 'UPDATING' AND table_name = 'STUDENTS' AND date_time >= desired_date;

    SELECT COUNT(*) INTO students_delete_count FROM History
        WHERE description = 'DELETING' AND table_name = 'STUDENTS' AND date_time >= desired_date;

    SELECT COUNT(*) INTO classes_insert_count FROM History
        WHERE description = 'INSERTING' AND table_name = 'CLASSES' AND date_time >= desired_date;

    SELECT COUNT(*) INTO classes_update_count FROM History
        WHERE description = 'UPDATING' AND table_name = 'CLASSES' AND date_time >= desired_date;

    SELECT COUNT(*) INTO classes_delete_count FROM History
        WHERE description = 'DELETING' AND table_name = 'CLASSES' AND date_time >= desired_date;

    SELECT COUNT(*) INTO groups_insert_count FROM History
        WHERE description = 'INSERTING' AND table_name = 'GROUPS' AND date_time >= desired_date;

    SELECT COUNT(*) INTO groups_update_count FROM History
        WHERE description = 'UPDATING' AND table_name = 'GROUPS' AND date_time >= desired_date;

    SELECT COUNT(*) INTO groups_delete_count FROM History
        WHERE description = 'DELETING' AND table_name = 'GROUPS' AND date_time >= desired_date;

    buff := buff || HTF.TABLEOPEN || CHR(10) || HTF.TABLEROWOPEN || CHR(10) || HTF.TABLEHEADER('') || CHR(10) || HTF.TABLEHEADER('STUDENTS') || CHR(10) ||
    HTF.TABLEHEADER('CLASSES') || CHR(10) || HTF.TABLEHEADER('GROUPS') || CHR(10) || HTF.TABLEROWCLOSE || CHR(10);

    buff := buff || HTF.TABLEROWOPEN || CHR(10) || HTF.TABLEHEADER('INSERTING') || CHR(10) || HTF.TABLEDATA(students_insert_count) || CHR(10) ||
    HTF.TABLEDATA(classes_insert_count) || CHR(10) || HTF.TABLEDATA(groups_insert_count) || CHR(10) || HTF.TABLEROWCLOSE || CHR(10);

    buff := buff || HTF.TABLEROWOPEN || CHR(10) || HTF.TABLEHEADER('UPDATING') || CHR(10) || HTF.TABLEDATA(students_update_count) || CHR(10) ||
    HTF.TABLEDATA(classes_update_count) || CHR(10) || HTF.TABLEDATA(groups_update_count) || CHR(10) || HTF.TABLEROWCLOSE || CHR(10);

    buff := buff || HTF.TABLEROWOPEN || CHR(10) || HTF.TABLEHEADER('DELETING') || CHR(10) || HTF.TABLEDATA(students_delete_count) || CHR(10) ||
    HTF.TABLEDATA(classes_delete_count) || CHR(10) || HTF.TABLEDATA(groups_delete_count) || CHR(10) || HTF.TABLEROWCLOSE || CHR(10);

    buff := buff || HTF.TABLECLOSE || CHR(10) || HTF.bodyclose || CHR(10) || HTF.htmlclose;

    UTL_FILE.put_line (file, buff);
    UTL_FILE.fclose(file);

    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error in generate_report(). NO_DATA_FOUND');
END generate_report;

BEGIN
    generate_report(TO_TIMESTAMP('24-04-27 00:00:00.000000000', 'YYYY-MM-DD HH24:MI:SS.FF9'));
END;

BEGIN
    rollback_package.rollback_changes(120000);
END;

BEGIN
    rollback_package.rollback_changes (TO_TIMESTAMP('24-04-26 00:00:00.000000000', 'YYYY-MM-DD HH24:MI:SS.FF9'));
END;

-- 1 час = 60 мин = 3600 с = 3600 000 мс (в 1 с 1000 мс)

select * from groups;
select * from students;
select * from classes;

declare
    min_insert_time TIMESTAMP;
    time_ TIMESTAMP; -- Добавлена точка с запятой для завершения строки
begin
    SELECT MIN(date_time)
    INTO min_insert_time
    FROM History;
    time_ := TO_TIMESTAMP('24-04-26 00:00:00.000000000', 'YYYY-MM-DD HH24:MI:SS.FF9'); -- Добавлена двоеточие для присвоения значения переменной
    if time_ < min_insert_time then
        dbms_output.put_line(min_insert_time);
    end if;
end;


select * from history;