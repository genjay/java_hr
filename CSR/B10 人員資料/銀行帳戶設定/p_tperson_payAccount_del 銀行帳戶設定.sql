drop procedure if exists p_tperson_payAccount_del;

delimiter $$

create procedure p_tperson_payAccount_del
( 
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36),
in_Rwid          int,
out outMsg text,
out outRwid int,
out err_code int
)
begin

declare tlog_note text; 
declare isCnt int;  
declare in_Empguid varchar(36);
declare need_restDefault int;
DECLARE EXIT HANDLER FOR SQLEXCEPTION#, SQLWARNING
BEGIN
    ROLLBACK;
END;

set err_code=0;set outRwid=0; set outMsg=concat(in_Rwid,'p_tperson_payAccount_del');

if err_code=0 then # 20 抓 Empguid
  set in_Empguid='';
  Select Empguid
  into in_Empguid 
  from tperson_payAccount
  Where rwid = in_Rwid;
end if; # 20

if err_code=0 then # 30 判斷刪除後，是否還有default的帳號
  set isCnt=0;
  Select rwid into isCnt 
  from tperson_payAccount
  Where
    rwid != in_Rwid And empguid=in_Empguid And emp_default = '1';
  if isCnt=0 then set need_restDefault=1; end if;
end if; # 30 判斷刪除後，是否還有default的帳號

if err_code=0 then # 90 資料刪除
start transaction;
  delete from tperson_payAccount
  Where rwid=in_Rwid;
 
  if need_restDefault=1 then # 隋機指定，已存在資料，預設值
  update tperson_payaccount 
  set 
    emp_default = 1
  Where Emp_default is null
        And Empguid = in_Empguid limit 1;
  end if; # 隋機指定，已存在資料，預設值
commit;
 
end if; # 90 資料刪除
 
end # Begin