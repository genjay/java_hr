drop procedure if exists p_Duty_DaySum;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_Duty_DaySum`(
 in_OUguid   varchar(36)
,in_ltUser   varchar(36)
,in_ltpid    varchar(36)  
,in_Dutydate varchar(36)
,in_EmpX      text # 預設'',字串時，未來指定單筆empguid、多筆empguid、單筆depguid、多筆depguid
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out outError int  # err_code
)
begin
/*
call p_Duty_DaySum(
'microjet','ltuser','ltpid'
,'20140624'
,'' #,in_EmpX      text # 預設'',字串時，未來指定單筆empguid、多筆empguid、單筆depguid、多筆depguid
,@a,@b,@c
);

select @a,@b,@c;

*/
DECLARE err_code int default '0'; 
DECLARE droptable int default '0'; # 0 代表測試中 1，正常使用

set @in_OUguid = IFNULL(in_OUguid,'');
set @in_ltUser = IFNULL(in_ltUser,'');
set @in_ltpid  = IFNULL(in_ltpid,'');  
set @in_EmpX   = IFNULL(in_EmpX,'');

if err_code=0 Then  # A @in_Dutydate 出勤日判斷
   set @xx3 = f_DtimeCheck(f_removeX(concat(in_Dutydate,'0000'))); 
   if @xx3 !='OK' Then set err_code=1;  set @outMsg=concat("出勤日  ",@xx3); end if; 
   if err_code=0 Then set @in_Dutydate = str_to_date(concat(f_removeX(  in_Dutydate)),'%Y%m%d'); end if;
   if droptable!=1 Then insert into t_log(ltpid,note) values ('p_Duty_DaySum','出勤日判斷'); end if;
end if; # A
call p_Sysset(1);

call p_tDuty_a_save(@in_OUguid,@in_ltUser,@in_ltpid,@in_Dutydate,@in_EmpX,@a,@b,@c);
if @c>0 then set err_code=1; set @outMsg=concat("p_tDuty_a_save 發生錯誤",ifnull(@a,'')); end if;

if 1 then # End 
set outMsg=if(ifnull(@outMsg,'')='',"成功",@outMsg);

End if; # End
end # end Begin