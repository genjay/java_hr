drop procedure if exists p_tOUset_Paybase_save;

delimiter $$

create procedure p_tOUset_Paybase_save
( 
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36),
in_rwid   int(10)  , 
in_typeZ06  varchar(36), # A 加班費/B 請假
in_typeA06  varchar(36), # 薪資項目 P01 底薪
out outMsg text,
out outRwid int,
out err_code int
)
begin

declare tlog_note text; 
declare isCnt int;  
DECLARE EXIT HANDLER FOR SQLEXCEPTION#, SQLWARNING
BEGIN
    ROLLBACK;
END;
set err_code=0;set outRwid=0; set outMsg='p_tOUset_Paybase_save';
 
set outMsg=concat(in_typeA06);
 
set sql_safe_updates=0;

set in_typeA06=replace( (in_typeA06),' ','');
set in_typeA06=replace( (in_typeA06),'[','(\'');
set in_typeA06=replace(in_typeA06,',','\',\'');
set in_typeA06=replace(in_typeA06,']','\')');
 
set outMsg=in_typeA06;
-- set err_code=1;
if err_code=0 && in_typeZ06=-1 then # 05 未選擇回傳(-1)
  set err_code=1; set outMsg='';
end if;
 
if err_code=0 then # 10
drop table if exists tmp01;
  set @sql_p_tOUset_Paybase_save = concat("
      create table tmp01 as
      Select a.OUguid ",
      ",\"",in_typeZ06,"\" as type_z06 ",
      ",b.codeGuid paytypeguid
      from tOUset a
      left join tCatcode b on a.OUguid=b.OUguid And b.Syscode='A06'
      Where a.OUguid = \"",in_OUguid,"\"
      And  b.codeid in ",in_typeA06,';');

   prepare s1 from @sql_p_tOUset_Paybase_save;
   execute s1; 
 set outMsg=@sql_p_tOUset_Paybase_save;
end if; # 10 

if err_code=0 && 1 then # 90 修改資料

start transaction; # 修改的 commit
  Delete from tOUset_Paybase 
  Where tOUset_Paybase.type_z06=in_typeZ06
  And not exists 
  (select * from tmp01 x where tOUset_Paybase.OUguid=x.OUguid
  and tOUset_Paybase.type_z06=x.type_z06
  and tOUset_Paybase.paytypeguid=x.paytypeguid);
  
  insert into tOUset_Paybase
  (OUguid,type_z06,Paytypeguid)
  Select OUguid,type_z06,paytypeguid from tmp01 a
  On duplicate key update
  paytypeguid=a.paytypeguid
  ;
  commit;

set outMsg='執行完成';

end if; # 90
   

end # Begin