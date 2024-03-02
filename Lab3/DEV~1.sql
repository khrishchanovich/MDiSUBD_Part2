DROP TABLE diff_tables;
DROP TABLE out_tables;

-- store 'list' of tables with differences in schemas
CREATE TABLE diff_tables (
    name VARCHAR2(100) NOT NULL,
    description VARCHAR2(100)
);

-- store 'list' of tables without differences
CREATE TABLE out_tables (
    name VARCHAR2(100) NOT NULL,
    description VARCHAR2(100)
);

CREATE OR REPLACE PROCEDURE compare_schemas(
    dev_schema_name IN VARCHAR2,
    prod_schema_name IN VARCHAR2
)
IS 
    tables_count NUMBER;
    columns_count NUMBER;

    ref_table VARCHAR2(100);
    ref_constraint VARCHAR2(100);
    ref_tables_count NUMBER;

    is_ref BOOLEAN := TRUE;

    obj_count NUMBER;
    f1_arg_count NUMBER;
    f2_arg_count NUMBER;
    arg_count NUMBER;

    is_exists BOOLEAN;
BEGIN
    dbms_output.put_line('_______________ Tables Info _______________');
    dbms_output.put_line(' ');
    -- get number of tables in Dev-schema
    SELECT COUNT(*) INTO tables_count FROM ALL_TABLES WHERE OWNER = dev_schema_name;

    -- if there are no tables in Dev-schema -> STOP
    IF tables_count = 0 THEN
        dbms_output.put_line('Schema ' || dev_schema_name || ' does not contain tables.');
        -- RAISE_APPLICATION_ERROR(-20002, 'Schema ' || dev_schema_name || ' does not contain tables.');
    ELSE
         -- get list of tables in dev-schema
        FOR tab IN (SELECT * FROM all_tables WHERE owner=dev_schema_name)
        LOOP
            -- get number of tables with same name in Prod-schema
            SELECT COUNT(*) INTO tables_count FROM all_tables WHERE owner=prod_schema_name AND table_name=tab.table_name;
        
            -- table is exists in prod-schema?
            IF tables_count = 1 THEN
                FOR col IN (SELECT * FROM all_tab_columns WHERE table_name=tab.table_name AND owner=dev_schema_name)
                LOOP
                    SELECT COUNT(*) INTO columns_count FROM all_tab_columns WHERE owner=prod_schema_name AND
                                                                                  column_name=col.column_name AND
                                                                                  data_type=col.data_type AND
                                                                                  data_length=col.data_length AND
                                                                                  nullable=col.nullable;

                    IF columns_count = 0 THEN
                    -- -> tables structure is different
                        INSERT INTO diff_tables VALUES(tab.table_name, 'structure');
                    END IF;
                    EXIT WHEN columns_count=0;
                END LOOP;
            ELSE
                INSERT INTO diff_tables VALUES (tab.table_name, 'not exists');
            END IF;
        END LOOP;

        -- check fk & cycle 
        SELECT COUNT(*) INTO tables_count FROM diff_tables;

        WHILE tables_count != 0
        LOOP
            FOR tab IN (SELECT * FROM diff_tables) LOOP
                FOR fk IN (SELECT * FROM all_constraints WHERE owner=dev_schema_name AND 
                                            table_name=tab.name AND constraint_type='R')
                LOOP
                    check_cycle(fk.r_constraint_name, dev_schema_name, fk.table_name);

                    SELECT table_name INTO ref_table FROM all_constraints 
                        WHERE constraint_name=fk.r_constraint_name;

                    SELECT COUNT(*) INTO ref_tables_count FROM out_tables WHERE name=ref_table;

                    IF ref_tables_count = 0 THEN
                        is_ref := FALSE;
                    END IF;
                END LOOP;

                IF is_ref THEN
                    DELETE FROM diff_tables WHERE name=tab.name;
                    INSERT INTO out_tables VALUES(tab.name, tab.description);
                END IF;

                is_ref := TRUE;

            END LOOP;

            SELECT COUNT(*) INTO tables_count FROM diff_tables;

        END LOOP;

        SELECT COUNT(*) INTO tables_count FROM out_tables;

        IF tables_count = 0 THEN
            dbms_output.put_line('There are no differences!');
        ELSE
            FOR tab IN (SELECT * FROM out_tables) LOOP
                dbms_output.put_line(tab.name || ' - ' || tab.description);
            END LOOP;
        END IF;
    END IF;

    -- task 2
    dbms_output.put_line(' ');
    dbms_output.put_line('_____________ Procedures Info _____________');
    dbms_output.put_line(' ');
    -- get number of procedures in Dev-schema
    SELECT COUNT(*) INTO obj_count FROM all_objects WHERE owner=dev_schema_name AND object_type='PROCEDURE';
    
    -- if there are no procedures in Dev-schema -> STOP
    IF obj_count = 0 THEN
        -- RAISE_APPLICATION_ERROR(-20002, 'Schema ' || dev_schema_name || ' does not contain procedures.');
        dbms_output.put_line('Schema ' || dev_schema_name || ' does not contain procedures.');
    ELSE
        FOR proc IN (SELECT * FROM all_objects WHERE owner=dev_schema_name AND object_type='PROCEDURE')
        LOOP
            SELECT COUNT(*) INTO obj_count FROM all_objects WHERE owner=prod_schema_name AND 
                                object_type='PROCEDURE' AND object_name=proc.object_name;

            IF obj_count = 0 THEN
                dbms_output.put_line(proc.object_name || ' not exists in Prod-schema');
            ELSE
                SELECT COUNT(*) INTO f1_arg_count FROM all_arguments WHERE owner=dev_schema_name AND object_name=proc.object_name;
                SELECT COUNT(*) INTO f2_arg_count FROM all_arguments WHERE owner=prod_schema_name AND object_name=proc.object_name;

                IF f1_arg_count != f2_arg_count THEN
                    dbms_output.put_line(proc.object_name || ' has different arguments');
                ELSE
                    FOR arg IN (SELECT * FROM all_arguments WHERE owner=dev_schema_name AND object_name=proc.object_name)
                    LOOP
                        SELECT COUNT(*) INTO arg_count FROM all_arguments WHERE owner=prod_schema_name AND 
                                                object_name=proc.object_name AND data_type=arg.data_type;

                        IF arg_count = 0 THEN
                            dbms_output.put_line(proc.object_name || ' has different arguments data types');
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        END LOOP;
    END IF;

    dbms_output.put_line(' ');
    dbms_output.put_line('_____________ Functions  Info _____________');
    dbms_output.put_line(' ');
    -- get number of functions in Dev-schema
    SELECT COUNT(*) INTO obj_count FROM all_objects WHERE owner=dev_schema_name AND object_type='FUNCTION';
    
    -- if there are no functions in Dev-schema -> STOP
    IF obj_count = 0 THEN
        -- RAISE_APPLICATION_ERROR(-20002, 'Schema ' || dev_schema_name || ' does not contain functions.');
        dbms_output.put_line('Schema ' || dev_schema_name || ' does not contain functions.');
    ELSE
        FOR func IN (SELECT * FROM all_objects WHERE owner=dev_schema_name AND object_type='FUNCTION')
        LOOP
            SELECT COUNT(*) INTO obj_count FROM all_objects WHERE owner=prod_schema_name AND 
                                object_type='FUNCTION' AND object_name=func.object_name;

            IF obj_count = 0 THEN
                dbms_output.put_line(func.object_name || ' not exists in Prod-schema');
            ELSE
                SELECT COUNT(*) INTO f1_arg_count FROM all_arguments WHERE owner=dev_schema_name AND object_name=func.object_name;
                SELECT COUNT(*) INTO f2_arg_count FROM all_arguments WHERE owner=prod_schema_name AND object_name=func.object_name;

                IF f1_arg_count != f2_arg_count THEN
                    dbms_output.put_line(func.object_name || ' has different arguments');
                ELSE
                    FOR arg IN (SELECT * FROM all_arguments WHERE owner=dev_schema_name AND object_name=func.object_name)
                    LOOP
                        IF arg.position = 0 THEN  -- return value?
                            SELECT COUNT(*) INTO arg_count FROM all_arguments WHERE owner=prod_schema_name AND 
                                                object_name=func.object_name AND data_type=arg.data_type AND position=0;

                            IF arg_count = 0 THEN
                                dbms_output.put_line(func.object_name || ' has different arguments data types');
                            END IF;
                        ELSE
                            SELECT COUNT(*) INTO arg_count FROM all_arguments WHERE owner=prod_schema_name AND 
                                                object_name=func.object_name AND data_type=arg.data_type;

                            IF arg_count = 0 THEN
                                dbms_output.put_line(func.object_name || ' has different arguments data types');
                            END IF;
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        END LOOP;
    END IF;

    dbms_output.put_line(' ');
    dbms_output.put_line('______________ Packages  Info _____________');
    dbms_output.put_line(' ');
    -- get number of indexes in Dev-schema
    SELECT COUNT(*) INTO obj_count FROM all_ind_columns WHERE index_owner=dev_schema_name; -- AND object_type='PACKAGE';
    
    -- if there are no packages in Dev-schema -> STOP
    IF obj_count = 0 THEN
        -- RAISE_APPLICATION_ERROR(-20002, 'Schema ' || dev_schema_name || ' does not contain procedures.');
        dbms_output.put_line('Schema ' || dev_schema_name || ' does not contain package indexes.');
    ELSE
        FOR dev_index IN (SELECT * FROM all_ind_columns WHERE index_owner=dev_schema_name)
        LOOP
            is_exists := FALSE;
            SELECT COUNT(*) INTO obj_count FROM all_ind_columns WHERE index_owner=prod_schema_name;

            IF obj_count = 0 THEN
                dbms_output.put_line('Index ' || dev_index.index_name || ' not exists in Prod-schema');
            ELSE
                FOR prod_index IN (SELECT * FROM all_ind_columns WHERE index_owner=prod_schema_name)
                LOOP
                    IF dev_index.index_name = prod_index.index_name THEN
                        IF dev_index.table_name = prod_index.table_name THEN
                            IF dev_index.column_name = prod_index.column_name THEN
                                is_exists := TRUE;
                            END IF;
                        END IF; 
                    END IF;
                END LOOP;

                IF is_exists = FALSE THEN
                    IF SUBSTR(dev_index.index_name, 1, 3) != 'BIN' AND
                        SUBSTR(dev_index.index_name, 1, 3) != 'SYS' THEN
                        dbms_output.put_line('Index ' || dev_index.index_name || ' not exists in Prod-schema');
                    END IF;
                END IF;
            END IF;
        END LOOP;
    END IF;

    dbms_output.put_line(' ');
    dbms_output.put_line(' ');

    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('ERROR | ' || SQLERRM);

