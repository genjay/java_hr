DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `P01001A_40`(varOUguid varchar(36),varDutyDate date)
begin

-- Call P01001A_50('microjet',20130502)
-- 計算請假資料


declare yestoday date ;
declare nextday date;
set yestoday=(select varDutydate -interval 1 day);
set nextday =(select varDutydate +interval 1 day);

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小

-- 加班單加總成日結概念


delete from tdutyc  -- 刪除結轉日相關資料
where dutydate= varDutyDate 
and exists (select * from P01001A_tmp01 b where tdutyc.empguid=b.empguid)
and exists (select * from tdutya x where tdutyc.empguid=x.empguid
 and tdutyc.dutydate=x.dutydate and x.status<99);



-- 將計算後資料，新增至 tdutyc

insert into tdutyc
(ouguid,empguid,dutydate,overtypeguid,overduty_minutes)
select a.ouguid,a.empguid,a.dutydate,a.overtypeguid
,sum(a.overmins )
from toverdoc a
left join p01001a_20_output b on a.empguid=b.empguid and a.dutydate=b.dutydate
where a.dutydate=varDutyDate and a.ouguid=varOUguid
group by ouguid,empguid,dutydate,overtypeguid;

 

 
end$$
DELIMITER ;
