delimiter $$
create procedure Get_Time (var_OUguid varchar(36),var_dutydate int)
begin
declare yestoday int;
declare nextday int;
set yestoday=(select (str_to_date(var_DutyDate,'%Y%m%d')-interval 1 day)+0);
set nextday =(select (str_to_date(var_DutyDate,'%Y%m%d')+interval 1 day)+0);

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小

drop table if exists plog;
create temporary table plog (sPP char(50),runtime time)  engine=memory;

insert into plog (spp,runtime) values ('tmpxx01前',(select curtime()));

drop table if exists tmpDtime;
create temporary table tmpDtime engine=memory
select ouguid,cardno,dtcardtime 
from tcardtime force index (itime,iouguid)
where ouguid=var_OUguid 
and dtcardtime between yestoday and nextday;
#建立tmpDtime的index，之後抓時間才不會很慢
alter table tmpDtime 
 add index iOU_cardno (ouguid,cardno) using btree,
 add index idtcardtime (dtcardtime) using btree;

drop table if exists tProc_DutyReal;
create temporary table tProc_DutyReal engine=memory
select 
 a.ouguid,a.empguid,a.dutydate,a.holiday,a.workguid
,a.stdon,a.stdoff,a.overon
,min(c.dtcardtime) realon
,max(c.dtcardtime) realoff
from tmpxx03 a
left join tdutyreal b on a.ouguid=b.ouguid and a.empguid=b.empguid
 and b.dutydate=((str_to_date(a.dutydate,'%Y%m%d')-interval 1 day)+0)
 and hour(timediff(b.realon,b.realoff))>2 #昨天上下班要差2小時以上，減少昨天錯誤資料造成今天抓不到正確時間
left join tmpDtime c # force index (itime,icardno) #tcardtime用
 on a.ouguid=c.OUguid and a.cardno=c.cardno
and c.dtcardtime between a.rangest and a.rangeend
and c.dtcardtime>=ifnull(b.realoff,'2000-01-01') #昨天下班時間後才使用
Where a.OUguid=var_ouguid and a.dutydate=var_dutydate
group by a.ouguid,a.empguid,a.dutydate,a.holiday,a.workguid
,a.stdon,a.stdoff,a.overon
;

insert into plog (spp,runtime) values ('結束',(select curtime()));

drop table if exists tmpDtime;

end$$