drop procedure if exists p_tRole_save;

delimiter $$

create procedure p_tRole_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36)  
,in_Role_ID varchar(36)
,in_Role_Desc varchar(36)
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
set outMsg='p_tRole_save 執行中'; 

if err_code=0 then # 10
  set isCnt=0;
  Select rwid into isCnt from tRole Where rwid != in_Rwid And Role_ID = in_Role_ID limit 1;
  if isCnt>0 then set err_code=1; set outMsg=concat(in_Role_ID,' 此代號使用中'); end if; 
end if; # 10

if err_code=0 && in_Rwid=0 then # 90 新增資料
  insert into tRole (Role_guid,OUguid,Role_ID,Role_Desc,note)
  Select uuid(),in_OUguid,in_Role_ID,in_Role_Desc,in_Note;
  set outRwid=last_insert_id();
  set outMsg=concat(in_Role_ID,'新增完成');
end if; # 90 

if err_code=0 && in_Rwid>0 then # 90 修改資料
  update tRole set
  Role_ID=in_Role_ID,
  Role_Desc=in_Role_Desc,
  Note= in_Note
  Where Rwid = in_Rwid;
  set outRwid=in_Rwid;
  set outMsg=concat(in_Role_ID,'修改完成');

end if; # 90 修改

end; # Begin