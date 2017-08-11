drop procedure if exists p_SQL_Mask;

delimiter $$ 

create procedure p_SQL_Mask
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_Sql        text # Select 後面的 SQL
,in_Table      text # table name 
,out outSql    text # 處理後的sql
,out outMsg    text # 回傳訊息
,out outRwid    int # 回傳單據號，新增單號、錯誤單號
,out err_code   int # err_code
)  

begin
declare isCnt int;  
/*
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
    set outMsg='sql error';
    set err_code=1;
  end if;
END;  
*/
 /*
call p_SQL_Mask
(
'**common**' # in_OUguid varchar(36)
,'e9f272bc-6a2f-11e4-8bc2-000c29364755' #,in_ltUser varchar(36)
,'' #,in_ltpid  varchar(36)  
,'rwid,ltdate,ltUser,ltpid,Emp_Guid,OUguid,Emp_ID,Emp_Name,ArriveDate,LeaveDate,Dep_Guid,CardNo,Sex_Z02,BirthDay,IDNumber,Marriage_Z13,education_level_Z12,School_info,Title_Name,Tel_1,Tel_2,Address_1,Address_2,Email,type_Z07,note' ,'tperson' #,in_Table      text # table name 
,@a #,out outSql    text # 處理後的sql
,@b #,out outMsg    text # 回傳訊息
,@c #,out outRwid    int # 回傳單據號，新增單號、錯誤單號
,@d #,out err_code   int # err_code
) ;

select @sql,@in_Sql,@a,@b,@c,@d;
*/
set err_code=0; set outRwid=0; set outMsg='p_demo 執行中';

#insert into tlog_proc (note) values ('mask'),(in_sql),(in_ltUser),(in_table);

if 1 && err_code=0 then
	set @in_Sql=concat('(\'',replace(in_Sql,',','\'),(\''),'\')');
	drop table if exists tmp_p_SQL_Mask01;
	CREATE temporary TABLE tmp_p_SQL_Mask01 (
	`rwid` int(10) unsigned NOT NULL AUTO_INCREMENT, 
	column_name varchar(60),
	Aid_guid varchar(36),
	PRIMARY KEY (`rwid`)
	) ENGINE=Myisam DEFAULT CHARSET=utf8;
	set @in_Sql=concat('Insert into tmp_p_SQL_Mask01 (column_name) values ',@in_Sql,';');
	prepare s1 from @in_Sql;
	execute s1;
	update tmp_p_SQL_Mask01 set column_name=trim(column_name),Aid_Guid=in_ltUser;
end if;

if err_code=0 then
	set @sql=concat("
	Select 
	Group_concat(if(ifnull(mask_rule,'')=''
	,a.column_name
	,concat('f_mask(',a.column_name,',',b.mask_rule,') ',a.column_name)
	) order by a.rwid) 
	into @outSql
	from tmp_p_SQL_Mask01 a 
	left join tcol_mask_aid b on a.column_name=b.column_name and b.aid_guid=a.Aid_Guid and b.table_name='"
	,in_Table,"';");

 insert into tlog_proc (note) values (@sql);

	prepare s1 from @sql;
	execute s1;
	set outSql=@outSql;
-- set outSql="tdoc_forget_rwid,emp_id,'xx' emp_name,dep_desc,dutydate,forgeton,forgetoff,closestatus,note";
 insert into tlog_proc (note) values (outSql);
end if; 

if err_code=0 then # 99 清除 tmp table 
 drop table if exists tmp_p_SQL_Mask01;
end if; # 99 清除 tmp table 


end; # begin