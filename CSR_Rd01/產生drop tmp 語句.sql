select concat('if err_code=0 then # 99 清除 tmp table \n'
,group_concat('drop table if exists ',table_name SEPARATOR ';\n'),';\n'
,'end if; # 99 清除 tmp table')
from information_schema.TABLES
where table_name like 'tmp%'
and table_schema='csr_rd01';