END compare_schemas;

CREATE OR REPLACE PROCEDURE check_cycle (
    ref_constraint_name IN VARCHAR2,
    dev_schema_name IN VARCHAR2,
    start_table_name IN VARCHAR2,
    cur_table_name IN VARCHAR2 DEFAULT NULL
)
IS 
    ref_table_name VARCHAR2(100);
BEGIN
    IF cur_table_name IS NULL THEN
        SELECT table_name INTO ref_table_name FROM all_constraints 
            WHERE constraint_name=ref_constraint_name;
    ELSE
        SELECT table_name INTO ref_table_name FROM all_constraints 
            WHERE constraint_name=ref_constraint_name AND table_name!=cur_table_name;
    END IF;

    IF ref_table_name = start_table_name THEN
        RAISE_APPLICATION_ERROR(-20003, 'Loop detected in foreign keys for table ' || dev_schema_name ||
                '.' || start_table_name || '!');
    ELSE
        FOR fk IN (SELECT * FROM all_constraints WHERE owner=dev_schema_name AND table_name=ref_table_name AND constraint_type='R')
        LOOP
            check_cycle(fk.r_constraint_name, dev_schema_name, start_table_name, ref_table_name);
        END LOOP;
    END IF;
END check_cycle;

-- task 3
CREATE OR REPLACE PROCEDURE replace_object (
    dev_schema_name IN VARCHAR2, 
    prod_schema_name IN VARCHAR2, 
    object_type IN VARCHAR2, 
    object_name IN VARCHAR2
) 
AS
    query_string VARCHAR2(1000); 
