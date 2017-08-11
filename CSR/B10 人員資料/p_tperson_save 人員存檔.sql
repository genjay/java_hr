drop procedure if exists p_tperson_save; # 人員資料存檔

delimiter $$

create procedure p_tperson_save
(
 in_OUguid varchar(36)
,in_LtUser varchar(36)
,in_ltPid varchar(36)
,in_rwid int(10) unsigned 
,in_EmpID   varchar(10)
,in_EmpName varchar(30) 
,in_CardNo  varchar(50)  
,in_Sex_Z02 varchar(36)
,in_BirthDay date
,in_IDNumber varchar(36)
,in_marriage_Z13 varchar(36)
,in_type_Z14 varchar(36)
,in_type_Z12 varchar(36)
,in_Address_1 varchar(36)
,in_Address_2 varchar(36)
,in_School_info varchar(36)
,in_Email varchar(36)
,in_Tel_1 varchar(36)
,in_Tel_2 varchar(36)
,out outMsg text
,out outRwid int
,out err_code int
)

begin
declare tlog_note text;
declare isCnt int;
set err_code = 0;

 
call p_tlog(in_ltPid,tlog_note);
set outMsg=concat(in_Rwid,'p_tperson_save,人員資料開始'); 

if err_code=0 && in_Rwid>0 then # 90 修改資料
  Update tperson set 
  empid=in_empid
 ,EmpName=in_EmpName 
 ,CardNo=in_CardNo  
 ,sex_z02=in_sex_z02
 ,BirthDay=in_BirthDay
 ,IDNumber=in_IDNumber
 ,Marriage_Z13=in_Marriage_Z13
 ,type_Z12=in_type_Z12
 ,type_Z14=in_type_Z14
 ,Address_1=in_Address_1
 ,Address_2=in_Address_2
 ,School_info=in_School_info
 ,email=in_email
 ,tel_1=in_tel_1
 ,tel_2=in_tel_2   
 ,ltUser=in_ltUser
 ,ltpid=in_ltpid  
Where Rwid=in_Rwid;
end if; # 90

if err_code=0 && in_Rwid=0 then # 90 新增資料
  set outMsg='新增開始';
  Insert into tperson
  (empguid,OUguid,empid,EmpName,CardNo,sex_z02,BirthDay,IDNumber,Marriage_Z13
  ,type_Z12,type_Z14,Address_1,Address_2,School_info,email,tel_1,tel_2
  ,ltUser,ltpid)
  values
  (uuid(),in_OUguid,in_empid,in_EmpName,in_CardNo,in_sex_z02,in_BirthDay,in_IDNumber,in_Marriage_Z13
  ,in_type_Z12,in_type_Z14,in_Address_1,in_Address_2,in_School_info,in_email,in_tel_1,in_tel_2
  ,in_ltUser,in_ltpid);
 set outMsg='新增結束';
end if; # 90


 
 
end # Begin