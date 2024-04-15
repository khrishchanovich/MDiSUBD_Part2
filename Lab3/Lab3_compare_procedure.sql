CREATE OR REPLACE PROCEDURE compare_schemas (
    dev  IN VARCHAR2,
    prod IN VARCHAR2
) AS

    TYPE list_objects IS
        TABLE OF VARCHAR2(100);
        
    tables_dev         list_objects := list_objects();
    tables_prod        list_objects := list_objects();
    checked_tables     list_objects := list_objects();
    sorted_tables      list_objects := list_objects();
    proc_dev           list_objects := list_objects();
    proc_prod          list_objects := list_objects();
    proc_only_dev      list_objects := list_objects();
    proc_only_prod     list_objects := list_objects();
    proc_diff          list_objects := list_objects();
    func_dev           list_objects := list_objects();
    func_prod          list_objects := list_objects();
    func_only_dev      list_objects := list_objects();
    func_only_prod     list_objects := list_objects();
    func_diff          list_objects := list_objects();
    idx_dev            list_objects := list_objects();
    idx_prod           list_objects := list_objects();
    idx_only_dev       list_objects := list_objects();
    idx_only_prod      list_objects := list_objects();
    pkg_dev            list_objects := list_objects();
    pkg_prod           list_objects := list_objects();
    pkg_only_dev       list_objects := list_objects();
    pkg_only_prod      list_objects := list_objects();
    pkg_diff           list_objects := list_objects();
    ddl_str            CLOB := '';
    counter            NUMBER;

    -- Сравнение структур таблиц
    FUNCTION compare_structure (
        p_table_name IN VARCHAR2
    ) RETURN BOOLEAN IS
        is_compare  BOOLEAN := TRUE;
        dev_cnstrt  list_objects;
        prod_cnstrt list_objects;
        dev_clmn    list_objects;
        prod_clmn   list_objects;
    BEGIN
        -- Получаем ограничения
        SELECT
            constraint_name
        BULK COLLECT
        INTO dev_cnstrt
        FROM
            all_constraints
        WHERE
                owner = dev
            AND table_name = p_table_name
            AND constraint_name NOT LIKE 'SYS%'
        ORDER BY
            constraint_name;

        SELECT
            constraint_name
        BULK COLLECT
        INTO prod_cnstrt
        FROM
            all_constraints
        WHERE
                owner = prod
            AND table_name = p_table_name
            AND constraint_name NOT LIKE 'SYS%'
        ORDER BY
            constraint_name;

        -- Получаем название таблиц
        SELECT
            column_name
        BULK COLLECT
        INTO dev_clmn
        FROM
            all_tab_columns
        WHERE
                owner = dev
            AND table_name = p_table_name
            AND column_name NOT LIKE 'SYS%'
        ORDER BY
            column_name;

        SELECT
            column_name
        BULK COLLECT
        INTO prod_clmn
        FROM
            all_tab_columns
        WHERE
                owner = prod
            AND table_name = p_table_name
            AND column_name NOT LIKE 'SYS%'
        ORDER BY
            column_name;
            
            
        -- Находим разницу между множествами
        is_compare := TRUE;
        IF dev_cnstrt MULTISET EXCEPT prod_cnstrt IS NOT EMPTY OR prod_cnstrt MULTISET EXCEPT dev_cnstrt IS NOT EMPTY THEN
            is_compare := FALSE;
        END IF;

        IF dev_clmn MULTISET EXCEPT prod_clmn IS NOT EMPTY OR prod_clmn MULTISET EXCEPT dev_clmn IS NOT EMPTY THEN
            is_compare := FALSE;
        END IF;

        IF is_compare THEN
            RETURN is_compare;
        END IF;
        
        -- Составляем ddl-скрипт
        ddl_str := '';
        DECLARE
            data_type      VARCHAR2(100);
            data_length    NUMBER;
            data_precision NUMBER;
        BEGIN
            FOR i IN 1..dev_clmn.count LOOP
                IF dev_clmn(i) NOT MEMBER OF prod_clmn THEN
                    SELECT
                        data_type,
                        data_length,
                        data_precision
                    INTO
                        data_type,
                        data_length,
                        data_precision
                    FROM
                        all_tab_columns
                    WHERE
                            owner = dev
                        AND table_name = p_table_name
                        AND column_name = dev_clmn(i);

                    ddl_str := ddl_str
                               || 'ALTER TABLE '
                               || p_table_name
                               || ' ADD COLUMN '
                               || dev_clmn(i)
                               || ' '
                               || data_type;

                    IF
                        data_type IN ( 'VARCHAR2', 'NVARCHAR2', 'RAW' )
                        AND data_length IS NOT NULL
                    THEN
                        ddl_str := ddl_str
                                   || '('
                                   || data_length
                                   || ')';
                    ELSIF
                        data_type IN ( 'NUMBER' )
                        AND data_precision IS NOT NULL
                    THEN
                        ddl_str := ddl_str
                                   || '('
                                   || data_precision
                                   || ')';
                    END IF;

                    ddl_str := ddl_str || chr(10);
                END IF;
            END LOOP;
        END;

        FOR i IN 1..dev_cnstrt.count LOOP
            IF dev_cnstrt(i) NOT MEMBER OF prod_cnstrt THEN
                DECLARE
                    ddl_str         CLOB;
                    constraint_type VARCHAR2(20);
                BEGIN
                    SELECT
                        constraint_type
                    INTO constraint_type
                    FROM
                        all_constraints
                    WHERE
                            owner = dev
                        AND table_name = p_table_name
                        AND constraint_name = dev_cnstrt(i);

                    ddl_str := ddl_str
                               || dbms_metadata.get_ddl(
                                                       CASE
                                                           WHEN constraint_type = 'R' THEN
                                                               'REF_CONSTRAINT'
                                                           ELSE 'CONSTRAINT'
                                                       END, dev_cnstrt(i), dev);

                    ddl_str := ddl_str || chr(10);
                END;

            END IF;
        END LOOP;

        FOR i IN 1..prod_clmn.count LOOP
            IF prod_clmn(i) NOT MEMBER OF dev_clmn THEN
                ddl_str := ddl_str
                           || 'ALTER TABLE '
                           || prod
                           || '.'
                           || p_table_name
                           || ' DROP COLUMN '
                           || prod_clmn(i)
                           || ';'
                           || chr(10);

            END IF;
        END LOOP;

        FOR i IN 1..prod_cnstrt.count LOOP
            IF prod_clmn(i) NOT MEMBER OF dev_cnstrt THEN
                ddl_str := ddl_str
                           || 'ALTER TABLE '
                           || prod
                           || '.'
                           || p_table_name
                           || ' DROP CONSTRAINT '
                           || prod_cnstrt(i)
                           || ';'
                           || chr(10);

            END IF;
        END LOOP;

        dbms_output.put_line('DDL-script for updating table '
                             || p_table_name
                             || ' {'
                             || chr(10));

        ddl_str := replace(ddl_str, dev, prod);
        dbms_output.put_line(ddl_str);
        RETURN is_compare;
    END compare_structure;

    PROCEDURE dfs_sort (
        p_table_name IN VARCHAR2
    ) IS

        CURSOR fk_cur IS
        SELECT
            cc.table_name AS child_table
        FROM
                 all_constraints pc
            JOIN all_constraints cc ON pc.constraint_name = cc.r_constraint_name
        WHERE
                pc.constraint_type = 'P'
            AND cc.constraint_type = 'R'
            AND pc.owner = dev
            AND cc.owner = dev
            AND pc.table_name = p_table_name;

        v_child_table VARCHAR2(100);
    BEGIN
        IF p_table_name NOT MEMBER OF checked_tables THEN
            checked_tables.extend;
            checked_tables(checked_tables.last) := p_table_name;
            FOR fk_rec IN fk_cur LOOP
                v_child_table := fk_rec.child_table;
                dfs_sort(v_child_table);
            END LOOP;

            sorted_tables.extend;
            sorted_tables(sorted_tables.last) := p_table_name;
        END IF;
    END dfs_sort;

