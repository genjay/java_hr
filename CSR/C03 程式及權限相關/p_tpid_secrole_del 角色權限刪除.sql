drop procedure if exists p_tpid_secrole_del;

delimiter $$

create procedure p_tpid_secrole_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36)  
,in_Rwid   int  # 0 新增
,out outMsg   text /*回傳訊息，直接給user看的*/
,out outRwid  int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin 
declare isCnt int;
set err_code=0;
set outRwid=0;
set outMsg='p_tpid_secrole_del 執行中'; 

end; # Begin