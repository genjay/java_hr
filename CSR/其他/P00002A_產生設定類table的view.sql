drop procedure if exists P00002A;

delimiter $$

create procedure P00002A(varSTR varchar(255))
begin

  set sql_safe_updates=0;

select concat('create or replace view v',table_name,' as \n select ',
group_concat(concat('a.',column_name) order by ordinal_position)
,',b.ouGuid,b.codeID,b.codeDesc ','\n'
,' from ',table_name,' a ','\n'
,' inner join tcatcode b on '
,(select column_name
from information_schema.statistics b
where index_name='upk'  and column_name like '%guid' and table_name=a.table_name)
,'=b.codeguid;'
) 
 into @sql
from information_schema.columns a
where table_schema='csrhr'
and column_name Not in ('ltdate','ltpid','crdate','cruser','OUguid')
and table_name=varSTR
 ; 

prepare s1 from @sql;
execute s1;

end