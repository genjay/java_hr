DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `P01001A_30`(varOUguid varchar(36),varDutyDate date)
begin

-- Call P01001A_50('microjet',20130502)
-- 計算請假資料


declare yestoday date ;
declare nextday date;
set yestoday=(select varDutydate -interval 1 day);
set nextday =(select varDutydate +interval 1 day);

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小

-- delete from tdutya where status<'99' and ouguid=varouguid and dutydate=vardutydate
-- and empguid in (select empguid from P01001A_tmp01);
--   /*關帳status='99'*/;


delete from tdutyb  -- 刪除結轉日相關資料
where dutydate= varDutyDate 
and exists (select * from P01001A_tmp01 b where tdutyb.empguid=b.empguid)
and exists (select * from tdutya x where tdutyb.empguid=x.empguid
 and tdutyb.dutydate=x.dutydate and x.status<99);

drop table  if exists P01001A_30_TMP01;
create temporary table P01001A_30_TMP01 engine=memory
select 
 a.dutydate,a.holiday,a.empguid,a.workguid,a.workminutes,a.stdon,a.stdoff
,b.offtypeguid
,if(b.off_start<=a.stdon,a.stdon,b.off_start) calON
,if(b.off_end>=a.stdoff,a.stdoff,b.off_end)   calOff
,if(c.includeholiday,1,not a.holiday) Iscal
,c.offunit
from p01001a_20_output a
inner join toffdoc b on b.ouguid=varouguid and a.empguid=b.empguid 
   and (a.stdon between b.off_start and b.off_end or a.stdoff between b.off_start and b.off_end
	   or b.off_start between a.stdon and a.stdoff or b.off_end between a.stdon and a.stdoff) 
left join tofftype c on c.ouguid=varouguid and b.offtypeguid=c.offtypeguid
-- where cardno!='a00514' and offmins>480
;

drop table  if exists P01001A_30_TMP02;
create temporary table P01001A_30_TMP02 engine=memory
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


drop table if exists P01001A_30_TMP03;
create temporary table P01001A_30_TMP03 engine=memory as
select a.empguid,a.dutydate,a.offtypeguid,a.calon,a.caloff,a.workguid,a.offunit
,b.restST,b.restEnd
,f_minute(timediff(a.calon,a.caloff)) offMM
,Case When (b.restST is null and b.restEnd is null) Then 0 Else
 f_minute(timediff(
           IF( a.calon < b.restST ,b.restST,a.calon)
		  ,IF(a.caloff > b.restEnd ,restEnd,a.calOff))) End useRest
from P01001A_30_TMP01 a
left join p01001a_30_tmp02 b on a.holiday=b.holiday and a.workguid=b.workguid and 
  ((b.restST >= a.calon and b.restST <  a.caloff) or
  (b.restEnd >  a.calon and b.restEnd <= a.caloff) )
where not (stdon=calon and stdoff=caloff) -- 請整天的不需要計算，以workinfo 的workminutes當請假時間
-- and a.empguid='DF71A899-7818-46FE-8873-14B1D3780E7C'
-- and a.empguid='DAFF3F8D-A2B1-42F7-A35E-024DFE455876'
; -- order by offtypeguid,restno;


-- 將計算後資料，新增至 tdutyB

insert into tdutyb 
(ltpid,ouguid,empguid,dutydate,offtypeguid,offunit,offdutyon,offdutyoff,offdutyminutes) 
select 'P01001A_30',varOUguid,a.empguid,a.dutydate,a.offtypeguid,a.offunit,a.calon,a.caloff
,floor((offMM-sum(useRest))/offunit)*offunit 
 from P01001A_30_TMP03 a
group by varOUguid,a.empguid,a.dutydate,a.offtypeguid,offMM,offunit
union all
select 'P01001A_30',varOUguid,a.empguid,a.dutydate,a.offtypeguid,a.offunit,a.calon,a.caloff,b.workminutes  
from P01001A_30_TMP01 a 
left join tworkinfo b on a.workguid=b.workguid
where (stdon=calon and stdoff=caloff);



drop table  if exists P01001A_30_TMP01;
drop table  if exists P01001A_30_TMP02;
drop table  if exists P01001A_30_TMP03;
 

 
end$$
DELIMITER ;
