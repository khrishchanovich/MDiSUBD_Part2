DROP TABLE MYTABLE;

-- TASK 1 --
CREATE TABLE mytable (
    id  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    val NUMBER
);

-- TASK 2 --
DECLARE 
    i NUMBER;
BEGIN 
    FOR i IN 1..10000 LOOP
        INSERT INTO mytable (val) values (ROUND(DBMS_RANDOM.VALUE(-100, 100)));
    END LOOP;
END;

SELECT * FROM MYTABLE;

DELETE FROM MYTABLE;

-- TASK 3 --
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
    text_str VARCHAR2(100);
BEGIN
    SELECT id, val
    INTO temp_id, temp_val
    FROM mytable
    WHERE id = input_id;
    
    text_str := 'INSERT INTO mytabl (id, val) VALUES (' || temp_id || ', ' || temp_val || ')';
    
    RETURN text_str;
END; 

SELECT insertcommand(12) FROM dual;

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
CREATE OR REPLACE FUNCTION CalculateYearlyReward(p_monthly_salary IN NUMBER, p_annual_bonus_percent IN NUMBER) RETURN NUMBER IS
    annual_bonus NUMBER;
    annual_bonus_percent NUMBER; 
BEGIN
    IF MOD(p_annual_bonus_percent, 1) != 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Bonus percentage must be an integer value.');
    END IF;
    
    IF p_annual_bonus_percent < 0 OR p_annual_bonus_percent > 100 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid bonus percentage. Please enter a value between 0 and 100.');
    END IF;

    annual_bonus_percent := p_annual_bonus_percent / 100;

    annual_bonus := (1 + annual_bonus_percent) * 12 * p_monthly_salary;

    RETURN annual_bonus;
EXCEPTION
    WHEN VALUE_ERROR THEN
        RAISE_APPLICATION_ERROR(-20003, 'Invalid input. Please enter a valid number.');
END; 

SELECT CalculateYearlyReward(5000, 10) FROM dual;

CREATE USER c##Labs IDENTIFIED BY pass091103;
grant connect to c##Labs;
grant all privileges to c##Labs;
