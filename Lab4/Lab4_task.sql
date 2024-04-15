CREATE OR REPLACE PROCEDURE EXEC_QUERY(
    V_JSON_DATA IN CLOB,
    V_CURSOR OUT SYS_REFCURSOR
) AS
    QUERY_TYPE CLOB;
    COLUMNS_LIST CLOB;
    TABLES_LIST CLOB;
    JOIN_CONDITIONS CLOB;
    FILTER_CONDITIONS CLOB;
    DYNAMIC_QUERY CLOB;
BEGIN
    SELECT 
        JSON_VALUE(V_JSON_DATA, '$.query_type'),
        JSON_VALUE(V_JSON_DATA, '$.columns'),
        JSON_VALUE(V_JSON_DATA, '$.tables'),
        JSON_VALUE(V_JSON_DATA, '$.join_conditions'),
        JSON_VALUE(V_JSON_DATA, '$.filter_conditions')
    INTO 
        QUERY_TYPE,
        COLUMNS_LIST,
        TABLES_LIST,
        JOIN_CONDITIONS,
        FILTER_CONDITIONS
    FROM 
        DUAL;

    DYNAMIC_QUERY := 'SELECT ' || COLUMNS_LIST || ' FROM ' || TABLES_LIST;
    
    IF JOIN_CONDITIONS IS NOT NULL THEN
        DYNAMIC_QUERY := DYNAMIC_QUERY || ' WHERE ' || JOIN_CONDITIONS;
    END IF;
    
    IF FILTER_CONDITIONS IS NOT NULL THEN
        IF JOIN_CONDITIONS IS NOT NULL THEN
            DYNAMIC_QUERY := DYNAMIC_QUERY || ' AND ' || FILTER_CONDITIONS;
        ELSE
            DYNAMIC_QUERY := DYNAMIC_QUERY || ' WHERE ' || FILTER_CONDITIONS;
        END IF;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE(DYNAMIC_QUERY);

    OPEN V_CURSOR FOR DYNAMIC_QUERY;
END EXEC_QUERY;

