drop procedure if exists p_tSysCode_del; # 分類碼存檔

delimiter $$

create procedure p_tSysCode_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/ 
,in_Rwid int  /*要修改的假單rwid*/
,out outMsg text /*回傳訊息，直接給user看的*/
,out outRwid int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin
/*
call p_tSysCode_del(
 'microjet'
,'user'
,'pid'
,12   #rwid  
,@a,@b,@c);
select @a,@b,@c;

*/

declare tlog_note text;
declare isCnt      int;
declare in_Syscode text;
set err_code=0;

SET tlog_note= concat( "call p_tSysCode_del(\n'"
,in_OUguid  ,"',\n'"
,in_ltUser  ,"',\n'"
,in_ltpid   ,"',\n'"  
,in_Rwid  ,"',\n"
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");");

call p_tlog(in_ltPid,tlog_note);
set outMsg="p_tSysCode_del 執行開始";

if err_code=0 then # 10
   set isCnt=0;
   set outMsg='10 判斷有無被tcatcode 使用';
   Select rwid into isCnt From tcatcode Where syscode in (Select syscode from tsyscode where rwid=in_Rwid) limit 1;
   if isCnt>0 Then set err_code=1; set outMsg="此syscode已被catcode 使用，不能刪除"; end if; 
   call p_tlog(in_ltPid,'10 判斷有無被tcatcode 使用');
end if;  # 10

if err_code=0 then #20
  set isCnt=0;
  set outMsg='20 判斷有無被tcatcode2 使用';
  Select rwid into isCnt from tcatcode2 where syscode in (Select syscode from tsyscode where rwid=in_Rwid) limit 1;
  if isCnt>0 Then set err_code=1; set outMsg="此syscode已被catcode2 使用，不能刪除"; end if;
  call p_tlog(in_ltPid,'20 判斷有無被tcatcode 使用');
end if;

 if err_code=0 Then # 90 刪除
    set outMsg='90 準備刪除';
    Select syscode into in_syscode from tsyscode where rwid=in_Rwid;
        Delete from tsyscode where rwid=in_rwid 
     and Not 
       (syscode in (select syscode from tcatcode ) or 
        syscode in (select syscode from tcatcode2));
        set outMsg=concat("「",ifnull(in_syscode,''),"」","刪除成功");
  call p_tlog(in_ltPid,'90 刪除syscode');
end if;

  
end