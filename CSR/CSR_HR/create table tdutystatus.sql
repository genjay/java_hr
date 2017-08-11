create table tdutystatus as 
select a.ouguid,a.empguid
,b.cardno,b.dutydate,b.holiday,c.workguid
,b.stdon,b.stdoff,b.overon,b.buffermm,b.rangest,b.rangeend 
from tperson a
left join vdutystd b  on a.ouguid=b.ouguid and a.empid=b.empid and dutydate<=20130510
left join tworkinfo c on b.ouguid=c.ouguid and b.workid=c.workid
order by b.dutydate,a.empid;

select * from tdutystatus;

drop table tdutystatus;

where cardno='a00514';
 