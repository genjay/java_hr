drop procedure if exists p_tperson_salary_h_save;

delimiter $$ 

create procedure p_tperson_salary_h_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_Emp_ID                    varchar(36)
,in_type_Z15                  varchar(45)  
,in_OverType_ID               varchar(36)
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int; 
declare in_OverType_Guid varchar(36); 
declare in_Emp_Guid varchar(36);

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
   set err_code=1;
   set outMsg='sql error';
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tperson_salary_h_save 執行中';

if err_code=0 then # 抓取 Emp_guid
 set isCnt=0;
 Select rwid,Emp_guid into isCnt,in_Emp_Guid
 from tperson
 Where OUguid=in_OUguid And Emp_ID=in_Emp_ID;
 if isCnt=0 then set err_code=1; set outMsg='Emp_Guid有錯誤'; end if;
end if;

if err_code=0 then # 抓取 overtype_guid
 set isCnt=0;
 SELECT rwid,Overtype_Guid into isCnt,in_Overtype_Guid
 FROM tovertype
 Where OUguid=in_OUguid And Overtype_ID=in_Overtype_ID ;
 if isCnt=0 then set err_code=1; set outMsg='Overtype_Guid有錯誤'; end if;
end if; 

if err_code=0 then # 判斷是否有無修改，需在抓取Empguid,overtypeguid之後
  set isCnt=0; 
  Select rwid into isCnt 
   From tperson_salary_h 
  Where rwid=in_Rwid And type_Z15=in_type_Z15 And OverType_Guid=in_OverType_Guid And note=in_note;
 if isCnt>0 then set err_code=0; set outMsg='資料無修改'; end if;
 end if;
 
if err_code=0 && in_Rwid=0 then # 90 新增
  Insert into tperson_salary_h
 (ltUser,ltPid,Emp_Guid,type_Z15,OverType_Guid,note)
 values 
 (in_ltUser,in_ltPid,in_Emp_Guid,in_type_Z15,in_OverType_Guid,in_note);
 set outMsg=concat('「',in_Emp_ID,'」','修改完成'); # 使用者畫面，都是修改樣式，所以新增改修改完成
 set outRwid=last_insert_id();
 end if; # 90 
 
  if err_code=0 && in_Rwid>0 then # 90 修改 
 Update tperson_salary_h Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid
 ,type_Z15                      = in_type_Z15  
 ,OverType_Guid                 = in_OverType_Guid
 ,note                          = in_note
  Where rwid=in_Rwid;
 set outMsg=concat('「',in_Emp_ID,'」','修改成功');
 set outRwid=in_Rwid;
 end if; # 90 修改
 
 

end; # begin