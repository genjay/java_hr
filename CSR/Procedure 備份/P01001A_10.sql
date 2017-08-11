DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `P01001A_10`(varOUguid varchar(36),varDutyDate date)
begin

-- Call P01001A_10('microjet',20130502,'tperson')
-- 取得ouguid='microjet',tperson內所有人在 20130502 應該出勤之人員
-- output 至 P01001A_10_OUTPUT

declare yestoday date ;
declare nextday date;
set yestoday=(select varDutydate -interval 1 day);
set nextday =(select varDutydate +interval 1 day);


set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小

drop table if exists P01001A_10_OUTPUT;
create temporary table if not exists P01001A_10_OUTPUT engine=memory
select a.empguid,a.depguid,a.cardno
from tperson a
left join tdutya b on a.empguid=b.empguid and b.dutydate=varDutyDate  
where  
    varDutyDate>=a.arrivedate # 到職後才要出勤
and varDutyDate<=Case When a.leavedate>0 Then a.leavedate Else 29991231 end #離職前要出勤
and varDutyDate<=Case When  a.stopdate>0 Then  a.stopdate Else 29991231 End #留停前要出勤
and varOUguid=a.OUguid
and exists (select * from P01001a_tmp01 x where x.empguid=a.empguid)
and (b.status is null or b.status<'99'); # 未結案才計算

-- drop table if exists P01001A_10_tmp01;
 
end$$
DELIMITER ;
