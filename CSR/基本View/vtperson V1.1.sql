create or replace view vtperson as
Select 
a.rwid,a.OUguid,a.EmpID,a.EmpName,a.ArriveDate,a.LeaveDate,a.stopDate,a.CardNo
,a.BirthDay,a.IDNumber
,concat(A07.CodeID,' ',A07.CodeDesc) DepDesc
,concat(A02.CodeID,' ',A02.CodeDesc) OverDesc
,concat(Z03.codeID,' ',Z03.CodeDesc) isCheckIn_Z03 
from tperson a
left join tCatCode A07 On A07.OUguid=A.OUguid and A07.Codeguid=a.DepGuid And A07.OUguid=a.OUguid
left join tCatCode A02 On A02.OUguid=A.OUguid And A02.Codeguid=a.OverTypeGuid And A02.OUguid=a.OUguid
left join tCatCode Z03 On Z03.OUguid=A.OUguid And Z03.Syscode='Z03' And Z03.CodeID=a.isCheckIn_Z03
left join tCatCode Z02 On Z02.OUguid=A.OUguid And Z02.Syscode='Z02' And Z02.CodeID=a.Sex_Z02
;
 