BEGIN
    FOR src IN (SELECT line, text FROM all_source WHERE owner=dev_schema_name AND name=object_name)
    LOOP    
        IF src.line =1 THEN
            query_string := 'CREATE OR REPLACE ' || REPLACE(src.text, LOWER(object_name), prod_schema_name || '.' || object_name);
        ELSE
            query_string := query_string || src.text; 
            END IF;
    END LOOP;
    
    dbms_output.put_line(query_string);
    -- EXECUTE IMMEDIATE query_string; 
END replace_object;


CREATE OR REPLACE PROCEDURE create_object (
    dev_schema_name IN VARCHAR2,
    prod_schema_name IN VARCHAR2,    
    object_type IN VARCHAR2, 
    object_name IN VARCHAR2
) 
AS
    query_string VARCHAR2(1000); 
BEGIN
    FOR src IN (SELECT line, text FROM all_source WHERE owner=dev_schema_name AND NAME=object_name)
    LOOP
        IF src.line =1 THEN
            query_string := 'CREATE ' || REPLACE(src.text, LOWER(object_name), prod_schema_name || '.' || object_name);
        ELSE
            query_string := query_string || src.text; 
        END IF;
    END LOOP;

    dbms_output.put_line(query_string);
    -- EXECUTE IMMEDIATE query_string; 
