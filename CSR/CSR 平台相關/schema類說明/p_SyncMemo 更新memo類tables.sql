drop procedure if exists p_SyncMemo ;

delimiter $$

create procedure p_SyncMemo()

begin
 # call p_SyncMemo();

# dd 欄位的說明
# 因無法使用
# insert into tdd_memo select column_name from information_schema.columns
# 只能用此方試處理


set Group_concat_max_len=4294967295 /*32bit 最大值*/;

-- set Group_concat_max_len=18446744073709547520 /*64bit 最大值*/ ;

select 
concat("('",
replace(group_concat(distinct a.column_name),',',"'),('"),"')")
into @sql_p1
from vcolumns_memo a
left join tdd_memo b on a.column_name=b.column_name
Where b.rwid is null;

if @sql_p1 is Not null 
Then 
set @sql=concat("insert into tdd_memo (column_name) values ",@sql_p1,";") ;

 prepare s1 from @sql;
 execute s1 ;
end if;

#######
# table 的說明
#######
insert into ttables_memo
(table_schema,table_name)
select a.table_schema,a.table_name
from vtables_memo a
left join ttables_memo b on a.rwid=b.rwid
where b.rwid is null;

###########
## index 說明
###########
insert into tindex_memo
(table_schema,table_name,index_name,index_seq)
select a.table_schema,a.table_name,a.index_name,a.index_seq
from vindex_memo a
left join tindex_memo b on a.rwid=b.rwid
Where b.rwid is null;


############
## Procedure & Function 說明
############
insert into troutine_memo
(routine_name,routine_schema,routine_type)
select a.routine_name,a.routine_schema,a.routine_type 
from vRoutine_memo a
left join troutine_memo b on a.rwid=b.rwid
where b.rwid is null;


##################
# tcolumns 說明
##################
# 遇到無法直接 insert * 
select 
group_concat(
concat("('",
concat_ws("','",
a.table_schema,a.table_name,a.column_name
,a.ordinal_position,a.data_type,a.memo)
      ,"')")
       ) 
 into @sql_p1
from (select a.rwid,a.table_schema,a.table_name,a.column_name
,a.ordinal_position,a.data_type,ifnull(a.memo,'') memo from vcolumns_memo a
left join tcolumns_memo b on a.rwid=b.rwid 
where b.rwid is null  
-- limit 1
) a 
-- where b.rwid is null  
;

if @sql_p1 is Not null 
Then 
set @sql=concat("insert into tcolumns_memo (table_schema,table_name,column_name,ordinal_position,data_type,memo
) values ",@sql_p1,";") ;

 prepare s1 from @sql;
 execute s1 ;
end if;


end;