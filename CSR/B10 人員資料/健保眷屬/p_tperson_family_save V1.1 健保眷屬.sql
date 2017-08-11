drop procedure if exists p_tperson_family_save;

delimiter $$

create procedure p_tperson_family_save
( 
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36)
,in_rwid   int(11) unsigned
,in_EmpID varchar(36)
,in_Fam_ID varchar(36)
,in_Fam_Name varchar(36)
,in_Fam_Birthday varchar(36)
,in_Sex_z02 varchar(36) 
,in_type_z19 varchar(36)
,in_Valid_st varchar(36)
,in_Valid_end varchar(36)
,in_note text
,out outMsg text
,out outRwid int
,out err_code int 
)
begin
/*
call p_tperson_family_save
( 
'microjet','ltuser','ltpid', 
0 ,#in_rwid int(11) unsigned
'a00004',
'f123999999',
'陳三一',
'1999/03/03'
,'m'
,'typeA16'
,'A' # typez19
,'20140101'
,''
,'' # in_note text
,@a,@b,@c
);

select @a,@b,@c
*/

declare tlog_note text; 
declare in_Empguid varchar(36);
declare isCnt int;  
set err_code=0;set outRwid=0; set outMsg='p_tperson_family_save';
  
if err_code=0 then # 20
  set isCnt=0;
  Select rwid,empguid into isCnt,in_Empguid from tperson where empid=in_EmpID and ouguid=in_OUguid;
  if isCnt=0 then set err_code=1; set outMsg='無此工號'; end if;
end if; # 20  

if err_code=0 then # 30
  set isCnt=0;
  Select rwid into isCnt from tperson_family 
  Where empguid=(select empguid from tperson where ouguid=in_OUguid and empid=in_EmpID)
    And fam_id=in_Fam_ID
    And rwid != in_rwid; 
  if isCnt>0 then set err_code=1; set outMsg=concat(in_Fam_id,'資料已存在'); end if;
end if; # 30 

if err_code=0 then # 85 
  if err_code=0 &&  in_Valid_st='' then set err_code=1; set outMsg='投保日不可空白'; end if;
  if err_code=0 &&  in_Fam_Birthday='' then set err_code=1; set outMsg='生日不可空白'; end if;
  if err_code=0 && in_Valid_end='' then set in_Valid_end=Null; end if;
  
end if; # 85

if err_code=0 && 1 then # 90 
insert into tperson_family
(empguid,fam_id,fam_name,fam_birthday,sex_z02,type_z19,valid_st,valid_end,note)
 values
(in_Empguid,in_Fam_ID,in_Fam_Name,in_Fam_Birthday,in_Sex_z02,in_type_z19,in_Valid_st,in_Valid_end,in_note)
On duplicate key update
 Fam_Name=in_Fam_Name
,Fam_Birthday=in_Fam_Birthday
,Sex_z02=in_Sex_z02
,valid_st=in_Valid_st
,valid_end=in_valid_end
,type_z19=in_type_z19
,note=in_note;
end if; # 90

end # Begin