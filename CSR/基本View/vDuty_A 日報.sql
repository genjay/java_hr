create or replace view vtDuty_A as 
Select 
Case 
 When instr(d.codeID,'-')>0 Then substring(d.codeID,1,instr(d.codeID,'-')-1)
 Else d.codeID end A00_DepID
,b.empID A01_empID
,b.OUguid  OUguid
,b.empName A02_empName
,a.dutydate,c.codeid workID,holiday,a.realOn,a.realOff
,date_format(realOn,'%h:%i') onTime,date_format(realOff,'%H:%i') OffTime
,format(a.overA/60,2) overA
,format(a.overB/60,2) overB
,format(a.overC/60,2) overC
,format(a.overH/60,2) overH
,format(a.overCh/60,2) overCh
,a.OffMins/60 OffMins,a.OffDesc 
,a.error_code
from tduty_a a
left join tperson b on a.empguid=b.empguid
left join tcatcode c on a.workguid=c.codeguid
left join tcatcode d on b.depguid =d.codeguid;


select substring('000',1,if(instr('000','-')=0,9,instr('000','-')-1)) from vtduty_a
where dutydate=20140828