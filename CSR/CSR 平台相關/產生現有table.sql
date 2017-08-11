select * from ttablememo;

delete from ttablememo;

insert into ttablememo (table_schema,table_name)
select a.table_schema,a.table_name
from information_schema.tables a
left join ttablememo b on a.table_schema=b.table_schema and a.table_name=b.table_name
where a.table_schema='csrhr' and b.table_name is null;
