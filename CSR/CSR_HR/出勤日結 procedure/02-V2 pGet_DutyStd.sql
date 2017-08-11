delimiter $$

create procedure Get_DutyStd (varOUguid varchar(36),varDutyDate int)
begin
declare yestoday int ;
declare nextday int;
set yestoday=(select (str_to_date(varDutyDate,'%Y%m%d')-interval 1 day)+0);
set nextday =(select (str_to_date(varDutyDate,'%Y%m%d')+interval 1 day)+0);

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小

drop table if exists plog;
create temporary table plog (sPP char(50),runtime time)  engine=memory;

insert into plog (spp,runtime) values ('tmpxx01前',(select curtime()));

#串部門排班表
drop table if exists tmpXX01;
create table tmpXX01 engine=memory
select a.ouguid,a.empguid,a.depguid,a.cardno
,b.dutydate
,ifnull(c.holiday,b.holiday) holiday
,ifnull(c.workguid,b.workguid) workguid
from tmpdutyemp a
left join tdepsch b on a.ouguid=b.ouguid and a.depguid=b.depguid
left join tempsch c on a.ouguid=c.ouguid and a.empguid=c.empguid and b.dutydate=c.dutydate
where a.ouguid=varouguid and b.dutydate=varDutyDate ;

#用串好的排班表(tmpxx02)串班別資訊
drop table if exists tmpxx03;
create temporary table tmpxx03
select a.ouguid,a.empguid,a.cardno,a.dutydate,a.holiday,a.workguid
,str_to_date(concat(a.dutydate,b.ondutyhhmm),'%Y%m%d%H:%i') stdON
,str_to_date(concat(a.dutydate,b.offdutyhhmm),'%Y%m%d%H:%i')
 +interval offnext*24*60 minute stdOff
,str_to_date(concat(a.dutydate,b.oversthhmm),'%Y%m%d%H:%i')
 +interval overnext*24*60 minute OverOn
,b.buffermm
,str_to_date(concat(a.dutydate, b.ondutyhhmm),'%Y%m%d%H:%i') 
 + interval -( b.RangeSt) minute RangeST
,str_to_date(concat(a.dutydate,b.offdutyhhmm),'%Y%m%d%H:%i') 
 + interval offnext*24*60+(b.RangeEnd) minute RangeEND
from tmpxx01 a
left join tworkinfo b on a.ouguid=b.ouguid and a.workguid=b.workguid
where a.ouguid=varouguid 
and a.dutydate=varDutyDate;

insert into plog (spp,runtime) values ('tmpxx03後',(select curtime()));


drop table if exists tmpXX01;



end$$