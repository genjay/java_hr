drop procedure if exists p_tperson_del;

delimiter $$ 

create procedure p_tperson_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_Rwid      int  
,in_note      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare is_Valid_Date date;
declare is_type_Z09 varchar(36);
declare in_Emp_ID varchar(36);
declare in_Emp_Guid varchar(36);
declare varA,varB,varC text;
/*
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
*/
 
set err_code=0; set outRwid=0; set outMsg='p_tperson_del 執行中';

insert into tlog_proc (note) values (in_Rwid);

if err_code=0 then
 set isCnt=0;
 Select rwid,Emp_id,Emp_Guid into isCnt,in_Emp_ID,in_Emp_Guid
 From tperson 
 Where OUguid=in_OUguid
   And rwid=in_Rwid;
 if isCnt=0 then set err_code=1; set outMsg='無此人'; end if; 
end if;

if err_code=0 then # 判斷有無其他資料使用中
call p_CheckGuid_used
(
 'tperson'   # in_Table      varchar(36)
,'emp_guid'  #,in_GuidName   varchar(36)
,in_Emp_Guid #,in_GuidValue  varchar(36)
,varA        # ougMsg
,varB        # outRwid
,varC        # err_code
);
 set err_code=varC;
 set outMsg=varA;
end if; 
  
 
 if err_code=0 then # 90 
 delete from tperson where ouguid=in_OUguid and emp_id=in_Emp_ID;
 set outMsg=concat('「',in_Emp_ID,'」','刪除成功');
 set outRwid=in_Rwid;
end if; # 90 

end; # begin