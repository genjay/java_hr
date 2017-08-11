set max_heap_table_size=512*8*1024*1024;#設定engine=memory 容量大小


create temporary table tmpTime engine=memory
select distinct cardno,dtcardtime from tcardtime 
where 
ouguid='htc' and 
dtcardtime between '2013-04-01 00:00' and '2013-04-03 00:00';

drop table tmptime;
drop table tmpdutystd;

create temporary table tmpdutystd engine=memory
select a.ouguid,a.empguid,a.cardno
,b.dutydate
,ifnull(c.holiday,b.holiday) holiday
,d.workid
,str_to_date(concat(b.dutydate,d.ondutyhhmm),'%Y%m%d%H:%i') stdON
,str_to_date(concat(b.dutydate,d.offdutyhhmm),'%Y%m%d%H:%i') stdOff
,str_to_date(concat(b.dutydate,d.oversthhmm),'%Y%m%d%H:%i') OverOn
,d.buffermm
,str_to_date(concat(b.dutydate, d.ondutyhhmm),'%Y%m%d%H:%i') + interval -( d.RangeSt) minute RangeST
,str_to_date(concat(b.dutydate,d.offdutyhhmm),'%Y%m%d%H:%i') + interval offnext*24*60+(d.RangeEnd) minute RangeEND
from tperson a
left join tdepsch b on a.ouguid=b.ouguid and b.depguid=a.depguid
left join tempsch c on a.ouguid=b.ouguid and c.empguid=a.empguid and b.dutydate=c.dutydate
left join tworkinfo d on a.ouguid=d.ouguid and d.workguid=ifnull(c.workguid,b.workguid)
where 
b.dutydate>=a.arrivedate 
and b.dutydate<=Case When a.leavedate>0 Then a.leavedate Else 29991231 end
and b.dutydate<=Case When  a.stopdate>0 Then  a.stopdate Else 29991231 End 
and b.dutydate=20130401
and a.arrivedate<=20130401
and (a.leavedate>20130401 or a.leavedate is null)
;
 
select * from tperson
where empid='a00514';
 
 
#insert into tdutyreal (ouguid,empguid,dutydate,workguid,realon,realoff)
select sql_no_cache a.ouguid,a.empguid,a.dutydate,a.workguid
,min(b.dtcardtime),max(b.dtcardtime)
,(select (s.dtcardtime) from tcardtime s
 where s.ouguid=a.ouguid and s.cardno=a.cardno
 and s.dtcardtime between a.rangest and a.rangeend
 and s.dtcardtime <=a.stdoff
 order by s.dtcardtime asc limit 1) realon2
,(select (s.dtcardtime) from tcardtime s
 where s.ouguid=a.ouguid and s.cardno=a.cardno
 and s.dtcardtime between a.rangest and a.rangeend
 and s.dtcardtime >=a.stdon
 order by s.dtcardtime desc limit 1) realoff2
from vdutystd a
left join tcardtime b on a.ouguid=b.ouguid and a.cardno=b.cardno
 and b.dtcardtime between a.rangest and a.rangeend
left join tdutyreal c on a.ouguid=c.ouguid and a.empguid=c.empguid
 and str_to_date(c.dutydate,'%Y%m%d')- interval 1 day=
     str_to_date(a.dutydate,'%Y%m%d') 
 and b.dtcardtime> c.realoff
where a.dutydate in (20130331,20130401,20130402);
# and a.empguid='FC8E6A8F-E259-4F12-95F4-E1EE1AD188B1'
group by a.ouguid,a.empguid,a.dutydate,a.workguid
;

select count(*) from vdutystd where ouguid='htc' and dutydate=20130402;
select * from tdutyreal a
left join tperson b on a.empguid=b.empguid
where a.ouguid='microjet' and b.empid='a02144';

select cardno,min(rwid) from tcardtime
where  dtcardtime>='2013-03-29';
 
select str_to_date(dutydate,'%Y%m%d')- interval 1 day from tmpdutystd;