BEGIN
    SELECT
        table_name
    BULK COLLECT
    INTO tables_dev
    FROM
        all_tables
    WHERE
        owner = dev;

    SELECT
        table_name
    BULK COLLECT
    INTO tables_prod
    FROM
        all_tables
    WHERE
        owner = prod;

    FOR i IN 1..tables_dev.count LOOP
        dfs_sort(tables_dev(i));
    END LOOP;

    SELECT
    COUNT(*)
INTO counter
FROM
    (
        WITH table_hierarchy AS (
            SELECT
                child_owner,
                child_table,
                parent_owner,
                parent_table
            FROM
                     (
                    SELECT
                        owner             AS child_owner,
                        table_name        AS child_table,
                        r_owner           AS parent_owner,
                        r_constraint_name AS constraint_name
                    FROM
                        all_constraints
                    WHERE
                            constraint_type = 'R'
                        AND owner = dev
                )
                JOIN (
                    SELECT
                        owner      AS parent_owner,
                        constraint_name,
                        table_name AS parent_table
                    FROM
                        all_constraints
                    WHERE
                            constraint_type = 'P'
                        AND owner = dev
                ) USING ( parent_owner,
                          constraint_name )
        )
        SELECT DISTINCT
            child_owner,
            child_table
        FROM
            (
                SELECT
                    *
                FROM
                    table_hierarchy
                WHERE
                    ( child_owner, child_table ) IN (
                        SELECT
                            parent_owner, parent_table
                        FROM
                            table_hierarchy
                    )
            ) a
        WHERE
            CONNECT_BY_ISCYCLE = 1
        CONNECT BY NOCYCLE
            ( PRIOR child_owner,
              PRIOR child_table ) = ( ( parent_owner,
                                        parent_table ) )
    );

