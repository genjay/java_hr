select * from tcolumnmemo;

delete from tcolumnmemo;

insert into tcolumnmemo
(table_schema,table_name,column_name)
select table_schema,table_name,column_name
from information_schema.columns a
where table_schema='csrhr'
and not exists (select * from tcolumnmemo b where a.table_schema=b.table_schema and 
a.table_name=b.table_name and a.column_name=b.column_name);