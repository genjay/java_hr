truncate csrhr.tperson;

insert into csrhr.tperson
(empguid,OUguid,empid,EmpName,ArriveDate,LeaveDate,stopDate,CardNo,DepGuid,Overtypeguid,isCheckIn_Z03,sex_z02,BirthDay,IDNumber,Marriage_Z13,type_Z12,type_Z14,Address_1,Address_2,School_info,email,tel_1,tel_2,type_Z15,type_Z16,type_Z17,tax1_rate,tax1_money,Welfare_rate)
Select empguid,OUguid,empid,EmpName,ArriveDate,LeaveDate,stopDate,CardNo,DepGuid,Overtypeguid,isCheckIn_Z03,sex_z02,BirthDay,IDNumber,Marriage_Z13,type_Z12,type_Z14,Address_1,Address_2,School_info,email,tel_1,tel_2,type_Z15,type_Z16,type_Z17,tax1_rate,tax1_money,Welfare_rate
from chi_hr.tperson;
 