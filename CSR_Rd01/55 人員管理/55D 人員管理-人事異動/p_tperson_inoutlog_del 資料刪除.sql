drop procedure if exists p_tperson_inoutlog_del;

delimiter $$ 

create procedure p_tperson_inoutlog_del
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned  
,in_note                      text        # 備註
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
/*
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
*/
 
set err_code=0; set outRwid=0; set outMsg='p_tperson_inoutlog_del 執行中';

insert into tlog_proc (ltpid,note) values ('rwid',in_rwid);

if err_code=0 then # 抓該員工，最後一筆異動資料
set isCnt=0;
Select b.rwid -- ,b.Valid_Date,b.type_Z09 
 into isCnt -- ,is_Valid_Date,is_type_Z09
from tperson a
inner join tperson_inoutlog b on a.Emp_Guid=b.Emp_Guid
Where a.OUguid=in_OUguid
  And a.emp_guid=(select emp_guid from tperson_inoutlog where rwid=in_rwid)
order by b.valid_date desc,b.ltdate desc limit 1;
 if isCnt!=in_Rwid then 
  set err_code=1; set outMsg='這不是最後一筆資料';
end if;

insert into tlog_proc (ltpid,note) values ('-----wid',in_rwid);
end if;
 
if err_code=0 && 1 then # 90
 delete from tperson_inoutlog
 Where rwid=in_Rwid;
 set outMsg='刪除成功';
end if; # 90 
end; # begin