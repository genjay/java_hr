-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`admin`@`%` PROCEDURE `p_tCalendar_save`(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36)  
,in_Type   varchar(36)
,in_Dutydate date
,in_holiday  int
,out outMsg  text /*回傳訊息，直接給user看的*/
,out outRwid  int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)
begin
/*
call p_tCalendar_save(
'microjet'
,'ltUser'
,'ltPid'
,''   # CalID 預設空白
,'20140701'
,'0'
,@a,@b,@c
);
*/
declare in_CalGuid text;
declare err_code int default 0;
if err_code=0 Then # 10 
  if IFNULL(in_Type,'')='' Then # 10-1
   Select OUguid into in_CalGuid From tOUset Where OUguid=in_OUguid;
   if in_CalGuid='' Then set err_code=1; set outMsg='in_OUguid 不存在於tOUset'; end if;
   call p_tlog('in_type=null',in_CalGuid);
  ELSE 
   Select codeguid into in_CalGuid From tcatcode 
   Where syscode='A05' And codeID=in_Type And OUguid=in_OUguid;
   if in_CalGuid='' Then set err_code=1; set outMsg="in_type 不存在於tcatcode 'A05'"; end if;
  end if; # 10-1
end if; # 10

if err_code=0 Then # 90
insert into tCalendar
(ltUser,ltpid,CalGuid,CalDate,holiday)
values
(in_ltUser,in_ltPid,in_CalGuid,in_Dutydate,in_holiday)
on duplicate key update
holiday=in_holiday;
set outMsg=concat(in_Dutydate,'修改');

end if; # 90 

end