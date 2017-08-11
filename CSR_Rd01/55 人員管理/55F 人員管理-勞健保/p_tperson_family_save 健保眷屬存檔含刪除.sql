drop procedure if exists p_tperson_family_save;

delimiter $$ 

create procedure p_tperson_family_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(11) unsigned
,in_emp_id                    varchar(36)
,in_Fam_ID                    varchar(36)
,in_Fam_Name                  varchar(36)
,in_Fam_Birthday              date
,in_Sex_z02                   varchar(36)
,in_type_Z03                  varchar(45)
,in_Subsidy_ID                varchar(45)
,in_Valid_st                  date
,in_Valid_end                 date
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare isDel int default 0;
declare in_Emp_Guid varchar(36);
declare in_typeA16_Guid varchar(36);

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tperson_family_save 執行中';

if in_Fam_ID='' && in_Fam_Name='' 
 && isnull(in_Fam_Birthday)
 && isnull(in_Valid_st) && isnull(in_Valid_end) && in_note='' then
 set isDel='1';
end if;

if isDel=0 && in_Valid_st > ifnull(in_Valid_end,'9999/12/31') then
 set err_code=1; set outMsg='退保日需大於投保日或空白';
end if; 

if isDel=0 && in_Valid_st > sysdate() then
 set err_code=1; set outMsg='投保日不可大於當日';
end if;

if isDel=0 && in_Fam_Birthday > sysdate() then
 set err_code=1; set outMsg='生日不可大於當日';
end if;

if isDel=0 && ifnull(trim(in_Fam_ID),'')='' then
 set err_code=1; set outMsg='身份証號不能空白'; 
end if;

if isDel=0 && ifnull(trim(in_Fam_Name),'')='' then
 set err_code=1; set outMsg='姓名不能空白'; 
end if;

if isDel=0 && err_code=0 then # 10 抓Emp_Guid
 set isCnt=0;
 Select rwid,Emp_Guid into isCnt,in_Emp_Guid
 from tperson a
 where a.OUguid=in_OUguid
  And a.Emp_id=in_Emp_ID;
 if isCnt=0 then set err_code=1; set outMsg='Emp_Guid 錯誤'; end if;
end if; # 10

if isDel=0 && err_code=0 then
 set isCnt=0;
 Select rwid into isCnt from tperson_family a
 Where a.emp_guid=in_Emp_Guid
   And a.rwid!=in_Rwid
   And a.Fam_ID=in_Fam_ID limit 1;
 if isCnt>0 then 
 set err_code=1; set outMsg=concat('「',in_Fam_ID,'」','該身份証號已輸入');
 end if;
end if;


if isDel=0 && err_code=0 && in_Rwid=0 then # 90 新增
  Insert into tperson_family
 (ltUser,ltPid,emp_Guid,Fam_ID,Fam_Name,Fam_Birthday,Sex_z02,type_Z03,Subsidy_ID,Valid_st,Valid_end,note)
 values 
 (in_ltUser,in_ltPid,in_emp_Guid,in_Fam_ID,in_Fam_Name,in_Fam_Birthday,in_Sex_z02,in_type_Z03,in_Subsidy_ID,in_Valid_st,in_Valid_end,in_note);
 set outMsg=concat('「',in_Fam_Name,'」','新增完成');
 set outRwid=last_insert_id();
 end if; # 90   

 if isDel=0 && err_code=0 && in_Rwid>0 then # 90 修改 
 Update tperson_family Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid
 -- ,emp_Guid                      = in_emp_Guid
 ,Fam_ID                        = in_Fam_ID
 ,Fam_Name                      = in_Fam_Name
 ,Fam_Birthday                  = in_Fam_Birthday
 ,Sex_z02                       = in_Sex_z02
 ,type_Z03                      = in_type_Z03
 ,Subsidy_ID                    = in_Subsidy_ID
 ,Valid_st                      = in_Valid_st
 ,Valid_end                     = in_Valid_end
 ,note                          = in_note
  Where rwid=in_Rwid;
 set outMsg=concat('「',in_Fam_Name,'」','修改成功');
 set outRwid=in_Rwid;
 end if; # 90 修改
 
if isDel=1 && err_code=0 && in_Rwid>0 then
 delete from tperson_family Where rwid=in_Rwid;
 set outMsg='刪除成功';
end if;

end; # begin