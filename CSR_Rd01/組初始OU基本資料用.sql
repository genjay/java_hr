set @tbl_name='touset_offspecial_lvlist'; 

select concat('insert into ',@tbl_name,' \n'
,'(',group_concat(column_name order by ordinal_position),')'
,'\n Select \n'
,group_concat(column_name order by ordinal_position) 
,'\n from ',@tbl_name,' b\n'
,'where OUguid="**common**"' 
)
from information_schema.COLUMNS a
where table_name=@tbl_name
 and table_schema='csr_rd01' 
 and ordinal_position>3;

select concat('\n on duplicate key update \n'
,group_concat(concat(column_name,'=b.',(column_name),'\n'))
,';')
from information_schema.COLUMNS a
where table_name=@tbl_name
 and table_schema='csr_rd01'
 and column_name not in ('OUguid')
 and ordinal_position>4
 ;