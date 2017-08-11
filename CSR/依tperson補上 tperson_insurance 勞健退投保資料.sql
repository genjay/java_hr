truncate  tperson_insurance;

insert into tperson_insurance
(EmpGuid,NHI_LV,NHI_Valid_St,NHI_Valid_End
,NHI_typeZ19,labor_LV,labor_Valid_St,labor_Valid_End
,labor_typeZ19
,LP_LV
,LP_Valid_St,LP_Valid_End
,LP_self_payRate,LP_company_payRate,NHI_2nd_free,NHI_2nd_Note,Note)
Select 
 empguid,24000 nhi_lv,arrivedate,leavedate
,'A' nhi_typez19,24000 labor_lv,arrivedate labor_valid_st,leavedate labor_valid_end
,'A' labor_typez19
,32000 lp_lv
,arrivedate lp_valid_st
,leavedate lp_valid_end
,0 lp_self_payrate
,6 lp_company_payrate
,0 NHI_2nd_free
,'' NHI_2nd_Note
,'' note
from tperson a
On duplicate key update
 lp_valid_st= arrivedate;