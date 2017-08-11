drop procedure if exists p_tAccount_ou_del;

delimiter $$

create procedure p_tAccount_ou_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltPid  varchar(36) 
,in_Rwid      int
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)

begin 
declare isCnt int;
declare in_Aid,in_Aid_guid varchar(36);
set err_code=0;
set outMsg='p_tAccount_ou_del 開始'; 

if err_code=0 then # 10
  Select Aid_guid into in_Aid_guid from tAccount_ou where rwid = in_Rwid;
  Select Aid into in_Aid from tAccount where aid_guid = in_Aid_guid;
end if; # 10

if err_code=0 then # 90 
  delete from tAccount_ou Where rwid = in_Rwid;
  set isCnt=0;
  Select rwid into isCnt from tAccount_ou where aid_guid=in_Aid_guid limit 1;
  if isCnt=0 then # 若tAccount_ou 無資料時，同時刪除 tAccount
   delete from tAccount Where Aid_guid= in_Aid_guid;
  end if;
  set outMsg=concat('「',in_Aid,'」','資料已刪除');  
  set outRwid=in_Rwid;
end if; # 90 

end;