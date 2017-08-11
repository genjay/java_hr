drop procedure if exists p_Pid_runCheck; # 檢查有無執行權限

delimiter $$

create procedure p_Pid_runCheck
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltPid  varchar(36)
,in_Aid_Guid   Varchar(36)    # 帳號 Aid_Guid
,in_Pid_ID     varchar(36)    # 程式代號
,out outRuntype int   # 0 無權限、1 有權限
,out outMsg     text  # 回傳訊息
,out outRwid    int   # 回傳單據號，新增單號、錯誤單號
,out err_code   int   # err_code
)

begin
declare isCnt,isEnd,isExists int ;
set err_code=0;
set outRuntype=0;
set isEnd=0;

call p_tlog('aaa',concat(in_Pid_ID ));  

if err_code=0 && isEnd=0 then # 05 判斷 tpid_ctrl、無資料或ctrl=0 就直接結束、回傳可執行
 set isCnt=0;
  Select Rwid into isCnt from tpid_ctrl
  where pid_ID=in_Pid_ID and pid_ctrl=1;
  if isCnt=0 then set outRuntype=1; set isEnd=1; end if;
end if; # 05 

if err_code=0 && isEnd=0 then # 07 放行 俊昇帳號，暫時測試用,完成後需拿掉此段程式
  set isCnt=0;
  Select Rwid into isCnt from tAccount 
  where aid='A02121' 
    And aid_guid=in_Aid_Guid;
  if isCnt>0 then set outRuntype=1; set isEnd=1; end if;
end if; # 

if err_code=0 && isEnd=0 then #10 個人權限
  set isCnt=0;  
  set isExists=0;
  Select ifnull(runtype,0),count(*) into isCnt,isExists from tpid_secemp
  Where pid_ID   = in_Pid_ID
    And Aid_Guid = in_Aid_Guid;
  if isExists=1 && isCnt=1 then set isEnd=1; set outRuntype=1; end if; #有權限
  if isExists=1 && isCnt=0 then set isEnd=1; set outRuntype=0; end if; #無權限
  if isExists=0 then set isEnd=0; end if; # 無設定

end if ; #  

if err_code=0  && isEnd=0 then # 20 角色權限
  set isCnt=0;
  set isExists=0;
  Select ifnull(runtype,0),count(*) into isCnt,isExists from tPid_secrole
  where pid_ID = in_Pid_ID
  And Role_guid in (Select Role_Guid From tRole_member Where Aid_Guid=in_Aid_Guid)
  And runtype=1 limit 1;
 
  if isExists=1 && isCnt=1 then set isEnd=1; set outRuntype=1; end if; #有權限
  if isExists=1 && isCnt=0 then set isEnd=1; set outRuntype=0; end if; #無權限
  if isExists=0 then set isEnd=0; end if; # 無設定

end if; # 20


end;