END create_object;


CREATE OR REPLACE PROCEDURE delete_object (
    schema_name IN VARCHAR2, 
    object_type IN VARCHAR2, 
    object_name IN VARCHAR2
)
AS
    delete_query VARCHAR(1000); 
BEGIN
    delete_query := 'DROP ' || object_type || ' ' || schema_name || '.' || object_name; 
    
    dbms_output.put_line(delete_query);
    -- EXECUTE IMMEDIATE delete_query;
END delete_object;


CREATE OR REPLACE PROCEDURE compare_objects (
    dev_schema_name IN VARCHAR2, 
    prod_schema_name IN VARCHAR2, 
    object_type IN VARCHAR2
) 
AS
    diff NUMBER := 0; 
BEGIN
    FOR pair IN (SELECT obj1.NAME AS name1, obj2.NAME AS name2 FROM
                    (SELECT object_name name FROM all_objects
                        WHERE object_type=object_type AND owner=dev_schema_name) obj1 FULL JOIN
                            (SELECT object_name name FROM all_objects
                                WHERE object_type=object_type AND owner=prod_schema_name) obj2 ON obj1.name=obj2.name ) 
    LOOP
        IF pair.name1 IS NULL THEN
            delete_object(prod_schema_name, object_type, pair.name2); 
        ELSIF pair.name2 IS NULL THEN
            create_object(dev_schema_name, prod_schema_name, object_type, pair.name1); 
        ELSE
            SELECT COUNT(*) INTO diff FROM all_source src1 
                FULL JOIN all_source src2 ON src1.name=src2.name
                    WHERE src1.name=pair.name1 AND src1.line=src2.line AND src1.text!=src2.text
                        AND src1.owner=dev_schema_name AND src2.owner=prod_schema_name;
            
            IF diff > 0 THEN 
                replace_object(dev_schema_name, prod_schema_name, object_type,pair.name1); 
            END IF; 
        END IF;
    END LOOP;
END compare_objects;