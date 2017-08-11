delimiter $$

create procedure p_createDutyStd 
(in var_ouguid varchar(36),in var_dutydate int) 
begin 

declare yestoday int;
declare nextday int;
set yestoday=(select str_to_date(var_dutydate,'%Y%m%d')- interval 1 day)+0;
set nextday =(select str_to_date(var_dutydate,'%Y%m%d')+ interval 1 day)+0;

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小

#delete from tmpdutystd where ouguid=var_ouguid and dutydate=var_dutydate;

#insert into tmpdutystd
#計算標準上下班時間放入temp table (tmpStd)
drop table if exists tmpStd;

create temporary table tmpStd engine=memory as
select a.ouguid,a.empguid,a.cardno,b.dutydate,b.workguid,b.holiday,b.stdON
,b.stdOff,b.OverOn,b.buffermm,b.RangeSt,b.RangeEnd
from tperson a
left join vdutystd b on a.empguid=b.empguid
where b.ouguid=var_ouguid and dutydate=var_dutydate;

drop table if exists t1;

#用(tmpStd)算實際上下班時間
create temporary table t1 engine=memory
select 
 a.ouguid,a.empguid,a.dutydate,a.holiday,a.workguid
,a.stdon,a.stdoff,a.overon
,min(dtcardtime) realon
,max(dtcardtime) realoff
from tmpStd a
left join tcardtime b on b.ouguid=a.OUguid and a.cardno=b.cardno
and b.dtcardtime between a.rangest and a.rangeend
left join tdutyreal c on a.ouguid=a.ouguid and a.empguid=c.empguid
 and a.dutydate=(str_to_date(c.dutydate,'%Y%m%d')-interval 1 day)+0
 and b.dtcardtime>c.realoff
Where a.OUguid=var_ouguid and a.dutydate=var_dutydate
group by a.ouguid,a.empguid,a.dutydate,a.holiday,a.workguid
,a.stdon,a.stdoff,a.overon
;

Case When 1=1 Then # 產生休息時間table
drop table  if exists tmpRest;
create table tmpRest engine=memory
select b.ouguid,b.workguid,b.holiday,b.restno,b.cuttime
,var_dutydate dutydate
,str_to_date(concat(var_dutydate,sthhmm),'%Y%m%d%H:%i')+interval stNext day restST
,str_to_date(concat(var_dutydate,enhhmm),'%Y%m%d%H:%i')+interval enNext day restEND
,minute(timediff(enhhmm,sthhmm)) restMM
from tworkrest b 
where b.ouguid=var_ouguid union all
select b.ouguid,b.workguid,b.holiday,b.restno,b.cuttime
,yestoday dutydate
,str_to_date(concat(yestoday,sthhmm),'%Y%m%d%H:%i')+interval stNext day restST
,str_to_date(concat(yestoday,enhhmm),'%Y%m%d%H:%i')+interval enNext day restEND
,minute(timediff(enhhmm,sthhmm)) restMM
from tworkrest b 
where b.ouguid=var_ouguid union all
select b.ouguid,b.workguid,b.holiday,b.restno,b.cuttime
,nextday dutydate
,str_to_date(concat(nextday,sthhmm),'%Y%m%d%H:%i')+interval stNext day restST
,str_to_date(concat(nextday,enhhmm),'%Y%m%d%H:%i')+interval enNext day restEND
,minute(timediff(enhhmm,sthhmm)) restMM
from tworkrest b 
where b.ouguid=var_ouguid ;

create index i01 on tmpRest (ouguid,workguid,holiday) using btree;

#產生出勤日使用休息時間狀況
drop table if exists t9;
create temporary table t9 engine=memory
select a.ouguid,a.empguid,a.dutydate,b.cuttime
,Sum(Case 
 When b.restST<a.stdOn 
 Then minute(timediff(
           IF( a.realon between b.restST and b.restEnd,a.realon,b.restST)
		  ,IF(a.realoff between b.restST and b.restEnd,a.realOff,restEnd)))
 Else 0 end) restA
,Sum(Case 
 When b.restEnd>=a.stdOn and b.restST<a.stdOff
 Then minute(timediff(
           IF( a.realon between b.restST and b.restEnd,a.realon,b.restST)
		  ,IF(a.realoff between b.restST and b.restEnd,a.realOff,restEnd)))
 Else 0 end) restB
,Sum(Case 
When b.restEnd>a.stdOff
Then minute(timediff(
           IF( a.realon between b.restST and b.restEnd,a.realon,b.restST)
		  ,IF(a.realoff between b.restST and b.restEnd,a.realOff,restEnd)))
Else 0 end) restC
from t1 a
inner join tmprest b on a.ouguid=b.ouguid 
and a.workguid=b.workguid  
and a.holiday=b.holiday
and (a.realon between b.restST and b.restEND or
	a.realoff between b.restST and b.restEND or
    b.restST between a.realon and a.realoff or
    b.restEND between a.realOn and a.realOff)
#where a.empguid='C153AE60-B2A2-4300-BB33-48374A98E79F'
group by ouguid,empguid,dutydate,cuttime
;

#drop table if exists tmprest;
end case;
end $$
delimiter ;
 
 


