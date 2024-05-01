DROP TYPE xml_record;
CREATE TYPE xml_record IS TABLE OF VARCHAR2(1000);

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

BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_create(read('test_2.xml')));
END;

BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_create(read('test_3.xml')));
END;

BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_insert(read('insert_test_1.xml')));
END;

BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_insert(read('insert_test_2.xml')));
END;

DECLARE
    v_sql VARCHAR2(4000);
    cur sys_refcursor;
BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_select(DBMS_LOB.SUBSTR(read('test_4.xml'), 4000)));
    v_sql := xml_package.xml_select(DBMS_LOB.SUBSTR(read('test_4.xml'), 4000));
    open cur for v_sql;
    DBMS_SQL.RETURN_RESULT(cur);
END;

BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_create(read('create_t1.xml')));
END;
BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_create(read('create_t2.xml')));
END;
BEGIN
    DBMS_OUTPUT.put_line(xml_package.xml_select(read('select_task.xml')));
END;