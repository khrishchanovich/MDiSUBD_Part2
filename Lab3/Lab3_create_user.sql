alter session set "_ORACLE_SCRIPT"=true;

create user dev_schema identified by "password";
create user prod_schema identified by "password";

create user lab_schema identified by "password";
grant sysdba to lab_schema container=all;
