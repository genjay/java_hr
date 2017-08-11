
set @inOUguid='microjet';
set @inPayYYYYMM=replace('2014-04','-','');
set @inPayYYYYMM_Seq=0;

SELECT Days_per_Month,Hours_per_Day
into @Days_per_Month,@Hours_per_Day
FROM csrhr.touset
where ouguid=@inOUguid;

create table tmp03 as;

select /*請假計算基礎*/
a.empguid,sum(a.paymoney) OverBase
from tperson_payset a
Where paytypeguid in 
(select paytypeguid from touset_overpay 
 where dutytype='Off' and ouguid=@inouguid)
group by a.empguid;