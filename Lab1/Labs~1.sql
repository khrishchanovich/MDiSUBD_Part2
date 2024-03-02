DROP TABLE MYTABLE;

-- TASK 1 --
CREATE TABLE mytable (
    id  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    val NUMBER
);

-- TASK 2 --
-- анонимный блок, заполн€ет случайными запис€ми таблицу -- 
DECLARE 
    i NUMBER;
BEGIN 
    FOR i IN 1..10 LOOP
        INSERT INTO mytable (val) values (ROUND(DBMS_RANDOM.VALUE(-100, 100)));
    END LOOP;
END;

SELECT * FROM MYTABLE;

DELETE FROM MYTABLE;

-- TASK 3 --
-- каких значений в таблице больше („ или Ќ„) --
CREATE FUNCTION comparison_function RETURN VARCHAR2 IS
    count_nechet NUMBER;
    count_chet NUMBER;
    text_str VARCHAR2(10); 
BEGIN
    SELECT COUNT(CASE WHEN MOD(val, 2) != 0 THEN 1 END), 
           COUNT(CASE WHEN MOD(val, 2) = 0 THEN 1 END)
    INTO count_nechet, count_chet
    FROM mytable;
    
    IF count_nechet > count_chet THEN
        text_str := 'false';
    ELSIF count_nechet < count_chet THEN
        text_str := 'true';
    ELSE
        text_str := 'equal';
    END IF;
    
    RETURN text_str;
END; 

SELECT comparison_function FROM dual;

-- TASK 4 --
CREATE OR REPLACE FUNCTION insertcommand(input_id NUMBER) RETURN VARCHAR2 IS
    temp_id NUMBER;
    temp_val NUMBER;
    COUNT_ NUMBER;
    text_str VARCHAR2(100);
BEGIN
    SELECT id, val
    INTO temp_id, temp_val
    FROM mytable
    WHERE id = input_id;
    
    text_str := 'INSERT INTO mytabl (id, val) VALUES (' || temp_id || ', ' || temp_val || ')';
    RETURN text_str;    
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'ID DOES NOT EXIST');
END INSERTCOMMAND; 

CREATE OR REPLACE FUNCTION COMM (INPUT_ID NUMBER, INPUT_VALUE NUMBER) RETURN VARCHAR2 IS
    TEMP_ID NUMBER;
    TEMP_VALUE NUMBER;
    TEXT_STR VARCHAR2(100);
    COUNT_ NUMBER;
BEGIN
    SELECT COUNT(*) INTO COUNT_ FROM MYTABLE WHERE ID = INPUT_ID;
    
    IF COUNT_ > 0 then
        RAISE_APPLICATION_ERROR(-20001, 'ID ALREADY EXISTS');
    END IF;
    IF COUNT_ = 0 THEN
        TEXT_STR := 'INSERT INTO mytabl (id, val) VALUES (' || INPUT_ID || ', ' || INPUT_VALUE || ')';
        RETURN TEXT_STR;
    END IF;
END;
SELECT * FROM MYTABLE;
SELECT COMM(10, 10) FROM DUAL;
SELECT insertcommand(12000000) FROM dual;

-- TASK 5 --
CREATE PROCEDURE insertrecord (val IN NUMBER) IS
BEGIN
    INSERT INTO mytable (val) VALUES (val);
END;

CREATE PROCEDURE deleterecord (delete_id IN NUMBER) IS 
BEGIN
    DELETE FROM mytable WHERE id = delete_id;
END;

CREATE PROCEDURE updaterecord (update_id IN NUMBER, update_val IN NUMBER) IS
BEGIN
    UPDATE mytable SET val = update_val WHERE id = update_id;
END;

-- TASK 6 --
-- добавить проверку на строку --
CREATE OR REPLACE FUNCTION CalculateYearlyReward(input_salary IN VARCHAR2, input_annual_percent IN VARCHAR) RETURN NUMBER IS
    salary NUMBER;
    annual_percent NUMBER; 
    annual_bonus_percent NUMBER;
    annual_bonus NUMBER;
BEGIN
    IF (input_salary IS NULL OR input_annual_percent IS NULL) THEN
        RAISE_APPLICATION_ERROR(-20003, 'Values must be not null.');
    END IF;
    
    IF NOT REGEXP_LIKE(input_salary, '^[0-9]+$') OR  NOT REGEXP_LIKE(input_annual_percent, '^[0-9]+$') THEN
        RAISE_APPLICATION_ERROR(-20004, 'Invalid input. Values must be numbers.');
    END IF;
    
    salary := TO_NUMBER(input_salary);
    annual_percent := TO_NUMBER(input_annual_percent);
    
    IF MOD(annual_percent, 1) != 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Bonus percentage must be an integer value.');
    END IF;
    
    IF salary < 0 OR annual_percent < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid input. Values must be positiv.');
    END IF;
    
    annual_bonus_percent := annual_percent / 100;
    annual_bonus := (1 + annual_bonus_percent) * 12 * salary;

    RETURN annual_bonus;
END; 

SELECT CalculateYearlyReward('gsfhd', 10) FROM dual;

CREATE USER c##Labs IDENTIFIED BY pass091103;
grant connect to c##Labs;
grant all privileges to c##Labs;
