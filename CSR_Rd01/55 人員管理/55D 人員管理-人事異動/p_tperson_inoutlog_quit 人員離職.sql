drop procedure if exists p_tperson_inoutlog_quit;

delimiter $$ 

create procedure p_tperson_inoutlog_quit
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_Emp_ID                    varchar(36)
,in_Valid_Date                date        # 離職日
,in_type_Z09                  varchar(45) # 異動類型  
,in_Change_Reason             varchar(45) # 異動原因 
,in_note                      text        # 備註
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int; 
declare is_Valid_Date date;
declare is_type_Z09 varchar(36);
declare in_Emp_Guid varchar(36);
declare in_Dep_Guid varchar(36); 
/*
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
*/
 
set err_code=0; set outRwid=0; set outMsg='p_tperson_inoutlog_quit 執行中';
 

Insert into tlog_proc (ltpid,note) values ('rwid',in_rwid);
Insert into tlog_proc (ltpid,note) values ('Emp_id',in_Emp_id);
Insert into tlog_proc (ltpid,note) values ('Valid_Date',in_Valid_Date);
Insert into tlog_proc (ltpid,note) values ('type_Z09',in_type_Z09);  
Insert into tlog_proc (ltpid,note) values ('note',in_note);

if err_code=0 && in_Valid_Date>sysdate() then # 到職日不可大於今天
 set err_code=1; set outMsg='離職日不可大於今天';
end if; # 10 

if err_code=0 && isnull(in_Valid_Date)  then # 到職日不可大於今天
 set err_code=1; set outMsg='離職日不可空白';
end if; # 10 

if err_code=0 then # 抓該員工，最後一筆異動資料
set isCnt=0;
Select b.rwid,b.Valid_Date,b.type_Z09 
 into isCnt,is_Valid_Date,is_type_Z09
from tperson a
inner join tperson_inoutlog b on a.Emp_Guid=b.Emp_Guid
Where a.OUguid=in_OUguid
  And a.emp_id=in_Emp_ID
  And b.rwid !=in_Rwid /*需排除自己，否則修改時會被卡*/
order by b.valid_date desc,b.ltdate desc limit 1;
 if isCnt=0 then set is_Valid_Date='0000/12/31'; set is_type_Z09=''; end if;
end if;


if err_code=0 then
 set isCnt=0;
 Select Emp_Guid into in_Emp_Guid
 from tperson 
 Where OUguid=in_OUguid 
   And Emp_ID=in_Emp_id; 
end if;  

-- 測試 insert into tlog_proc (note) values (concat(is_Valid_Date,is_type_Z09));

if err_code=0 && in_Valid_Date<is_Valid_Date then 
 set err_code=1; set outMsg='離職日不可小於上一筆資料的生效日';
end if;

if err_code=0 && is_type_Z09 like 'Q%' then
 set err_code=1; set outMsg='目前已是離職狀態'; 
end if;

if err_code=0 && in_Rwid=0 then # 90 新增
 
  Insert into tperson_inoutlog
 (ltUser,ltPid,Emp_Guid,Valid_Date,type_Z09,note)
 values 
 (in_ltUser,in_ltPid,in_Emp_Guid,in_Valid_Date,in_type_Z09,in_note);
 
 update tperson set
 LeaveDate=in_Valid_Date
 Where Emp_Guid=in_Emp_Guid;
 set outMsg=concat('「',in_Rwid,'」','新增完成');
 set outRwid=last_insert_id();
 end if; # 90 

 if err_code=0 && in_Rwid>0 then # 90 修改 
 Update tperson_inoutlog Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid 
 ,Valid_Date                    = in_Valid_Date
 ,type_Z09                      = in_type_Z09
 ,Change_Reason                 = in_Change_Reason
 ,note                          = in_note
  Where rwid=in_Rwid;
 update tperson set
 LeaveDate=in_Valid_Date
 Where Emp_Guid=in_Emp_Guid;
 set outMsg=concat('「',in_Rwid,'」','修改成功');
 set outRwid=in_Rwid;
 end if; # 90 修改
 

end; # begin