IF counter > 0 THEN
    dbms_output.put_line(counter || ' ' ||' Loop connections detected.');
ELSE
    dbms_output.put_line('No loop connections detected.');
END IF;

    dbms_output.put_line('********************');
    dbms_output.put_line(chr(10)
                         || 'Table in DEV but not in PROD or with different structure');                     
    dbms_output.put_line('********************');
    ddl_str := '';
    FOR i IN REVERSE 1..sorted_tables.count LOOP
        IF sorted_tables(i) NOT MEMBER OF tables_prod THEN
            dbms_output.put_line(dbms_metadata.get_ddl('TABLE', sorted_tables(i), dev)
                                 || chr(10));

        ELSIF NOT compare_structure(sorted_tables(i)) THEN
            dbms_output.put_line(sorted_tables(i)
                                 || ' }'
                                 || chr(10));
        END IF;
    END LOOP;

    ddl_str := replace(ddl_str, dev, prod);
    dbms_output.put_line(ddl_str);
    
    dbms_output.put_line('********************');
    dbms_output.put_line(chr(10) || 'Tables only in PROD');
    dbms_output.put_line('********************');
    FOR i IN 1..tables_prod.COUNT LOOP
        IF tables_prod(i) NOT MEMBER OF tables_dev THEN
            dbms_output.put_line('DROP TABLE ' || prod || '.' || tables_prod(i) || ';');
        END IF;
    END LOOP;

    --compare_packages;

    SELECT
        object_name
    BULK COLLECT
    INTO proc_dev
    FROM
        all_objects
    WHERE
            object_type = 'PROCEDURE'
        AND owner = dev;

    SELECT
        object_name
    BULK COLLECT
    INTO proc_prod
    FROM
        all_objects
    WHERE
            object_type = 'PROCEDURE'
        AND owner = prod;

    FOR i IN 1..proc_dev.count LOOP
        IF proc_dev(i) MEMBER OF proc_prod THEN
            SELECT
                COUNT(*)
            INTO counter
            FROM
                (
                    SELECT
                        argument_name,
                        position,
                        data_type,
                        in_out
                    FROM
                        all_arguments
                    WHERE
                            owner = dev
                        AND object_name = proc_dev(i)
                    MINUS
                    SELECT
                        argument_name,
                        position,
                        data_type,
                        in_out
                    FROM
                        all_arguments
                    WHERE
                            owner = prod
                        AND object_name = proc_dev(i)
                    UNION ALL
                    SELECT
                        argument_name,
                        position,
                        data_type,
                        in_out
                    FROM
                        all_arguments
                    WHERE
                            owner = prod
                        AND object_name = proc_dev(i)
                    MINUS
                    SELECT
                        argument_name,
                        position,
                        data_type,
                        in_out
                    FROM
                        all_arguments
                    WHERE
                            owner = dev
                        AND object_name = proc_dev(i)
                );

            IF counter > 0 THEN
                proc_diff.extend;
                proc_diff(proc_diff.last) := proc_dev(i);
            END IF;

        END IF;
    END LOOP;

    proc_only_dev := proc_dev MULTISET EXCEPT proc_prod;
    proc_only_prod := proc_prod MULTISET EXCEPT proc_dev;
    dbms_output.put_line('********************');
    dbms_output.put_line('Only DEV procedures');
    dbms_output.put_line('********************');
    ddl_str := '';
    FOR i IN 1..proc_only_dev.count LOOP
        ddl_str := ddl_str
                   || dbms_metadata.get_ddl('PROCEDURE', proc_only_dev(i), dev);
    END LOOP;

    ddl_str := replace(ddl_str, dev, prod);
    dbms_output.put_line(ddl_str);
    dbms_output.put_line('********************');
    dbms_output.put_line('Only PROD procedures');
    dbms_output.put_line('********************');
    ddl_str := '';
    FOR i IN 1..proc_only_prod.count LOOP
        --ddl_str := ddl_str
        --           || dbms_metadata.get_ddl('PROCEDURE', proc_only_prod(i), prod);
        dbms_output.put_line('DROP PROCEDURE ' || prod || '.' || proc_only_prod(i) || ';');
    END LOOP;

    ddl_str := replace(ddl_str, dev, prod);
    dbms_output.put_line(ddl_str);
    dbms_output.put_line('********************');
    dbms_output.put_line(chr(10)
                         || 'Procedures that have different parameters');
    dbms_output.put_line('********************');
    ddl_str := '';
    FOR i IN 1..proc_diff.count LOOP
        ddl_str := ddl_str
                   || 'DROP PROCEDURE'
                   || ' '
                   || prod
                   || '.'
                   || proc_diff(i)
                   || ';';

        ddl_str := ddl_str
                   || dbms_metadata.get_ddl('PROCEDURE', proc_diff(i), dev);

    END LOOP;

    ddl_str := replace(ddl_str, dev, prod);
    dbms_output.put_line(ddl_str);

    SELECT
        object_name
    BULK COLLECT
    INTO func_dev
    FROM
        all_objects
    WHERE
            object_type = 'FUNCTION'
        AND owner = dev;

    SELECT
        object_name
    BULK COLLECT
    INTO func_prod
    FROM
        all_objects
    WHERE
            object_type = 'FUNCTION'
        AND owner = prod;

    FOR i IN 1..func_dev.count LOOP
        IF func_dev(i) MEMBER OF func_prod THEN
            SELECT
                COUNT(*)
            INTO counter
            FROM
                (
                    SELECT
                        argument_name,
                        position,
                        data_type,
                        in_out
                    FROM
                        all_arguments
                    WHERE
                            owner = dev
                        AND object_name = func_dev(i)
                    MINUS
                    SELECT
                        argument_name,
                        position,
                        data_type,
                        in_out
                    FROM
                        all_arguments
                    WHERE
                            owner = prod
                        AND object_name = func_dev(i)
                    UNION ALL
                    SELECT
                        argument_name,
                        position,
                        data_type,
                        in_out
                    FROM
                        all_arguments
                    WHERE
                            owner = prod
                        AND object_name = func_dev(i)
                    MINUS
                    SELECT
                        argument_name,
                        position,
                        data_type,
                        in_out
                    FROM
                        all_arguments
                    WHERE
                            owner = dev
                        AND object_name = func_dev(i)
                );

            IF counter > 0 THEN
                func_diff.extend;
                func_diff(func_diff.last) := func_dev(i);
            END IF;

        END IF;
    END LOOP;

    func_only_dev := func_dev MULTISET EXCEPT func_prod;
    func_only_prod := func_prod MULTISET EXCEPT func_dev;
    dbms_output.put_line('********************');
    dbms_output.put_line('Only DEV functions');
    dbms_output.put_line('********************');
    ddl_str := '';
    FOR i IN 1..func_only_dev.count LOOP
        ddl_str := ddl_str
                   || dbms_metadata.get_ddl('FUNCTION', func_only_dev(i), dev);
    END LOOP;

    ddl_str := replace(ddl_str, dev, prod);
    dbms_output.put_line(ddl_str);
    dbms_output.put_line('********************');
    dbms_output.put_line('Only PROD functions');
    dbms_output.put_line('********************');
    ddl_str := '';
    FOR i IN 1..func_only_prod.count LOOP
        --ddl_str := ddl_str
         --          || dbms_metadata.get_ddl('FUNCTION', func_only_prod(i), prod);
         dbms_output.put_line('DROP FUNCTION ' || prod || '.' || func_only_prod(i) || ';');
    END LOOP;

    ddl_str := replace(ddl_str, dev, prod);
    dbms_output.put_line(ddl_str);
    dbms_output.put_line('********************');
    dbms_output.put_line(chr(10)
                         || 'Functions that have different parameters');
    dbms_output.put_line('********************');
    ddl_str := '';
    FOR i IN 1..func_diff.count LOOP
        ddl_str := ddl_str
                   || 'DROP FUNCTION'
                   || ' '
                   || prod
                   || '.'
                   || func_diff(i)
                   || ';';

        ddl_str := ddl_str
                   || dbms_metadata.get_ddl('FUNCTION', func_diff(i), dev);

    END LOOP;

    ddl_str := replace(ddl_str, dev, prod);
    dbms_output.put_line(ddl_str);

    SELECT
        index_name
    BULK COLLECT
    INTO idx_dev
    FROM
        all_indexes
    WHERE
            owner = dev
         AND index_name NOT LIKE 'SYS%';

    SELECT
        index_name
    BULK COLLECT
    INTO idx_prod
    FROM
        all_indexes
    WHERE
            owner = prod
        AND index_name NOT LIKE 'SYS%';

    idx_only_dev := idx_dev MULTISET EXCEPT idx_prod;
    idx_only_prod := idx_prod MULTISET EXCEPT idx_dev;
    dbms_output.put_line('********************');
    dbms_output.put_line('Only DEV indexes');
    dbms_output.put_line('********************');
    ddl_str := '';
    FOR i IN 1..idx_only_dev.count LOOP
        ddl_str := ddl_str
                   || dbms_metadata.get_ddl('INDEX', idx_only_dev(i), dev);
    END LOOP;

    ddl_str := replace(ddl_str, dev, prod);
    dbms_output.put_line(ddl_str);
    dbms_output.put_line('********************');
    dbms_output.put_line('Only PROD indexes');
    dbms_output.put_line('********************');
    ddl_str        := '';
    FOR i IN 1..idx_only_prod.count LOOP
        dbms_output.put_line('DROP INDEX '
                             || prod
                             || '.'
                             || idx_only_prod(i)
                             || ';');
    END LOOP;

    ddl_str := replace(ddl_str, dev, prod);
    dbms_output.put_line(ddl_str);
END compare_schemas;
/
