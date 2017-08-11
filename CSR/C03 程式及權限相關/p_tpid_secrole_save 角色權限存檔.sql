drop procedure if exists p_tpid_secrole_save;

delimiter $$

create procedure p_tpid_secrole_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) 
,in_pid_ID   varchar(36)
,in_role_ID  varchar(36)
,in_ctrl   int  # 0 不要管控/1 需要控制權限 
,in_Note   text
,in_Rwid   int  # 0 新增
,out outMsg   text /*回傳訊息，直接給user看的*/
,out outRwid  int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin 
declare isCnt int;
set err_code=0;
set outRwid=0;
set outMsg='p_tpid_secrole_save 執行中'; 

end; # Begin