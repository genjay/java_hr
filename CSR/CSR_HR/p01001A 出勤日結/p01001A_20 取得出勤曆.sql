-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `P01001A_20`
(varOUguid varchar(36),varDutyDate int)
begin
declare yestoday int ;
declare nextday int;
set yestoday=(select (str_to_date(varDutyDate,'%Y%m%d')-interval 1 day)+0);
set nextday =(select (str_to_date(varDutyDate,'%Y%m%d')+interval 1 day)+0);

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小

#串部門排班表
drop table if exists P01001A_20_tmp01;
create table P01001A_20_tmp01 engine=memory
select a.empguid,a.depguid,a.cardno
,b.dutydate
,ifnull(c.holiday,b.holiday) holiday
,ifnull(c.workguid,b.workguid) workguid
from P01001A_10_OUTPUT a
left join tdepsch b on a.depguid=b.depguid
left join tempsch c on a.empguid=c.empguid and b.dutydate=c.dutydate
where  
b.dutydate=varDutyDate ;

drop table if exists P01001A_10_OUTPUT;

#用串好的排班表(P01001A_20_OUTPUT)串班別資訊
drop table if exists P01001A_20_OUTPUT;
create temporary table P01001A_20_OUTPUT engine=memory
select a.empguid,a.cardno,a.dutydate,a.holiday,a.workguid
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
from P01001A_20_tmp01 a
left join tworkinfo b on a.workguid=b.workguid
where 
a.dutydate=varDutyDate;

drop table if exists P01001A_20_tmp01;
 
end