drop procedure if exists p_tOUset_Insurance_save;

delimiter $$

create procedure p_tOUset_Insurance_save
( 
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36),
# in_Rwid     int,
in_typeA16  varchar(36),
in_typeZ21  varchar(36),
in_Rate    decimal(10,5),
in_self_payRate  decimal(10,5),
in_company_payRate  decimal(10,5),
in_note text,
out outMsg text,
out outRwid int,
out err_code int
)
begin

declare tlog_note text; 
declare isCnt int;  
declare in_typeA16_Guid varchar(36);
set err_code=0;set outRwid=0; set outMsg='p_tOUset_Insurance_save';

set outMsg=in_note;

if err_code=0 then # 10
  set isCnt=0;
  Select rwid,CodeGuid into isCnt,in_typeA16_Guid
  from tCatcode 
  where Syscode='A16' and OUguid=in_OUguid and codeID=in_typeA16;
  if isCnt=0 then set err_code=1; set outMsg='代號錯誤'; end if;

end if; # 10 

if 1 && err_code=0 then # 90 修改
  
insert into tOUset_Insurance
(OUguid,typeA16_Guid,type_Z21,Rate,self_payRate,company_payRate,Note)
Values
(in_OUguid
,in_typeA16_Guid
,in_typeZ21
,in_Rate
,in_self_payRate
,in_company_payRate
,in_Note
 )
on duplicate key update
Rate=in_Rate,
self_payRate=in_self_payRate,
company_payRate=in_company_payRate,
note=in_Note
;

end if; # 90 

end # Begin