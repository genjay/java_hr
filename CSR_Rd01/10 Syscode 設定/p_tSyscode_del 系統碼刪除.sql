drop procedure if exists p_tSysCode_del; # 分類碼存檔

delimiter $$

create procedure p_tSysCode_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/ 
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
 
declare isCnt      int; 
declare is_syscode varchar(36);

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
set err_code=0;
 
set outMsg="p_tSysCode_del 執行開始";

if err_code=0 then # 05
  set isCnt=0; set is_Syscode='';
  Select rwid,Syscode Into isCnt,is_Syscode from tSyscode Where rwid = in_Rwid;
  if isCnt=0 then set err_code=1; set outMsg='資料不存在'; end if;
end if; # 05

if err_code=0 then # 10
   set isCnt=0;
   set outMsg='10 判斷有無被tcatcode 使用';
   Select rwid into isCnt From tcatcode 
    Where syscode = is_Syscode limit 1;
   if isCnt>0 Then set err_code=1; set outMsg="此syscode已被catcode 使用，不能刪除"; end if; 
   
end if;  # 10

if err_code=0 then #20
  set isCnt=0;
  set outMsg='20 判斷有無被tcatcode2 使用';
  Select rwid into isCnt from tcatcode_sys 
    Where syscode = is_Syscode limit 1;
  if isCnt>0 Then set err_code=1; set outMsg="此syscode已被catcode_sys 使用，不能刪除"; end if;
  
end if;

 if err_code=0 Then # 90 刪除
    set outMsg='90 準備刪除'; 
        Delete from tsyscode where rwid=in_rwid ;
        set outMsg=concat("「",ifnull(is_syscode,''),"」","刪除成功");
 
end if;

  
end