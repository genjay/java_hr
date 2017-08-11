drop procedure if exists p_tperson_inoutlog_change;

delimiter $$ 

create procedure p_tperson_inoutlog_change
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_Emp_ID                    varchar(36)  # 工號
,in_Valid_Date                date         # 生效日
,in_type_Z09                  varchar(45)  # 異動類型
,in_Dep_ID                    varchar(45)  # 部門
,in_title_name                varchar(45)  # 職稱
,in_JobAge_Offset             int(11)      # 期初年資
,in_Change_Reason             varchar(45)  # 異動原因
,in_CardNo                    varchar(45)  # 卡號
,in_note                      text
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

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
	set err_code=1;
	set outMsg='sql error';
  end if;
END;  
 
set err_code=0; set outRwid=0; 
set outMsg='p_tperson_inoutlog_change 執行中';

if err_code=0 then
insert into tlog_proc (ltpid,note) values 
('in_rwid',in_rwid)
,('in_Emp_ID',in_Emp_ID ) 
,('in_Valid_Date',in_Valid_Date )             
,('in_type_Z09',in_type_Z09)            
,('in_Dep_ID',in_Dep_ID )                 
,('in_title_name',in_title_name)     
,('in_JobAge_Offset' ,in_JobAge_Offset)          
,('in_Change_Reason',in_Change_Reason)            
,('in_CardNo',in_CardNo );               
end if;

set err_code=1; set outMsg='錯誤測試';

if err_code=0 && in_Valid_Date>sysdate() then # 到職日不可大於今天
 set err_code=1; set outMsg='生效日不可大於今天';
end if; # 10 

if err_code=0 && isnull(in_Valid_Date)  then # 到職日不可大於今天
 set err_code=1; set outMsg='生效日不可空白';
end if; # 10 

if err_code=0 then # 抓該員工，最後一筆異動資料
set isCnt=0;
Select b.rwid,b.Valid_Date,b.type_Z09 
 into isCnt,is_Valid_Date,is_type_Z09
from tperson a
inner join tperson_inoutlog b on a.Emp_Guid=b.Emp_Guid
Where a.OUguid=in_OUguid
  And a.emp_id=in_Emp_ID 
order by b.valid_date desc,b.ltdate desc limit 1;
 if isCnt=0 then set is_Valid_Date='0000/12/31'; set is_type_Z09=''; end if;
 if in_Rwid>0/*修改時*/ && isCnt!=in_Rwid then set err_code=1; set outMsg='此筆資料不是最後一筆'; end if;
end if;

if err_code=0 && is_type_Z09 like 'Q%' then # 判斷在職中，才能異動
 set err_code=1; set outMsg='離職狀態不能做異動';
end if; #

if err_code=0 then
 set isCnt=0;
 Select Emp_Guid into in_Emp_Guid
 from tperson 
 Where OUguid=in_OUguid 
   And Emp_ID=in_Emp_id;
end if;  

if err_code=0 then
 set isCnt=0;
Select Dep_Guid into in_Dep_Guid
from tdept
where OUguid=in_OUguid 
   And dep_id=in_dep_id;
end if;  

if err_code=0 && in_Valid_Date<is_Valid_Date then 
 set err_code=1; set outMsg='到職日不可小於上一筆資料的生效日';
end if;

start transaction;
if err_code=0 && in_Rwid=0 then # 90 新增 
  Insert into tperson_inoutlog
 (ltUser,ltPid,Emp_Guid,Valid_Date,type_Z09,Dep_Guid,title_name,JobAge_Offset,Change_Reason,CardNo,note)
 values 
 (in_ltUser,in_ltPid,in_Emp_Guid,in_Valid_Date,in_type_Z09,in_Dep_Guid,in_title_name,in_JobAge_Offset,in_Change_Reason,in_CardNo,in_note);

 set outMsg=concat('「',in_Rwid,'」','新增完成');
 set outRwid=last_insert_id();
 end if; # 90 

 if err_code=0 && in_Rwid>0 then # 90 修改 
 Update tperson_inoutlog Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid 
 ,Valid_Date                    = in_Valid_Date
 ,type_Z09                      = in_type_Z09
 ,Dep_Guid                      = in_Dep_Guid
 ,title_name                    = in_title_name
 ,JobAge_Offset                 = in_JobAge_Offset
 ,Change_Reason                 = in_Change_Reason
 ,CardNo                        = in_CardNo
 ,note                          = in_note
  Where rwid=in_Rwid;

 set outMsg=concat('「',in_Rwid,'」','修改成功');
 set outRwid=in_Rwid;
 end if; # 90 修改

if err_code=0 then # 95 修改 tperson
 update tperson Set 
  Dep_Guid                      = in_Dep_Guid
 ,title_name                    = in_title_name
 ,CardNo                        = in_CardNo
 Where Emp_Guid=in_Emp_Guid;
end if; # 95 

commit;

end; # begin