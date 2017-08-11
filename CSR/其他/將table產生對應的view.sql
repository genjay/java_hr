select concat('create or replace ALGORITHM = TEMPTABLE  view v',table_name,' as \n select ',
group_concat(concat('a.',column_name) order by ordinal_position)
,',b.ouGuid,b.codeID,b.codeDesc ','\n'
,' from ',table_name,' a ','\n'
,' inner join tcatcode b on '
,(select column_name
from information_schema.statistics b
where index_name='upk' and table_name=a.table_name)
,'=b.codeguid;'
)
from information_schema.columns a
where table_schema='csrhr'
and column_name Not in ('ltdate','ltpid','crdate','cruser','OUguid')
and table_name='toffquota'
 ; 