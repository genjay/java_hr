drop procedure if exists p_tpid_Ctrl_del;

delimiter $$

create procedure p_tpid_Ctrl_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) 
,in_Rwid   int     # 單據的Rwid
,out outMsg   text /*回傳訊息，直接給user看的*/
,out outRwid  int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin 
declare isCnt int; 
declare in_pid_ID varchar(36);
set err_code=0;
set outRwid=0;
set outMsg='p_tpid_Ctrl_del 執行中';
 

if err_code=0 then # 10 
  set in_pid_ID='';
  Select pid_ID into in_pid_ID from tpid_ctrl Where rwid=in_Rwid;
  if in_pid_ID='' then set err_code=1; set outMsg=concat('資料不存在'); end if;
end if; # 10

if err_code=0 then # 20
  set isCnt=0;
  Select Rwid Into isCnt from tpid_secrole Where pid_ID = in_pid_ID;
  if isCnt>0 then set err_code=1; set outMsg=concat('「',in_pid_ID,'」','已被 tpid_secrole 使用'); end if;
end if; # 20

if err_code=0 then # 30
  set isCnt=0;
  Select Rwid Into isCnt from tpid_secemp Where pid_ID = in_pid_ID;
  if isCnt>0 then set err_code=1; set outMsg=concat('「',in_pid_ID,'」','已被 tpid_secemp 使用'); end if;
end if; # 30

if err_code=0 then # 90
  delete from tpid_Ctrl Where Rwid=in_Rwid;
  set outMsg=concat('「',in_pid_ID,'」','已刪除');
end if; # 90



end; # Begin