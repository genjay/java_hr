drop procedure if exists p_tOUset_Offspecial_lvlist_save;

delimiter $$ 

create procedure p_tOUset_Offspecial_lvlist_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)  
,in_Data                      text # * (rwid,年資，天數、備註)，(rwid,年資，天數、備註)...
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END; 

set err_code=0; set outRwid=0; set outMsg='p_tOUset_Offspecial_lvlist_save 執行中';

-- 除錯用 insert into tlog_proc (note) values (in_Data);

if err_code=0 then
 drop table if exists tmp01;
 create temporary table tmp01 (
  `rwid` int(11) ,
  `JobAges_m` text DEFAULT NULL,
  `OffDays` text DEFAULT NULL,
  `Note` text
) engine=myisam;

 set @sql=concat('insert into tmp01 (rwid,JobAges_m,OffDays,Note) values ',
 in_Data,';'); 
 
 prepare s1 from @sql;
 execute s1;
 
end if;


if err_code=0 then
 delete from tOUset_offspecial_lvlist 
 Where OUguid=in_OUguid
   And rwid in (select rwid from tmp01);

  Insert into tOUset_offspecial_lvlist
 (ltUser,ltPid,OUguid,JobAges_m,OffDays,Note)
 Select in_ltUser,in_ltPid,in_OUguid,JobAges_m,OffDays,Note
 from tmp01 a 
 where a.JobAges_m>0 and a.OffDays>0; /*因input可以為空白，所以需要加條件否則會sql error*/
 drop table if exists tmp01;
 set outMsg='修改完成';
end if;


 
end; # begin