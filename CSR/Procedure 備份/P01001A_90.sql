DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `P01001A_90`(varOUguid varchar(36),varDutyDate date)
begin

-- Call P01001A_90('microjet',20130502)
-- 利用 P01001A_30 & P01001A_40 產生日結資料

declare yestoday date ;
declare nextday date;
set yestoday=(select varDutydate -interval 1 day);
set nextday =(select varDutydate +interval 1 day);

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小

delete from tdutya where status<'99' and ouguid=varouguid and dutydate=vardutydate
and empguid in (select empguid from P01001A_tmp01);
--   /*關帳status='99'*/;

insert into tdutya 
(ouguid,empguid,dutydate,stdon,stdoff,stdoveron,workguid,realon,realoff,delayuse,workA,WorkB,WorkC,restA,restB,restC) 
select varouguid,
a.empguid,a.dutydate,a.stdon,a.stdoff,a.stdoveron,a.workguid,a.realon,a.realoff
,Case When a.realon between a.stdon and (stdon + interval a.delaybuffer minute) /*在彈性時間內才計算*/
 Then f_minute(timediff(a.realon,stdon) ) 
 Else 0 end  DelayUse
,f_minute(timediff(if(a.realon< a.stdon,a.realon,a.stdon),if(a.realoff<a.stdon,a.realoff,a.stdon))) WorkA /*上班前時間(分)*/
,f_minute(timediff(if(a.realon< a.stdon, a.stdon,a.realon),if(a.realoff<a.stdoff,a.realoff,a.stdoff))) WorkB /*上班工時含休息(分)*/
,f_minute(timediff(if(a.realon<a.stdoff,a.stdoff,a.realon),if(a.realoff<a.stdoff,a.stdoff,a.realoff))) WorkC /*下班後時間(分)*/
,b.restA,b.restB,b.restC 
from p01001a_50_output a
left join p01001a_60_output b on a.empguid=b.empguid and a.dutydate=b.dutydate 
;
 
end$$
DELIMITER ;
