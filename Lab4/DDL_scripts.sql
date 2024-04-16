CREATE OR REPLACE PACKAGE xml_package AS
    FUNCTION process_select (
        xml_string IN VARCHAR2
    ) RETURN SYS_REFCURSOR;

    FUNCTION xml_select (
        xml_string IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION where_property (
        xml_string IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION xml_insert (
        xml_string IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION xml_update (
        xml_string IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION xml_delete (
        xml_string IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION xml_drop (
        xml_string IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION xml_create (
        xml_string IN VARCHAR2
    ) RETURN NVARCHAR2;

END;

CREATE OR REPLACE FUNCTION auto_increment_generator (
    table_name IN VARCHAR2
) RETURN VARCHAR2 AS
    generated_script VARCHAR(1000);
BEGIN
    generated_script := 'CREATE SEQUENCE '
                        || table_name
                        || '_pk_seq'
                        || ';'
                        || chr(10);

    generated_script := generated_script
                        || 'CREATE OR REPLACE TRIGGER '
                        || table_name
                        || ' BEFORE INSERT ON '
                        || table_name
                        || ' FOR EACH ROW '
                        || chr(10)
                        || 'BEGIN '
                        || chr(10)
                        || ' IF inserting THEN '
                        || chr(10)
                        || ' IF :NEW.ID IS NULL THEN '
                        || chr(10)
                        || ' SELECT '
                        || table_name
                        || '_pk_seq'
                        || '.nextval INTO :NEW.ID FROM dual; '
                        || chr(10)
                        || ' END IF; '
                        || chr(10)
                        || ' END IF; '
                        || chr(10)
                        || 'END;';

    RETURN generated_script;
END;

DECLARE
    v_ddl_script CLOB;
    v_table_name VARCHAR2(100);
    v_generated_script VARCHAR2(1000);
BEGIN
    v_ddl_script := xml_package.xml_create(read('create_t1.xml'));
    v_table_name := SUBSTR(v_ddl_script, INSTR(v_ddl_script, 'CREATE TABLE') + LENGTH('CREATE TABLE') + 1,
                           INSTR(SUBSTR(v_ddl_script, INSTR(v_ddl_script, 'CREATE TABLE') + LENGTH('CREATE TABLE') + 1), '(') - 1);
    v_table_name := TRIM(v_table_name);
    v_generated_script := auto_increment_generator(v_table_name);
    
    DBMS_OUTPUT.put_line(v_ddl_script);
    DBMS_OUTPUT.put_line(v_generated_script);
END;

CREATE OR REPLACE PACKAGE BODY xml_package AS

    FUNCTION process_select (
        xml_string IN VARCHAR2
    ) RETURN SYS_REFCURSOR AS
        cur SYS_REFCURSOR;
    BEGIN
        OPEN cur FOR xml_select(xml_string);

        RETURN cur;
    END process_select;

    FUNCTION xml_select (
        xml_string IN VARCHAR2
    ) RETURN VARCHAR2 AS

        join_type      VARCHAR2(100);
        join_condition VARCHAR2(100);
        select_query   VARCHAR2(1000) := 'SELECT';
        tables_list    xml_record := xml_record();
        columns_list   xml_record := xml_record();
        filters        xml_record := xml_record();
    BEGIN
        IF xml_string IS NULL THEN
            RETURN NULL;
        END IF;
        tables_list := get_record_from_xml(xml_string, 'Operation/Tables/Table');
        columns_list := get_record_from_xml(xml_string, 'Operation/OutputColumns/Column');
        select_query := select_query
                        || ' '
                        || columns_list(1);
        FOR col_index IN 2..columns_list.count LOOP
            select_query := select_query
                            || ', '
                            || columns_list(col_index);
        END LOOP;

        select_query := select_query
                        || ' FROM '
                        || tables_list(1);
        FOR indx IN 2..tables_list.count LOOP
            SELECT
                extractvalue(xmltype(xml_string),
                             'Operation/Joins/Join'
                             || '['
                             ||(indx - 1)
                             || ']/Type')
            INTO join_type
            FROM
                dual;

            SELECT
                extractvalue(xmltype(xml_string),
                             'Operation/Joins/Join'
                             || '['
                             ||(indx - 1)
                             || ']/Condition')
            INTO join_condition
            FROM
                dual;

            select_query := select_query
                            || ' '
                            || join_type
                            || ' '
                            || tables_list(indx)
                            || ' ON '
                            || join_condition;

        END LOOP;

        select_query := select_query || where_property(xml_string); 
        -- DBMS_OUTPUT.PUT_LINE(select_query);

        RETURN select_query;
    END xml_select;

    FUNCTION where_property (
        xml_string IN VARCHAR2
    ) RETURN VARCHAR2 AS

        sub_query          VARCHAR(1000);
        sub_query1         VARCHAR(1000);
        condition_operator VARCHAR(100);
        condition_body     VARCHAR2(100);
        current_record     VARCHAR2(1000);
        where_clouse       VARCHAR2(1000) := ' WHERE';
        i                  NUMBER := 0;
        records_length     NUMBER := 0;
        where_filters      xml_record := xml_record();
        value1             NUMBER;
        value2             NUMBER;
        pattern            VARCHAR2(100);
    BEGIN
        SELECT
            extract(xmltype(xml_string), 'Operation/Where/Conditions/Condition').getstringval()
        INTO current_record
        FROM
            dual;

        WHILE current_record IS NOT NULL LOOP
            i := i + 1;
            records_length := records_length + 1;
            where_filters.extend;
            where_filters(records_length) := trim(current_record);
            SELECT
                extract(xmltype(xml_string), 'Operation/Where/Conditions/Condition'
                                             || '['
                                             || i
                                             || ']').getstringval()
            INTO current_record
            FROM
                dual;

        END LOOP;

        FOR i IN 2..where_filters.count LOOP
            SELECT
                extractvalue(xmltype(where_filters(i)),
                             'Condition/Body')
            INTO condition_body
            FROM
                dual;

            SELECT
                extractvalue(xmltype(where_filters(i)),
                             'Condition/LowerBound')
            INTO value1
            FROM
                dual;

            SELECT
                extractvalue(xmltype(where_filters(i)),
                             'Condition/UpperBound')
            INTO value2
            FROM
                dual;

            SELECT
                extractvalue(xmltype(where_filters(i)),
                             'Condition/Pattern')
            INTO pattern
            FROM
                dual;

            SELECT
                extract(xmltype(where_filters(i)), 'Condition/Operation').getstringval()
            INTO sub_query
            FROM
                dual;

            SELECT
                extractvalue(xmltype(where_filters(i)),
                             'Condition/ConditionOperator')
            INTO condition_operator
            FROM
                dual;

            sub_query1 := xml_select(sub_query);
            IF sub_query1 IS NOT NULL THEN
                sub_query1 := '('
                              || sub_query1
                              || ')';
            END IF;

            -- Условие BETWEEN
            IF condition_operator = 'BETWEEN' THEN
                where_clouse := where_clouse
                                || ' '
                                || condition_body
                                || ' BETWEEN '
                                || value1
                                || ' AND '
                                || value2
                                || ' ';
            -- Условие LIKE
            ELSIF condition_operator = 'LIKE' THEN
                where_clouse := where_clouse
                                || ' '
                                || condition_body
                                || ' LIKE '
                                || ''''
                                || pattern
                                || ''''
                                || ' ';
            ELSE
                where_clouse := where_clouse
                                || ' '
                                || trim(condition_body)
                                || ' '
                                || sub_query1
                                || trim(condition_operator)
                                || ' ';
            END IF;

        END LOOP;

        IF where_filters.count = 0 THEN
            RETURN ' ';
        ELSE
            RETURN where_clouse;
        END IF;
    END where_property;

    FUNCTION xml_insert (
        xml_string IN VARCHAR2
    ) RETURN VARCHAR2 AS

        insert_query           VARCHAR2(1000);
        values_to_insert       VARCHAR2(1000);
        xml_columns            VARCHAR2(200);
        table_name             VARCHAR(100);
        select_query_to_insert VARCHAR(1000);
        xml_values             xml_record := xml_record();
        xml_columns_list       xml_record := xml_record();
    BEGIN
        SELECT
            extract(xmltype(xml_string), 'Operation/Values').getstringval()
        INTO values_to_insert
        FROM
            dual;

        SELECT
            extractvalue(xmltype(xml_string),
                         'Operation/Table')
        INTO table_name
        FROM
            dual;

        xml_columns_list := get_record_from_xml(xml_string, 'Operation/Columns/Column');
        xml_columns := '(' || xml_columns_list(1);
        FOR i IN 2..xml_columns_list.count LOOP
            xml_columns := xml_columns
                           || ', '
                           || xml_columns_list(i);
        END LOOP;

        xml_columns := xml_columns || ')';
        insert_query := 'INSERT INTO '
                        || table_name
                        || xml_columns;
        IF values_to_insert IS NOT NULL THEN
            xml_values := get_record_from_xml(values_to_insert, 'Values/Value');
            insert_query := insert_query
                            || ' VALUES'
                            || ' ('
                            || xml_values(1);
            FOR i IN 2..xml_values.count LOOP
                insert_query := insert_query
                                || ', '
                                || xml_values(i);
            END LOOP;

            insert_query := insert_query || ')';
        ELSE
            SELECT
                extract(xmltype(xml_string), 'Operation/Operation').getstringval()
            INTO select_query_to_insert
            FROM
                dual;

            insert_query := insert_query
                            || ' '
                            || xml_select(select_query_to_insert);
        END IF;

        insert_query := insert_query || ';';
        RETURN insert_query;
    END xml_insert;

    FUNCTION xml_update (
        xml_string IN VARCHAR2
    ) RETURN VARCHAR2 AS

        table_name     VARCHAR(100);
        set_operations VARCHAR2(1000);
        update_query   VARCHAR2(1000) := 'UPDATE ';
        set_collection xml_record := xml_record();
    BEGIN
        SELECT
            extract(xmltype(xml_string), 'Operation/SetOperations').getstringval()
        INTO set_operations
        FROM
            dual;

        SELECT
            extractvalue(xmltype(xml_string),
                         'Operation/Table')
        INTO table_name
        FROM
            dual;

        set_collection := get_record_from_xml(set_operations, 'SetOperations/Set');
        update_query := update_query
                        || table_name
                        || ' SET '
                        || set_collection(1);
        FOR i IN 2..set_collection.count LOOP
            update_query := update_query
                            || ','
                            || set_collection(i);
        END LOOP;

        update_query := update_query || where_property(xml_string);
        update_query := update_query || ';';
        RETURN update_query;
    END xml_update;

    FUNCTION xml_delete (
        xml_string IN VARCHAR2
    ) RETURN VARCHAR2 AS
        table_name   VARCHAR(100);
        delete_query VARCHAR2(1000) := 'DELETE FROM ';
    BEGIN
        SELECT
            extractvalue(xmltype(xml_string),
                         'Operation/Table')
        INTO table_name
        FROM
            dual;

        delete_query := delete_query
                        || table_name
                        || ' '
                        || where_property(xml_string)
                        || ';';

        RETURN delete_query;
    END xml_delete;

    FUNCTION xml_drop (
        xml_string IN VARCHAR2
    ) RETURN VARCHAR2 AS
        table_name VARCHAR2(100);
        drop_query VARCHAR2(1000) := 'DROP TABLE ';
    BEGIN
        SELECT
            extractvalue(xmltype(xml_string),
                         'Operation/Table')
        INTO table_name
        FROM
            dual;

        drop_query := drop_query
                      || table_name
                      || ';';
        RETURN drop_query;
    END xml_drop;

    FUNCTION xml_create (
        xml_string IN VARCHAR2
    ) RETURN NVARCHAR2 AS

        col_type              VARCHAR(100);
        auto_increment_script VARCHAR(1000);
        col_name              VARCHAR2(100);
        parent_table          VARCHAR2(100);
        constraint_value      VARCHAR2(100);
        temporal_string       VARCHAR2(100);
        table_name            VARCHAR2(100);
        current_record        VARCHAR2(1000);
        primary_constraint    VARCHAR2(1000);
        create_query          VARCHAR2(1000) := 'CREATE TABLE';
        i                     NUMBER := 0;
        records_length        NUMBER := 0;
        table_columns         xml_record := xml_record();
        temporal_record       xml_record := xml_record();
        col_constraints       xml_record := xml_record();
        table_constraints     xml_record := xml_record();
    BEGIN
        SELECT
            extractvalue(xmltype(xml_string),
                         'Operation/Table')
        INTO table_name
        FROM
            dual;

        create_query := create_query
                        || ' '
                        || table_name
                        || '(';
        SELECT
            extract(xmltype(xml_string), 'Operation/Columns/Column').getstringval()
        INTO current_record
        FROM
            dual;

        WHILE current_record IS NOT NULL LOOP
            i := i + 1;
            records_length := records_length + 1;
            table_columns.extend;
            table_columns(records_length) := trim(current_record);
            SELECT
                extract(xmltype(xml_string), 'Operation/Columns/Column'
                                             || '['
                                             || i
                                             || ']').getstringval()
            INTO current_record
            FROM
                dual;

        END LOOP;

        FOR i IN 2..table_columns.count LOOP
            constraint_value := '';
            SELECT
                extractvalue(xmltype(table_columns(i)),
                             'Column/Name')
            INTO col_name
            FROM
                dual;

            SELECT
                extractvalue(xmltype(table_columns(i)),
                             'Column/Type')
            INTO col_type
            FROM
                dual;

            col_constraints := get_record_from_xml(table_columns(i), 'Column/Constraints/Constraint');
            FOR i IN 1..col_constraints.count LOOP
                constraint_value := constraint_value
                                    || ' '
                                    || col_constraints(i);
            END LOOP;
    
    -- Добавление пробела, если constraint_value не равно NULL
            IF constraint_value IS NOT NULL THEN
                constraint_value := constraint_value || ' ';
            END IF;
            create_query := create_query
                            || ' '
                            || col_name
                            || ' '
                            || col_type
                            || constraint_value;

            IF i != table_columns.count THEN
                create_query := create_query || ', ';
            END IF;

        END LOOP;

        SELECT
            extract(xmltype(xml_string), 'Operation/TableConstraints/PrimaryKey').getstringval()
        INTO primary_constraint
        FROM
            dual;

        IF primary_constraint IS NOT NULL THEN
            temporal_record := get_record_from_xml(primary_constraint, 'PrimaryKey/Columns/Column');
            temporal_string := temporal_record(1);
            FOR i IN 2..temporal_record.count LOOP
                temporal_string := temporal_string
                                   || ', '
                                   || temporal_record(i);
            END LOOP;

            create_query := create_query
                            || ', CONSTRAINT '
                            || table_name
                            || '_pk '
                            || 'PRIMARY KEY ('
                            || temporal_string
                            || ')';

        ELSE
            auto_increment_script := auto_increment_generator(table_name);
            create_query := create_query || ', ID NUMBER PRIMARY KEY';
        END IF;

        table_constraints := xml_record();
        records_length := 0;
        i := 0;
        SELECT
            extract(xmltype(xml_string), 'Operation/TableConstraints/ForeignKey').getstringval()
        INTO current_record
        FROM
            dual;

        WHILE current_record IS NOT NULL LOOP
            i := i + 1;
            records_length := records_length + 1;
            table_constraints.extend;
            table_constraints(records_length) := trim(current_record);
            SELECT
                extract(xmltype(xml_string), 'Operation/TableConstraints/ForeignKey'
                                             || '['
                                             || i
                                             || ']').getstringval()
            INTO current_record
            FROM
                dual;

        END LOOP;

        FOR i IN 2..table_constraints.count LOOP
            SELECT
                extractvalue(xmltype(table_constraints(i)),
                             'ForeignKey/Parent')
            INTO parent_table
            FROM
                dual;

            temporal_record := get_record_from_xml(table_constraints(i), 'ForeignKey/ChildColumns/Column');
            temporal_string := temporal_record(1);
            FOR i IN 2..temporal_record.count LOOP
                temporal_string := temporal_string
                                   || ', '
                                   || temporal_record(i);
            END LOOP;

            create_query := create_query
                            || ', CONSTRAINT '
                            || table_name
                            || '_'
                            || parent_table
                            || '_fk '
                            || 'Foreign Key'
                            || '('
                            || temporal_string
                            || ') ';

            temporal_record := get_record_from_xml(table_constraints(i), 'ForeignKey/ParentColumns/Column');
            temporal_string := temporal_record(1);
            FOR i IN 2..temporal_record.count LOOP
                temporal_string := temporal_string
                                   || ', '
                                   || temporal_record(i);
            END LOOP;

            create_query := create_query
                            || 'REFERENCES '
                            || parent_table
                            || '('
                            || temporal_string
                            || ')';

        END LOOP;

        create_query := create_query
                        || ');'
                        || auto_increment_script;
        RETURN create_query;
    END xml_create;

END xml_package;