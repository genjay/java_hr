delimiter $$

create procedure p_createDutyStd 
(in var_ouguid varchar(36),in var_dutydate int) 
begin 

declare yestoday int;
declare nextday int;
set yestoday=(select str_to_date(var_dutydate,'%Y%m%d')- interval 1 day)+0;
set nextday =(select str_to_date(var_dutydate,'%Y%m%d')+ interval 1 day)+0;

set sql_safe_updates=0;

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
,a.stdon,a.overon
,min(dtcardtime) realon
,max(dtcardtime) realoff
from tmpStd a
left join tcardtime b on b.ouguid=a.OUguid and a.cardno=b.cardno
and b.dtcardtime between a.rangest and a.rangeend
left join tdutyreal c on a.ouguid=a.ouguid and a.empguid=c.empguid
 and a.dutydate=(str_to_date(c.dutydate,'%Y%m%d')-interval 1 day)+0
 and b.dtcardtime>c.realoff
Where a.OUguid=var_ouguid and a.dutydate=var_dutydate
group by a.ouguid,a.empguid,a.dutydate,a.holiday
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
where b.ouguid=var_ouguid ;

insert into tmpRest
(ouguid,workguid,holiday,restno,cuttime,dutydate,restST,restEND,restMM)
select b.ouguid,b.workguid,b.holiday,b.restno,b.cuttime
,yestoday dutydate
,str_to_date(concat(yestoday,sthhmm),'%Y%m%d%H:%i')+interval stNext day restST
,str_to_date(concat(yestoday,enhhmm),'%Y%m%d%H:%i')+interval enNext day restEND
,minute(timediff(enhhmm,sthhmm)) restMM
from tworkrest b 
where b.ouguid=var_ouguid ;

insert into tmpRest
(ouguid,workguid,holiday,restno,cuttime,dutydate,restST,restEND,restMM)
select b.ouguid,b.workguid,b.holiday,b.restno,b.cuttime
,nextday dutydate
,str_to_date(concat(nextday,sthhmm),'%Y%m%d%H:%i')+interval stNext day restST
,str_to_date(concat(nextday,enhhmm),'%Y%m%d%H:%i')+interval enNext day restEND
,minute(timediff(enhhmm,sthhmm)) restMM
from tworkrest b 
where b.ouguid=var_ouguid ;

drop table if exists tmpRest2;
create temporary table tmpRest2 engine=memory
select sql_no_cache a.ouguid,a.workguid,a.holiday,a.restno,a.restST
,restst + interval b.rwid minute as restTime
,a.cuttime
from tmprest a
left join tserno b on b.rwid<=restmm;

drop table if exists tmprest;
end case;
end $$
delimiter ;
 
 


