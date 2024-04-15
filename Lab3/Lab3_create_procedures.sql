drop procedure dev_schema.simple_procedure;

create or replace procedure dev_schema.simple_procedure(
    id in number,
    name in varchar2
) as
begin
    dbms_output.put_line('it is simple procedure');
end;

drop index prod_schema.table3_name_idx;

CREATE INDEX prod_schema.ya_ne_sdala ON prod_schema.table3 (name);

create or replace procedure dev_schema.ya_sdala(
    id in number,
    name in varchar2
) as
begin
    dbms_output.put_line('ya sdala');
end;

drop procedure prod_schema.simple_proc;

create or replace procedure prod_schema.simple_proc(
    id in number,
    name in varchar2
) as
begin
    dbms_output.put_line('it is simple proc');
end;