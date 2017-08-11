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
#計算標準上下班時間放入temp table (tProc_dutySTD)
drop table if exists tProc_dutySTD;
create temporary table tProc_dutySTD engine=memory as
select a.ouguid,a.empguid,a.cardno
,b.dutydate
,d.workguid
,ifnull(c.holiday,b.holiday) holiday
,str_to_date(concat(b.dutydate,d.ondutyhhmm),'%Y%m%d%H:%i') stdON
,str_to_date(concat(b.dutydate,d.offdutyhhmm),'%Y%m%d%H:%i')
 +interval offnext*24*60 minute stdOff
,str_to_date(concat(b.dutydate,d.oversthhmm),'%Y%m%d%H:%i')
 +interval overnext*24*60 minute OverOn
,d.buffermm
,str_to_date(concat(b.dutydate, d.ondutyhhmm),'%Y%m%d%H:%i') 
 + interval -( d.RangeSt) minute RangeST
,str_to_date(concat(b.dutydate,d.offdutyhhmm),'%Y%m%d%H:%i') 
 + interval offnext*24*60+(d.RangeEnd) minute RangeEND
from tperson a
left join tdepsch b on a.ouguid=b.ouguid and b.depguid=a.depguid
left join tempsch c on a.ouguid=b.ouguid and c.empguid=a.empguid and b.dutydate=c.dutydate
left join tworkinfo d on a.ouguid=d.ouguid and d.workguid=ifnull(c.workguid,b.workguid)
where 
    b.dutydate>=a.arrivedate # 到職後才要出勤
and b.dutydate<=Case When a.leavedate>0 Then a.leavedate Else 29991231 end #離職前要出勤
and b.dutydate<=Case When  a.stopdate>0 Then  a.stopdate Else 29991231 End #留停前要出勤
and a.ouguid=var_ouguid
and b.dutydate=var_dutydate;

#用(tProc_dutySTD)算實際上下班時間
drop table if exists tProc_DutyReal;
create temporary table tProc_DutyReal engine=memory
select 
 a.ouguid,a.empguid,a.dutydate,a.holiday,a.workguid
,a.stdon,a.stdoff,a.overon
,min(dtcardtime) realon
,max(dtcardtime) realoff
from tProc_dutySTD a
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
drop table  if exists tProc_DutyRestSTD;
create table tProc_DutyRestSTD engine=memory
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

#create index i01 on tProc_DutyRestSTD (ouguid,workguid,holiday) using btree;

alter table tProc_DutyRestSTD 
 add index i01 (ouguid,workguid,holiday) using btree;

#產生出勤日使用休息時間狀況
drop table if exists tProc_DutyRestStatus;
create temporary table tProc_DutyRestStatus engine=memory
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
from tProc_DutyReal a
inner join tProc_DutyRestSTD b on a.ouguid=b.ouguid 
and a.workguid=b.workguid  
and a.holiday=b.holiday
and (a.realon between b.restST and b.restEND or
	a.realoff between b.restST and b.restEND or
    b.restST between a.realon and a.realoff or
    b.restEND between a.realOn and a.realOff)
#where a.empguid='C153AE60-B2A2-4300-BB33-48374A98E79F'
group by ouguid,empguid,dutydate,cuttime
;
alter table tProc_DutyRestStatus 
 add index i01 (ouguid,empguid,dutydate) using btree;

#drop table if exists tProc_DutyRestSTD;
end case;
end $$
delimiter ;
 
 


