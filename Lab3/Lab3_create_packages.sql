drop package dev_schema.simple_package;

CREATE OR REPLACE PACKAGE dev_schema.simple_package AS
    PROCEDURE procedure1;
    FUNCTION function1 RETURN NUMBER;
    FUNCTION function2(param IN NUMBER) RETURN VARCHAR2;
END;

drop package prod_schema.simple_package;

CREATE OR REPLACE PACKAGE prod_schema.simple_package AS
    PROCEDURE procedure2;
    FUNCTION function2 RETURN NUMBER;
    FUNCTION function3(param IN NUMBER) RETURN VARCHAR2;
END;