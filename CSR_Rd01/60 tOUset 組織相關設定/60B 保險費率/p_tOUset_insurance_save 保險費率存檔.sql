drop procedure if exists p_tOUset_insurance_save;

delimiter $$ 

create procedure p_tOUset_insurance_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_typeA16_ID                varchar(36)
,in_type_Z21                  varchar(36)
,in_Pay_Rate                  decimal(10,4)
,in_self_payRate              decimal(10,4)
,in_company_payRate           decimal(10,4)
,in_Note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare in_typeA16_Guid varchar(36);

/*
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
*/
 
set err_code=0; set outRwid=0; set outMsg='p_demo 執行中';

if err_code=0 then # 10 取得 typeA16_guid
 set isCnt=0;
 Select rwid,codeGuid into isCnt,in_typeA16_Guid from tcatcode
 Where OUguid=in_OUguid And syscode='A16'
   And codeID=in_typeA16_ID ;
 if isCnt=0 then set err_code=1; set outMsg='typeA16錯誤'; end if;
end if;

if err_code=0 then # 判斷是否有無修改
  set isCnt=0; 
  Select rwid into isCnt 
   From touset_insurance 
  Where rwid=in_Rwid And typeA16_Guid=in_typeA16_Guid And type_Z21=in_type_Z21 And Pay_Rate=in_Pay_Rate And self_payRate=in_self_payRate And company_payRate=in_company_payRate And Note=in_Note;
 if isCnt>0 then set err_code=1; set outMsg=''; # 故意空白，資料無修改
 end if;
 end if;

if err_code=0 && in_Rwid=0 then # 90 新增
 Insert into touset_insurance
 (ltUser,ltPid,OUguid,typeA16_Guid,type_Z21,Pay_Rate,self_payRate,company_payRate,Note)
 values 
 (in_ltUser,in_ltPid,in_OUguid,in_typeA16_Guid,in_type_Z21,in_Pay_Rate,in_self_payRate,in_company_payRate,in_Note);
 set outRwid=last_insert_id();
 set outMsg='新增完成';
end if; # 90
 
 if err_code=0 then # 90 
Update touset_insurance Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid
 ,typeA16_Guid                  = in_typeA16_Guid
 ,type_Z21                      = in_type_Z21
 ,Pay_Rate                      = in_Pay_Rate
 ,self_payRate                  = in_self_payRate
 ,company_payRate               = in_company_payRate
 ,Note                          = in_Note
  Where rwid=in_Rwid;
 set outMsg=concat('「',in_type_Z21,'」','修改完成');
 set outRwid=in_Rwid;
end if; # 90

end; # begin