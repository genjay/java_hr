drop procedure if exists p_tworkrest_del;

delimiter $$

create procedure p_tworkrest_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36)  
,in_Rwid int  /*要修改的單據rwid*/
,out outMsg text /*回傳訊息，直接給user看的*/
,out outRwid int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin
set err_code=0;

if err_code=0 Then # 90 刪除資料 
  delete  from tworkrest where rwid=in_Rwid ; 
  set outMsg="刪除成功";
end if;


end;