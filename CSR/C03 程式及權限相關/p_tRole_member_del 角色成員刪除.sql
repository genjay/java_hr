drop procedure if exists p_tRole_member_del;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_tRole_member_del`(
 in_OUguid   varchar(36)
,in_ltUser   varchar(36)
,in_ltpid    varchar(36)  
,in_Rwid      int 
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)
begin

declare tlog_note text;
declare isCnt int; 
declare in_Role_ID,in_Aid varchar(36); 
declare droptable int default 0; # 1 drop temptable /0 不drop 除錯用 
set err_code = 0; 
set sql_safe_updates=0; 
set outMsg='p_tRole_member_del 執行中';

if err_code=0 then # 10
  set in_Role_ID='';
  Select Role_ID,Aid into in_Role_ID,in_Aid from vtRole_member
  Where rwid =  in_Rwid And OUguid = in_OUguid limit 1;
  if in_Role_ID='' then set err_code=1; set outMsg='資料不存在'; end if;

end if; # 10 

if err_code=0 then # 90 刪除
   delete from tRole_member where rwid = in_Rwid;
  set outMsg='資料已刪除'; 
end if; # 90 

end # Begin