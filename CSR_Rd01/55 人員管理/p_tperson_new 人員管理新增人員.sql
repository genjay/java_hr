drop procedure if exists p_tperson_new;

delimiter $$ 

create procedure p_tperson_new
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_Emp_ID                    varchar(36)
,in_Emp_Name                  varchar(36)
,in_ArriveDate                date
,in_Dep_ID                    varchar(36)
,in_CardNo                    varchar(36)
,in_Sex_Z02                   varchar(36)
,in_BirthDay                  date
,in_IDNumber                  varchar(36)
,in_Marriage_Z13              varchar(36)
,in_education_level_Z12       varchar(36)
,in_School_info               varchar(255)
,in_Title_Name                varchar(36)
,in_Tel_1                     varchar(255)
,in_Tel_2                     varchar(255)
,in_Address_1                 varchar(255)
,in_Address_2                 varchar(255)
,in_Email                     varchar(255)
,in_ICE_Name                  varchar(255)
,in_ICE_relationship          varchar(255)
,in_ICE_Tel1                  varchar(255)
,in_ICE_Tel2                  varchar(255)
,in_type_Z07                  varchar(45)
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare in_Dep_Guid varchar(36);
declare in_Emp_Guid varchar(36);
declare in_type_Z09 varchar(36);
declare in_Valid_Date date;

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tperson_new 執行中';

if err_code=0 then # 0 tlog_proc

Insert into tlog_proc (ltpid,note) values ('rwid',in_rwid);
Insert into tlog_proc (ltpid,note) values ('Emp_ID',in_Emp_ID);
Insert into tlog_proc (ltpid,note) values ('Emp_Name',in_Emp_Name);
Insert into tlog_proc (ltpid,note) values ('ArriveDate',in_ArriveDate); 
Insert into tlog_proc (ltpid,note) values ('Dep_ID',in_Dep_id);
Insert into tlog_proc (ltpid,note) values ('CardNo',in_CardNo);
Insert into tlog_proc (ltpid,note) values ('Sex_Z02',in_Sex_Z02);
Insert into tlog_proc (ltpid,note) values ('BirthDay',in_BirthDay);
Insert into tlog_proc (ltpid,note) values ('IDNumber',in_IDNumber);
Insert into tlog_proc (ltpid,note) values ('Marriage_Z13',in_Marriage_Z13);
Insert into tlog_proc (ltpid,note) values ('education_level_Z12',in_education_level_Z12);
Insert into tlog_proc (ltpid,note) values ('School_info',in_School_info);
Insert into tlog_proc (ltpid,note) values ('Title_Name',in_Title_Name);
Insert into tlog_proc (ltpid,note) values ('Tel_1',in_Tel_1);
Insert into tlog_proc (ltpid,note) values ('Tel_2',in_Tel_2);
Insert into tlog_proc (ltpid,note) values ('Address_1',in_Address_1);
Insert into tlog_proc (ltpid,note) values ('Address_2',in_Address_2);
Insert into tlog_proc (ltpid,note) values ('Email',in_Email);
Insert into tlog_proc (ltpid,note) values ('note',in_note);
end if;

if err_code=0 && ifnull(in_IDNumber,'')='' then # 0
 set err_code=1; set outMsg='身分証號不能空白';
end if; # 0  

if err_code=0 && ifnull(in_Emp_ID,'')='' then # 0
 set err_code=1; set outMsg='員工工號不能空白';
end if; # 0   

if err_code=0 && ifnull(in_Emp_Name,'')='' then # 0
 set err_code=1; set outMsg='姓名不能空白';
end if; # 0   


if err_code=0 then
 set isCnt=0;
 Select rwid into isCnt from tperson a
 Where a.OUguid=in_OUguid
   And a.Emp_id=in_Emp_ID  
   And a.leavedate is null limit 1;
 if isCnt>0 then set err_code=1; set outMsg=concat(in_Emp_ID,'該員工在職中');
 end if;
end if; # 10

if err_code=0 then # 20
 set isCnt=0;
 Select rwid into isCnt from tperson a
 where a.OUguid=in_OUguid
  And a.IDNumber=in_IDNumber limit 1;
 if isCnt>0 then set err_code=1; set outMsg=concat('該身份証號有人使用');
 end if;
end if; # 20

if err_code=0 then
 set isCnt=0;
 Select rwid,Dep_Guid into isCnt,in_Dep_Guid from tdept a
 where a.OUguid=in_OUguid
   And a.dep_id=in_Dep_ID;
 if isCnt=0 then set err_code=1; set outMsg='部門錯誤'; end if;
end if;

if err_code=0 && in_Rwid=0 then # 90 新增
 set in_Emp_Guid=uuid();
  Insert into tperson
 (ltUser,ltPid,Emp_Guid,OUguid,Emp_ID,Emp_Name,ArriveDate,Dep_Guid,CardNo,Sex_Z02,BirthDay,IDNumber,Marriage_Z13,education_level_Z12,School_info,Title_Name,Tel_1,Tel_2,Address_1,Address_2,Email,type_Z07,note)
 values 
 (in_ltUser,in_ltPid,in_Emp_Guid,in_OUguid,in_Emp_ID,in_Emp_Name,in_ArriveDate,in_Dep_Guid,in_CardNo,in_Sex_Z02,in_BirthDay,in_IDNumber,in_Marriage_Z13,in_education_level_Z12,in_School_info,in_Title_Name,in_Tel_1,in_Tel_2,in_Address_1,in_Address_2,in_Email,in_type_Z07,in_note);
 set outMsg=concat('「',in_Emp_ID,'」','新增完成');
 set outRwid=last_insert_id();
 end if; # 90 

 if err_code=0 && in_Rwid>0 then # 90 修改 
  # 此程式目前只處理新人報到
 set outMsg=concat('「',in_Rwid,'」','修改成功');
 set outRwid=in_Rwid;
 end if; # 90 修改

if err_code=0 then # 95 新增 tperson_inoutlog  
 set in_type_Z09='A1';
 set in_Valid_Date=in_ArriveDate;
Insert into tperson_inoutlog
 (ltUser,ltPid,Emp_Guid,Valid_Date,type_Z09,Dep_Guid,title_name,CardNo,note)
 values 
 (in_ltUser,in_ltPid,in_Emp_Guid,in_Valid_Date,in_type_Z09,in_Dep_Guid,in_title_name,in_CardNo,in_note);

end if; # 95

if err_code=0 && in_Rwid=0 
  && not (in_ICE_Name='') then # 95 tperson_ice新增

  Insert into tperson_ice
 (ltUser,ltPid,Emp_Guid,ICE_Name,ICE_relationship,ICE_Tel1,ICE_Tel2,note)
 values 
 (in_ltUser,in_ltPid,in_Emp_Guid,in_ICE_Name,in_ICE_relationship,in_ICE_Tel1,in_ICE_Tel2,in_note);
 
 end if; # 90  
 
end; # begin