select a.empid,a.dutydate,min(b.dtcardtime),max(b.dtcardtime)
from tvdutystd a
left join tcardtime b on a.ouguid=b.ouguid and a.cardno=b.cardno 
 and b.dtcardtime between a.rangest and a.rangeend
where a.dutydate between 20130401 and 20130410
#此用法，where條件要限制，因為會組成所有資料，
#取第一筆及全取，時間一樣
group by a.empid,a.dutydate
order by a.dutydate 
limit 2000;
 
#alter view v01 as
select a.empid,a.dutydate
,(select min(s.dtcardtime) from tcardtime s
where s.ouguid=a.ouguid and s.cardno=a.cardno
and s.dtcardtime between a.rangest and a.rangeend) realon
,(select max(s.dtcardtime) from tcardtime s
where s.ouguid=a.ouguid and s.cardno=a.cardno
and s.dtcardtime between a.rangest and a.rangeend) realoff
from tvdutystd a
where a.dutydate between 20130401 and 20130430
#此用法 where筆數多，不影響第一筆取回速度
#適合多筆資料使用
order by a.dutydate
limit 1;
 