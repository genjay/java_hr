-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `P01001A_30`
(varOUguid varchar(36),varDutyDate int)
begin
declare yestoday int ;
declare nextday int;
set yestoday=(select (str_to_date(varDutyDate,'%Y%m%d')-interval 1 day)+0);
set nextday =(select (str_to_date(varDutyDate,'%Y%m%d')+interval 1 day)+0);

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小

drop table if exists P01001A_30_TMP01;
create temporary table P01001A_30_TMP01 engine=memory row_format=compressed
select sql_no_cache cardno,dtcardtime 
from tcardtime #tst01 v01 ## force index (itime,iouguid)
where ouguid=varOUguid 
and dtcardtime between yestoday and nextday;
#建立P01001A_30_TMP01的index，之後抓時間才不會很慢
alter table P01001A_30_TMP01 
 add index i01 (cardno) using btree;
 #add index idtcardtime (dtcardtime) using btree;


drop table if exists P01001A_30_OUTPUT;
create temporary table P01001A_30_OUTPUT engine=memory
select sql_no_cache
 a.empguid,a.dutydate,a.holiday,a.workguid
,a.stdon,a.stdoff,a.overon
,min(c.dtcardtime) realon
,max(c.dtcardtime) realoff
from P01001A_20_OUTPUT a
left join tdutyreal b on #a.ouguid=b.ouguid and 
 a.empguid=b.empguid
 and b.dutydate=((str_to_date(a.dutydate,'%Y%m%d')-interval 1 day)+0)
 and hour(timediff(b.realon,b.realoff))>2 #昨天上下班要差2小時以上，減少昨天錯誤資料造成今天抓不到正確時間
left join P01001A_30_TMP01 c # force index (itime,icardno) #tcardtime用
 on a.cardno=c.cardno #and a.ouguid=c.OUguid 
and c.dtcardtime between a.rangest and a.rangeend
and c.dtcardtime>=ifnull(b.realoff,'2000-01-01') #昨天下班時間後才使用
Where #a.OUguid=var_ouguid and
 a.dutydate=varDutyDate
group by #a.ouguid,
a.empguid,a.dutydate,a.holiday,a.workguid
,a.stdon,a.stdoff,a.overon
;
 
drop table if exists P01001A_20_OUTPUT;

drop table if exists P01001A_30_TMP01;
#*/
 
end