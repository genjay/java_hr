drop procedure if exists p_tOUset_subsidy_del;

delimiter $$ 

create procedure p_tOUset_subsidy_del
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

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_demo 執行中';

if err_code=0 then
 set isCnt=0;
 # 判斷是否被其他Table使用
end if; 
 
 if err_code=0 then # 90 
 Delete from tOUset_subsidy Where rwid=in_Rwid;
 set outMsg=concat('「',is_dep_ID,'」','刪除成功');
 set outRwid=in_Rwid;
end if; # 90

end; # begin