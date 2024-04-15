drop function dev_schema.simple_function;

create or replace function dev_schema.simple_function(
    id in number,
    name in varchar2
) return number as
    counter number := 10;
begin
    return counter;
end;

drop function prod_schema.simple_func;

create or replace function prod_schema.simple_func(
    id in number,
    name in varchar2
) return number as
    counter number := 10;
begin
    return counter;
end;

drop function prod_schema.simple_function;

create or replace function prod_schema.simple_function(
    id in number,
    name in varchar2
) return number as
    counter number := 10;
begin
    return counter;
end;

create or replace function prod_schema.same_name(
    id in number,
    name in varchar2
) return number as
    counter number := 10;
begin
    return counter;
end;

create or replace function dev_schema.same_name(
    id in varchar,
    name in number
) return number as
    counter number := 10;
begin
    return counter;
end;
