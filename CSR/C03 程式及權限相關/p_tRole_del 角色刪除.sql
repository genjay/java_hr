drop procedure if exists p_tRole_del;

delimiter $$

create procedure p_tRole_del
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
declare in_Role_ID,in_Role_Desc,in_Role_Guid varchar(36);
set err_code=0;
set outRwid=0;
set outMsg='p_tRole_del 執行中'; 

if err_code=0 then # 05 判斷資料是否存在，及抓roleid…
  set in_Role_ID=''; set in_Role_Desc='';
  Select Role_ID,Role_Desc,Role_Guid into in_Role_ID,in_Role_Desc,in_Role_Guid from tRole Where rwid= in_Rwid;
  if in_Role_ID='' then set err_code=1; set outMsg='資料不存在'; end if;
end if; # 05

if err_code=0 then # 10 判斷 角色成員是否使用中
  set isCnt=0;
  Select Rwid into isCnt from tRole_member
  where Role_Guid = in_Role_Guid limit 1;
  if isCnt>0 then set err_code=1; set outMsg=concat(in_Role_ID,' 已被tRole_member使用'); end if;

end if; # 10

if err_code=0 then # 20 判斷 程式管控角色是否使用中
  set isCnt=0;
  Select Rwid into isCnt from tpid_secrole Where Role_Guid = in_Role_Guid limit 1;
  if isCnt>0 then set err_code=1; set outMsg=concat(in_Role_ID,' 已被tPid_secrole使用'); end if;
  
end if; # 20 

if err_code=0 then
  delete from tRole where Rwid=in_Rwid;
  set outMsg=concat(in_Role_ID,' 刪除成功'); 
end if;


end; # Begin