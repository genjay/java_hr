drop procedure if exists p_tdept_del;

delimiter $$ 

create procedure p_tdept_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_Rwid      int  # 0 代表新增，大於 0 代表修改 
,in_note      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare is_dep_iD varchar(36);
declare is_Dep_Guid varchar(36);
declare is_outMsg,is_outRwid text; # 用來執行proc，接回傳值用
declare is_err_code int;


DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
/*
call p_tdept_del
(
'microjet','',''
,59 #in_Rwid      int  # 0 代表新增，大於 0 代表修改 
,''  #in_note      text
,@a,@b,@c
)  ;

*/

set err_code=0; set outRwid=0; set outMsg='p_tdept_del 執行中';

if err_code=0 then # 10
 set isCnt=0;
 Select rwid,dep_ID,dep_Guid into isCnt,is_dep_ID,is_Dep_Guid from tdept where rwid = in_Rwid;
 if isCnt=0 then set err_code=1; set outMsg='資料不存在'; end if;
end if; # 10

if err_code=0 then # 50 判斷是否被其他table 欄位使用
 call p_CheckGuid_Used('tdept','Dep_Guid',is_Dep_Guid,is_outMsg,is_outRwid,is_err_code);
 if is_err_code=1 then set err_code=1; set outMsg=is_outMsg; end if; 
end if; # 50

if err_code=0 then # 90 
 Delete from tdept where rwid = in_Rwid;
 set outMsg=concat('「',is_dep_ID,'」','刪除成功');
 set outRwid=in_Rwid;
end if; # 90
 
 
end; # begin