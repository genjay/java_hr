DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `P01001A_50`(varOUguid varchar(36),varDutyDate date)
begin

-- Call P01001A_50('microjet',20130502) 

declare yestoday date ;
declare nextday date;
set yestoday=(select varDutydate -interval 1 day);
set nextday =(select varDutydate +interval 1 day);

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小

drop table if exists P01001A_50_TMP01;
create temporary table P01001A_50_TMP01 engine=memory -- row_format=compressed
select sql_no_cache cardno,dtcardtime 
from tcardtime #tst01 v01 ## force index (itime,iouguid)
where ouguid=varOUguid 
and dtcardtime between yestoday and str_to_date(concat(nextday,'23:59'),'%Y-%m-%d%H:%i');
#建立P01001A_30_TMP01的index，之後抓時間才不會很慢
alter table P01001A_50_TMP01 
 add index i01 (cardno) using btree;
 #add index idtcardtime (dtcardtime) using btree;


drop table if exists P01001A_50_OUTPUT;
create temporary table P01001A_50_OUTPUT engine=memory
select sql_no_cache
 a.empguid,a.dutydate,a.holiday,a.workguid
,a.stdon,a.stdoff,a.stdoveron,a.delaybuffer
,min(c.dtcardtime) realon
,max(c.dtcardtime) realoff
from P01001A_20_OUTPUT a 
left join P01001A_50_TMP01 c # force index (itime,icardno) #tcardtime用
 on a.cardno=c.cardno #and a.ouguid=c.OUguid 
and c.dtcardtime between a.rangest and a.rangeend 
Where #a.OUguid=var_ouguid and
 a.dutydate=varDutyDate
group by #a.ouguid,
a.empguid,a.dutydate,a.holiday,a.workguid
,a.stdon,a.stdoff,a.stdoveron,a.delaybuffer
;
create index iEmp on P01001A_50_OUTPUT (EMPGUID);
 
-- drop table if exists P01001A_20_OUTPUT;

-- drop table if exists P01001A_50_TMP01;
#*/
 
end$$
DELIMITER ;
