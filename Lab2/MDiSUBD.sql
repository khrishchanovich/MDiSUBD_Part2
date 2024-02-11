-- LAB2 --

-- TASK1 --
CREATE TABLE STUDENTS (
    ID NUMBER NOT NULL,
    NAME VARCHAR2(50) NOT NULL,
    GROUP_ID NOT NULL,
    
    CONSTRAINT student_id PRIMARY KEY (ID),
    CONSTRAINT fk_group FOREIGN KEY (GROUP_ID) REFERENCES GROUPS(ID) 
);

CREATE TABLE GROUPS (
    ID NUMBER NOT NULL,
    NAME VARCHAR2(50) NOT NULL,
    C_VAL NUMBER NOT NULL,
    
    CONSTRAINT group_pk PRIMARY KEY (ID)
);