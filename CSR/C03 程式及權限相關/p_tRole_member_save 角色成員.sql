drop procedure if exists p_tRole_member_save;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_tRole_member_save`(
 in_OUguid   varchar(36)
,in_ltUser   varchar(36)
,in_ltpid    varchar(36)  
,in_Role_ID  varchar(36)
,in_Aid      varchar(36)
,in_Note      text
,in_Rwid      int
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)
begin

declare tlog_note text;
declare in_aid_guid,in_Role_Guid varchar(36);
declare isCnt int;  
declare droptable int default 0; # 1 drop temptable /0 不drop 除錯用 
set err_code = 0; 
set sql_safe_updates=0; 

if err_code=0 then # 10
  set isCnt=0; set in_aid_guid='';
  Select a.rwid,a.aid_guid into isCnt,in_aid_guid from tAccount a
  left join tAccount_ou b on a.aid_guid=b.aid_guid
  where b.ouguid=in_OUguid and a.aid=in_Aid limit 1;
  if isCnt=0 then set err_code=1; set outMsg='無此帳號aid'; end if;
end if; # 10

if err_code=0 then # 20 
  set isCnt=0;  
  Select Rwid,Role_guid into isCnt,in_Role_Guid from tRole
  where ouguid=in_OUguid and role_id=in_role_id limit 1;
  if isCnt=0 then set err_code=1; set outMsg='無此角色ID'; end if;
end if; # 20

if err_code=0 then # 30 判斷欲修改的資料，是否已存在
  set isCnt=0;
  Select rwid into isCnt from tRole_member 
  Where Rwid != in_Rwid 
    And Role_Guid = in_Role_Guid 
    And  Aid_Guid = in_Aid_Guid limit 1;
  if isCnt>0 then set err_code=1; set outMsg='資料已存在'; end if;
end if;  # 30 

if err_code=0 && in_Rwid=0 then # 90 新增
  Insert into tRole_member (Role_Guid,Aid_guid,Note)
  Select in_Role_Guid,in_aid_guid,in_Note ;
  set outRwid=last_insert_id();
  set outMsg='新增完成';
end if; # 90 

if err_code=0 && in_Rwid>0 then # 90 修改
  Update tRole_member set
  Role_Guid=in_Role_Guid,
  Aid_guid = in_Aid_Guid,
  note = in_note
  Where Rwid=in_Rwid;
  set outMsg='修改完成'; 
  set outRwid=in_Rwid;
end if; # 90 

end # Begin