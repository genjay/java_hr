drop procedure if exists p_tperson_save;

delimiter $$ 

create procedure p_tperson_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_Emp_ID                    varchar(36)
,in_Emp_Name                  varchar(36) 
,in_Sex_Z02                   varchar(36)
,in_BirthDay                  date
,in_IDNumber                  varchar(36)
,in_Marriage_Z13              varchar(36)
,in_education_level_Z12       varchar(36)
,in_School_info               varchar(255) 
,in_Tel_1                     varchar(255)
,in_Tel_2                     varchar(255)
,in_Address_1                 varchar(255)
,in_Address_2                 varchar(255)
,in_Email                     varchar(255)
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare is_Emp_ID varchar(36);

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tperson_save 執行中';

if err_code=0 then
Insert into tlog_proc (ltpid,note) values ('rwid',in_rwid);
Insert into tlog_proc (ltpid,note) values ('Emp_ID',in_Emp_ID);
Insert into tlog_proc (ltpid,note) values ('Emp_Name',in_Emp_Name); 
Insert into tlog_proc (ltpid,note) values ('Sex_Z02',in_Sex_Z02);
Insert into tlog_proc (ltpid,note) values ('BirthDay',in_BirthDay);
Insert into tlog_proc (ltpid,note) values ('IDNumber',in_IDNumber);
Insert into tlog_proc (ltpid,note) values ('Marriage_Z13',in_Marriage_Z13);
Insert into tlog_proc (ltpid,note) values ('education_level_Z12',in_education_level_Z12);
Insert into tlog_proc (ltpid,note) values ('School_info',in_School_info);
Insert into tlog_proc (ltpid,note) values ('Tel_1',in_Tel_1);
Insert into tlog_proc (ltpid,note) values ('Tel_2',in_Tel_2);
Insert into tlog_proc (ltpid,note) values ('Address_1',in_Address_1);
Insert into tlog_proc (ltpid,note) values ('Address_2',in_Address_2);
Insert into tlog_proc (ltpid,note) values ('Email',in_Email);
Insert into tlog_proc (ltpid,note) values ('note',in_note);
end if;

if err_code=0 then
 set isCnt=0;
 Select rwid,Emp_ID into isCnt,is_Emp_ID
 From tperson
 Where rwid!=in_Rwid # 自己以外
   And OUguid=in_OUguid 
  -- And leavedate=null
   And IDNumber=in_IDNumber limit 1;
 if isCnt>0 then 
  set err_code=1; 
  set outMsg=concat('該身份証號已被',is_Emp_ID,'使用'); end if;
   
end if;

if err_code=0 && in_Rwid=0 then # 90 新增
 # 此proc，不會有新增tperson的情境
 # 新人報到，必需使用另一隻proc
 set outMsg=concat('「',in_Rwid,'」','新增完成');
 set outRwid=last_insert_id();
 end if; # 90 
 
 if err_code=0 && in_Rwid>0 then # 90 修改 
 Update tperson Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid
 ,Emp_ID                        = in_Emp_ID
 ,Emp_Name                      = in_Emp_Name
 ,Sex_Z02                       = in_Sex_Z02
 ,BirthDay                      = in_BirthDay
 ,IDNumber                      = in_IDNumber
 ,Marriage_Z13                  = in_Marriage_Z13
 ,education_level_Z12           = in_education_level_Z12
 ,School_info                   = in_School_info
 ,Tel_1                         = in_Tel_1
 ,Tel_2                         = in_Tel_2
 ,Address_1                     = in_Address_1
 ,Address_2                     = in_Address_2
 ,Email                         = in_Email
 ,note                          = in_note
  Where rwid=in_Rwid;
 set outMsg=concat('「',in_Rwid,'」','修改成功');
 set outRwid=in_Rwid;
 end if; # 90 修改
 

end; # begin