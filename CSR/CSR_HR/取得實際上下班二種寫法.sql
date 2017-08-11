call p_createdutystd('htc','20130401');

Set @var_OUguid='htc';

drop table t2;

create table t1 engine=memory
 select a.ouguid,a.empguid,a.dutydate,a.holiday
,min(dtcardtime) realon
,max(dtcardtime) realoff
from tmpdutystd a
left join tcardtime b on b.ouguid=a.OUguid and a.cardno=b.cardno
and b.dtcardtime between a.rangest and a.rangeend
left join tdutyreal c on a.ouguid=a.ouguid and a.empguid=c.empguid
 and a.dutydate=(str_to_date(c.dutydate,'%Y%m%d')-interval 1 day)+0
 and b.dtcardtime>c.realoff
group by a.ouguid,a.empguid,a.dutydate,a.holiday
;
 
create table t2 engine=memory
select sql_no_cache a.ouguid,a.empguid,a.dutydate,a.holiday
,(select dtcardtime from tcardtime s where s.ouguid=a.ouguid and s.cardno=a.cardno
 and s.dtcardtime between a.rangest and a.rangeend
 and s.dtcardtime>c.realoff
 order by dtcardtime asc limit 1) realon
,(select dtcardtime from tcardtime s where s.ouguid=a.ouguid and s.cardno=a.cardno
 and s.dtcardtime between a.rangest and a.rangeend
 and s.dtcardtime>c.realoff
 order by dtcardtime desc limit 1) realoff
from tmpdutystd a
left join tdutyreal c on a.ouguid=@var_ouguid and a.empguid=c.empguid
 and a.dutydate=(str_to_date(c.dutydate,'%Y%m%d')-interval 1 day)+0 ;
 