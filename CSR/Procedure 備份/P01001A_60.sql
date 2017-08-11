DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `P01001A_60`(varOUguid varchar(36),varDutyDate date)
begin

-- Call P01001A_60('microjet',20130502) 

declare yestoday date ;
declare nextday date;
set yestoday=(select varDutydate -interval 1 day);
set nextday =(select varDutydate +interval 1 day);

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小

-- P01001A_40_TMP01 
-- 產生dutydate 前一後一天的休息時間表

drop table  if exists P01001A_60_TMP01;
create temporary table P01001A_60_TMP01 engine=memory
select b.ouguid,b.workguid,b.holiday,b.restno,b.cuttime
,varDutyDate dutydate
,str_to_date(concat(varDutyDate,sthhmm),'%Y-%m-%d%H:%i:%s')+interval stNext day restST
,str_to_date(concat(varDutyDate,enhhmm),'%Y-%m-%d%H:%i:%s')+interval enNext day restEND
,f_minute(timediff(enhhmm,sthhmm)) restMM
from tworkrest b 
where b.ouguid=varOUguid  union all
select b.ouguid,b.workguid,b.holiday,b.restno,b.cuttime
,yestoday dutydate
,str_to_date(concat(yestoday,sthhmm),'%Y-%m-%d%H:%i:%s')+interval stNext day restST
,str_to_date(concat(yestoday,enhhmm),'%Y-%m-%d%H:%i:%s')+interval enNext day restEND
,f_minute(timediff(enhhmm,sthhmm)) restMM
from tworkrest b 
where b.ouguid=varOUguid  union all
select b.ouguid,b.workguid,b.holiday,b.restno,b.cuttime
,nextday dutydate
,str_to_date(concat(nextday,sthhmm),'%Y-%m-%d%H:%i:%s')+interval stNext day restST
,str_to_date(concat(nextday,enhhmm),'%Y-%m-%d%H:%i:%s')+interval enNext day restEND
,f_minute(timediff(enhhmm,sthhmm)) restMM
from tworkrest b 
where b.ouguid=varOUguid  ;

#create index i01 on P01001A_40_TMP01 (ouguid,workguid,holiday) using btree;

alter table P01001A_60_TMP01 
 add index iOU_work_holiday (workguid,holiday) using btree; #dutydate 不能加，很慢

#產生出勤日使用休息時間狀況
drop table if exists P01001A_60_OUTPUT;
create temporary table P01001A_60_OUTPUT engine=memory
select #a.ouguid,
a.empguid,a.dutydate
,Sum(Case 
 When b.restST<a.stdOn 
 Then f_minute(timediff(
           IF( a.realon between b.restST and b.restEnd,a.realon,b.restST)
		  ,IF(a.realoff between b.restST and b.restEnd,a.realOff,restEnd)))
 Else 0 end) restA
,Sum(Case 
 When b.restEnd>=a.stdOn and b.restST<a.stdOff
 Then f_minute(timediff(
           IF( a.realon between b.restST and b.restEnd,a.realon,b.restST)
		  ,IF(a.realoff between b.restST and b.restEnd,a.realOff,restEnd)))
 Else 0 end) restB
,Sum(Case 
When b.restEnd>a.stdOff
Then f_minute(timediff(
           IF( a.realon between b.restST and b.restEnd,a.realon,b.restST)
		  ,IF(a.realoff between b.restST and b.restEnd,a.realOff,restEnd)))
Else 0 end) restC
from P01001A_50_OUTPUT a
inner join P01001A_60_TMP01 b on #a.ouguid=b.ouguid and 
    a.workguid=b.workguid  
and a.holiday=b.holiday
and (a.realon between b.restST and b.restEND or
	a.realoff between b.restST and b.restEND or
    b.restST between a.realon and a.realoff or
    b.restEND between a.realOn and a.realOff)
#where a.empguid='C153AE60-B2A2-4300-BB33-48374A98E79F'
group by #ouguid,
empguid,dutydate
;
alter table P01001A_60_OUTPUT 
 add index iOU_Emp_dutydate (empguid,dutydate) using btree;


drop table  if exists P01001A_60_TMP01;

#*/
 
end$$
DELIMITER ;
