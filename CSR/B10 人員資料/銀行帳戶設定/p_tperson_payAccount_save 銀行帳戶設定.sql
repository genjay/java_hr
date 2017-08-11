drop procedure if exists p_tperson_payAccount_save;

delimiter $$

create procedure p_tperson_payAccount_save
( 
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36),
in_Rwid           int,
in_Bank_ID        varchar(36), 
in_Emp_PayAccount varchar(36),
in_Emp_default    int,
in_note    text,
in_EmpID          varchar(36),
out outMsg text,
out outRwid int,
out err_code int
)
begin

declare tlog_note text; 
declare isCnt int;  
set err_code=0;set outRwid=0; set outMsg='p_tperson_payAccount_save';
set sql_safe_updates=0;

set outMsg=concat(in_Rwid,',',in_Bank_ID,',',
in_Emp_PayAccount,',',
in_Emp_default ,',',
in_note  ,',',
in_EmpID  ,',');
 # set err_code=1;

if err_code=0 then # 20 判斷有無修改
  set isCnt=0;
  Select isCnt from tperson_payAccount
  Where rwid = in_Rwid
    And Bank_ID = in_Bank_ID
    And Emp_PayAccount = in_Emp_PayAccount
    And Emp_default=in_Emp_default
    And note = in_note;
 if isCnt>0 then set err_code=1; set outMsg='no Change'; end if;
end if; # 20

start transaction;
if err_code=0 && in_Emp_default=1 then # 85 清除該人員的 emp_default
  # 因有設定unique index 在(empguid,emp_default)
  # 所以需要清除default 才能成功update 
  set isCnt=0;
  Select Rwid into isCnt from tperson_payAccount
  Where Rwid != in_Rwid
    And Empguid =  (Select empguid from tperson where OUguid=in_OUguid and empid=in_empid)
    And emp_default=1 limit 1;

  if isCnt>0 then   
  Update tperson_payAccount
  set emp_default=NULL 
  Where Empguid = (Select empguid from tperson where OUguid=in_OUguid and empid=in_empid);
  set outMsg='清空default';
  end if;

end if; # 85 清除該人員的 emp_default 
 

if err_code=0 && in_Rwid=0 then # 90 新增
  
  insert into tperson_payAccount
  (EmpGuid,Bank_ID,Emp_payAccount,Emp_default,Note)
  values 
  (
  (Select Empguid from tperson where OUguid=in_OUguid and empid=in_EmpID)
  ,in_Bank_ID
  ,in_Emp_payAccount
  ,if(in_Emp_default='1','1',NULL)
  ,in_note);
end if; # 90 新增

if err_code=0 && in_Rwid>0 then # 90B 修改
  update tperson_payAccount Set
   Bank_ID =in_Bank_ID
  ,Emp_payAccount = in_Emp_payAccount
  ,Emp_default = if(in_Emp_default='1','1',NULL)
  ,Note = in_note
  Where rwid=in_Rwid;
end if; # 90B 修改

commit;
 
end # begin