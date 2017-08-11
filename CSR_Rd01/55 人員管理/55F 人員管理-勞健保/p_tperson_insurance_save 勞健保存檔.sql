drop procedure if exists p_tperson_insurance_save;

delimiter $$ 

create procedure p_tperson_insurance_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_Emp_ID                    varchar(36)
,in_NHI_LV                    int(11)
,in_NHI_Valid_St              date
,in_NHI_Valid_End             date
,in_NHI_Subsidy_ID            varchar(36)
,in_labor_LV                  int(11)
,in_labor_Valid_St            date
,in_labor_Valid_End           date
,in_labor_Subsidy_ID          varchar(36)
,in_LP_LV                     int(11)
,in_LP_Valid_St               date
,in_LP_Valid_End              date
,in_LP_self_payRate           decimal(10,5)
,in_LP_company_payRate        decimal(10,5)
,in_NHI_2nd_free              tinyint(1)
,in_NHI_2nd_Note              text
,in_typeA16_ID                varchar(36)
,in_Note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare in_Emp_Guid varchar(36);
declare in_typeA16_Guid varchar(36);

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tperson_insurance_save 執行中';
 
if 0 && err_code=0 then
Insert into tlog_proc (ltpid,note) values ('rwid',in_rwid);
Insert into tlog_proc (ltpid,note) values ('Emp_id',in_Emp_id);
Insert into tlog_proc (ltpid,note) values ('NHI_LV',in_NHI_LV);
Insert into tlog_proc (ltpid,note) values ('NHI_Valid_St',in_NHI_Valid_St);
Insert into tlog_proc (ltpid,note) values ('NHI_Valid_End',in_NHI_Valid_End);
Insert into tlog_proc (ltpid,note) values ('NHI_Subsidy_ID',in_NHI_Subsidy_ID);
Insert into tlog_proc (ltpid,note) values ('labor_LV',in_labor_LV);
Insert into tlog_proc (ltpid,note) values ('labor_Valid_St',in_labor_Valid_St);
Insert into tlog_proc (ltpid,note) values ('labor_Valid_End',in_labor_Valid_End);
Insert into tlog_proc (ltpid,note) values ('labor_Subsidy_ID',in_labor_Subsidy_ID);
Insert into tlog_proc (ltpid,note) values ('LP_LV',in_LP_LV);
Insert into tlog_proc (ltpid,note) values ('LP_Valid_St',in_LP_Valid_St);
Insert into tlog_proc (ltpid,note) values ('LP_Valid_End',in_LP_Valid_End);
Insert into tlog_proc (ltpid,note) values ('LP_self_payRate',in_LP_self_payRate);
Insert into tlog_proc (ltpid,note) values ('LP_company_payRate',in_LP_company_payRate);
Insert into tlog_proc (ltpid,note) values ('NHI_2nd_free',in_NHI_2nd_free);
Insert into tlog_proc (ltpid,note) values ('NHI_2nd_Note',in_NHI_2nd_Note);
Insert into tlog_proc (ltpid,note) values ('typeA16_id',in_typeA16_id);
Insert into tlog_proc (ltpid,note) values ('Note',in_Note);
end if;

if err_code=0 && in_NHI_Valid_St > ifnull(in_NHI_Valid_End,'9999/12/31') then
 set err_code=1; set outMsg='健保投保日錯誤';
end if;
if err_code=0 && in_labor_Valid_St > ifnull(in_labor_Valid_End,'9999/12/31') then
 set err_code=1; set outMsg='勞保投保日錯誤';
end if;
if err_code=0 && in_LP_Valid_St > ifnull(in_LP_Valid_End,'9999/12/31') then
 set err_code=1; set outMsg='勞退投保日錯誤';
end if;

if err_code=0 && (not in_LP_self_payRate between 0 and 6) then
 set err_code=1; set outMsg='勞退自提只能輸入0~6';
end if;

if err_code=0 && (not in_LP_company_payRate in (0,6)) then
 set err_code=1; set outMsg='勞退公司只能輸入(0或6)';
end if;

if err_code=0 then # 10 抓 Emp_guid
 set isCnt=0;
 Select rwid,Emp_Guid into isCnt,in_Emp_Guid
 from tperson
 Where OUguid=in_OUguid 
   And emp_id=in_Emp_ID;
 if isCnt=0 then set err_code=1; set outMsg='Emp_Guid 錯誤'; end if;
end if;

if err_code=0 then # 11 抓 Emp_guid
 set isCnt=0;
 Select rwid,CodeGuid into isCnt,in_typeA16_Guid
 from tcatcode
 Where OUguid=in_OUguid 
   And Syscode='A16'
   And CodeID=in_typeA16_ID;
 if isCnt=0 then set err_code=1; set outMsg='CodeGuid 錯誤'; end if;
end if;
 

if err_code=0 && in_Rwid=0 then # 90 新增
  Insert into tperson_insurance
 (ltUser,ltPid,Emp_Guid,NHI_LV,NHI_Valid_St,NHI_Valid_End,NHI_Subsidy_ID,labor_LV,labor_Valid_St,labor_Valid_End,labor_Subsidy_ID,LP_LV,LP_Valid_St,LP_Valid_End,LP_self_payRate,LP_company_payRate,NHI_2nd_free,NHI_2nd_Note,typeA16_Guid,Note)
 values 
 (in_ltUser,in_ltPid,in_Emp_Guid,in_NHI_LV,in_NHI_Valid_St,in_NHI_Valid_End,in_NHI_Subsidy_ID,in_labor_LV,in_labor_Valid_St,in_labor_Valid_End,in_labor_Subsidy_ID,in_LP_LV,in_LP_Valid_St,in_LP_Valid_End,in_LP_self_payRate,in_LP_company_payRate,in_NHI_2nd_free,in_NHI_2nd_Note,in_typeA16_Guid,in_Note);
 set outMsg=concat('「',in_Rwid,'」','新增完成');
 set outRwid=last_insert_id();
 end if; # 90 

 if err_code=0 && in_Rwid>0 then # 90 修改 
 Update tperson_insurance Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid
 ,Emp_Guid                      = in_Emp_Guid
 ,NHI_LV                        = in_NHI_LV
 ,NHI_Valid_St                  = in_NHI_Valid_St
 ,NHI_Valid_End                 = in_NHI_Valid_End
 ,NHI_Subsidy_ID                = in_NHI_Subsidy_ID
 ,labor_LV                      = in_labor_LV
 ,labor_Valid_St                = in_labor_Valid_St
 ,labor_Valid_End               = in_labor_Valid_End
 ,labor_Subsidy_ID              = in_labor_Subsidy_ID
 ,LP_LV                         = in_LP_LV
 ,LP_Valid_St                   = in_LP_Valid_St
 ,LP_Valid_End                  = in_LP_Valid_End
 ,LP_self_payRate               = in_LP_self_payRate
 ,LP_company_payRate            = in_LP_company_payRate
 ,NHI_2nd_free                  = in_NHI_2nd_free
 ,NHI_2nd_Note                  = in_NHI_2nd_Note
 ,typeA16_Guid                  = in_typeA16_Guid
 ,Note                          = in_Note
  Where rwid=in_Rwid;
 set outMsg=concat('「',in_Rwid,'」','修改成功');
 set outRwid=in_Rwid;
 end if; # 90 修改
 


end; # begin