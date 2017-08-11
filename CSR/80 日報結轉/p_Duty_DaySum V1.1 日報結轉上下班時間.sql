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
,out err_code int  # err_code
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

declare tlog_note text;
declare outA,outB,outC text;
declare tmpVar_A text; 
set err_code=0;

SET tlog_note= concat( "call p_Duty_DaySum(\n'"
,in_OUguid  ,"',\n'"
,in_ltUser  ,"',\n'"
,in_ltpid   ,"',\n'"  
,in_Dutydate,"',\n'"   
,in_EmpX    ,"',\n"
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");");

call p_tlog('p_Duty_DaySum',tlog_note);
set outMsg='日結開始';

if err_code=0 Then  # A 出勤日判斷
   set tmpVar_A = f_DtimeCheck(f_removeX(concat(in_Dutydate,'0000'))); 
   if  tmpVar_A !='OK' Then set err_code=1;  set outMsg=concat("出勤日  ",tmpVar_A); end if; 
   if err_code=0 Then set in_Dutydate = str_to_date(concat(f_removeX(  in_Dutydate)),'%Y%m%d'); end if;
   call p_tlog(in_ltPid,'出勤日判斷結束');
   set outMsg="A 出勤日判斷";
end if; # A

if err_code=0 then # 出勤日不能超過今天
   if in_Dutydate > date(now()) Then set err_code=1; set outMsg="結轉日期不可超過今天"; end if;
end if;


if err_code=0 then # 90
  set outMsg='p_tduty_A_save 開始';

  call p_tOverdoc_duty(
   in_OUguid,in_ltUser,in_ltpid
  ,in_Dutydate
  ,in_EmpX #,in_EmpX      text # 預設'',字串時，未來指定單筆empguid、多筆empguid、單筆depguid、多筆depguid
  ,outA,outB,outC);
if outC > 0 then set err_code=1; set outMsg=outA; end if;

  call p_tduty_A_save( # 必需在 p_tOverdoc_duty 之後執行
   in_OUguid,in_ltUser,in_ltpid
  ,in_Dutydate
  ,in_EmpX 
  ,outA,outB,outC);
  if outC > 0 then set err_code=1; set outMsg=outA; end if;
 
end if; # 90
 

end # end Begin