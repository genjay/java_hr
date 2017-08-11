drop procedure if exists p_tpid_Ctrl_save;

delimiter $$

create procedure p_tpid_Ctrl_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) 
,in_pid_ID   varchar(36)
,in_pid_Desc varchar(36)
,in_pid_ctrl   int  # 0 不要管控/1 需要控制權限 
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
set outMsg='p_tpid_Ctrl_save 執行中';

if err_code=0 && in_Rwid=0 then # 10 新增時判斷，判斷是否存在相同資料
  set isCnt=0;
  Select Rwid into isCnt from tpid_ctrl where pid_ID=in_pid_ID;
  if isCnt>0 then set err_code=1; set outMsg=concat(in_pid_ID,' 已存在'); end if;
end if; # 10

if err_code=0 then # 20 判斷 in_pid_ctrl 是否為 0/1
  if not in_pid_ctrl in (0,1) then set err_code=1; set outMsg='in_pid_ctrl 錯誤，只能 0/1'; end if;
end if;

if err_code=0 && in_Rwid=0 then # 90
  Insert into tPid_Ctrl (pid_ID,pid_Desc,pid_ctrl,Note)
  Select in_pid_ID,in_pid_Desc,in_pid_ctrl,in_Note;
  set outMsg=concat('「',in_pid_ID,'」','新增完成'); 
  set outRwid=last_insert_id();
end if; # 90

if err_code=0 && in_Rwid>0 then # 90 修改
  # 因 pid_ID 為 unique 值，不能修改，若還尚未使用，則使用刪除
  # 此程式不要開放，修改 pid_ID
  Update tPid_ctrl Set
  pid_Desc = in_pid_Desc,
  Note = in_Note,
  pid_ctrl = in_pid_ctrl
  Where Rwid = in_Rwid;
  set outMsg=concat('「',in_pid_ID,'」','修改完成'); 
  set outRwid=in_Rwid;
end if; # 90 


  

end; # Begin