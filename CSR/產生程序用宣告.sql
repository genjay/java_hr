set @Table_name='tperson';

select ' in_OUguid varchar(36)' column_name union all
select ',in_LtUser varchar(36)' column_name union all
select ',in_ltPid varchar(36)'  column_name union all
select concat(',','in_',column_name,' ',column_type)
from information_schema.columns a
inner join information_schema.tables b on a.table_name=b.table_name and a.table_schema=b.table_schema
where a.table_name = @Table_name
and ((table_type='BASE TABLE' and ordinal_position> 4 or column_name='rwid')
or (b.table_type='VIEW' and not column_name in ('ouguid')))
union all select ',out outMsg text'
union all select ',out outRwid int'
union all select ',out err_code int';


select "set @in_OUguid=ifnull(in_OUguid,'');" union all
select "set @in_ltUser=ifnull(in_ltUser,'');" union all
select "set @in_ltPid=ifnull(in_ltPid,'');" union all
select 
 concat('set @in_',column_name,'  = ifnull(','in_',column_name,','
,Case 
  When column_type like '%char%' Then "''" 
  When column_type like '%int%' Then "'0'"
  When column_type like '%text%' Then "''"
  When column_type like '%float%' Then "'0'"
  When column_type like 'decimal%' Then "'0'"
  When column_type like 'date'  Then "'2000-01-01'"
  When column_type like 'datetime' Then "'2000-01-01 00:00:00'"
  When column_type like 'time' Then "'00:00:00'  "
  end 
,');')
# ,concat('@in_',column_name ,'=',column_name,';') 
from information_schema.columns a
inner join information_schema.tables b on a.table_name=b.table_name and a.table_schema=b.table_schema
where a.table_name = @Table_name
and ((table_type='BASE TABLE' and ordinal_position> 4 or column_name='rwid')
or (b.table_type='VIEW'  and not column_name in ('ouguid')));

select 
group_concat(
concat('@in_',column_name)
)
from 
(
select 'OUguid ' column_name union all
select 'LtUser ' column_name union all
select 'ltPid '  column_name union all
select column_name from information_schema.columns a
where table_name = @Table_name
 and (ordinal_position>4 or column_name='rwid')
union all select 'outMsg'
union all select 'outRwid'
union all select 'outError') a;

 