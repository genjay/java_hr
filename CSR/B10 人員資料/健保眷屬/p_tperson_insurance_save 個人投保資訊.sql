drop procedure if exists p_tperson_insurance_save;

delimiter $$

create procedure p_tperson_insurance_save
( 
 in_OUguid varchar(36)
,in_LtUser varchar(36)
,in_ltPid varchar(36)
,in_rwid int(10)  
,in_EmpID varchar(36)
,in_NHI_LV int(11)
,in_NHI_Valid_St  varchar(36)
,in_NHI_Valid_End varchar(36)
,in_NHI_typeZ19   varchar(36)
,in_labor_LV int(11)
,in_labor_Valid_St  varchar(36)
,in_labor_Valid_End varchar(36)
,in_labor_typeZ19   varchar(36)
,in_LP_LV int(11)
,in_LP_Valid_St     varchar(36)
,in_LP_Valid_End    varchar(36)
,in_LP_self_payRate    decimal(10,5)
,in_LP_company_payRate decimal(10,5)
,in_NHI_2nd_free int
,in_NHI_2nd_Note text
,in_Note         text
,out outMsg text
,out outRwid int
,out err_code int 
)
begin
/*  
*/

declare tlog_note text; 
declare in_Empguid,in_type_A16_guid varchar(36);
declare isCnt int;  
set err_code=0;set outRwid=0; set outMsg='p_tperson_insurance_save';
 
end # Begin