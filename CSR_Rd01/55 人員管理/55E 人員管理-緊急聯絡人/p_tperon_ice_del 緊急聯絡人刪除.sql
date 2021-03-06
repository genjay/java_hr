drop procedure if exists p_tperson_ice_del;

delimiter $$ 

create procedure p_tperson_ice_del
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
declare is_ICE_Name varchar(36);

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tperson_ice_del 執行中';

if err_code=0 then
Insert into tlog_proc (ltpid,note) values ('rwid',in_rwid); 
Insert into tlog_proc (ltpid,note) values ('note',in_note);
end if;

if err_code=0 then # 10
 set isCnt=0; 
 Select rwid,ice_name into isCnt,is_ICE_Name
 from tperson_ice 
 Where rwid=in_Rwid 
  And emp_guid in (select emp_guid from tperson where OUguid=in_OUguid);
 if isCnt=0 then set err_code=1; set outMsg='資料不存在'; end if;
end if; # 10

 if err_code=0 then # 90 
 delete from tperson_ice where rwid=in_Rwid;
 set outMsg=concat('「',is_ICE_Name,'」','刪除成功');
 set outRwid=in_Rwid;
end if; # 90

end; # begin