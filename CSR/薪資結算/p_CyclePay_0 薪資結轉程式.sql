# 算薪主程式
drop procedure if exists p_CyclePay_0;
delimiter $$

create procedure p_CyclePay_0(
inOUguid varchar(36),
inPayYYYYMM varchar(7),
inPayYYYYMM_Seq varchar(3)
)

begin

# 算薪主程式
# call p_calpay_01('microjet',201404,1);

set @inOUguid=inOUguid;
set @inPayYYYYMM=replace(inPayYYYYMM,'-','');
set @inPayYYYYMM_Seq=if(inPayYYYYMM_Seq='','1',inPayYYYYMM_Seq);

set sql_safe_updates=0;

# 取得該ou的每月天數及每日小時數
SELECT Days_per_Month,Hours_per_Day
into  @Days_per_Month,@Hours_per_Day
FROM csrhr.touset
where ouguid=@inOUguid;

drop table if exists tmp01;
create table tmp01 as
select 
 a.empguid,a.payYYYYMM,a.PayYYYYMM_seq,a.Duty_Days,a.Range_Days,a.WorkMins
,b.PaytypeGuid,b.PayMoney,b.Payunit  
,d.codeseq
,e.days_per_month
from tduty_sum_a a
left join tperson_payset b on a.empguid=b.empguid
left join tpaytype c on b.paytypeguid=c.paytypeguid
left join tcatcode d on c.paytypeguid=d.codeguid
left join tOUset e on e.ouguid=@inOUguid
Where 
    a.PayYYYYMM=@inPayYYYYMM
and a.PayYYYYMM_Seq=@inPayYYYYMM_Seq
and a.empguid in (select empguid from tperson where ouguid=@inOUguid);

drop table if exists tmp02;
create table tmp02 as
select a.empguid,a.payYYYYMM,a.PayYYYYMM_seq,a.PaytypeGuid,codeseq
,Case 
 When a.days_per_month>'0' /*大於0，使用固定天數*/ and a.Payunit='M' /*M代表月薪*/
 Then PayMoney*(@Days_per_Month-IF(Duty_Days=Range_Days,0,Range_Days-Duty_Days))/@Days_per_Month
 When a.days_per_month='0' /* 0，使用range_days*/ and a.Payunit='M' /*M代表月薪*/
 Then PayMoney*Duty_Days/Range_Days
 When a.Payunit='D' /*日薪*/ Then PayMoney/@Hours_per_Day*(a.WorkMins/60)
 When a.Payunit='H' /*時薪*/ Then PayMoney*(a.WorkMins/60)
 Else '0'
 end Pay /*當月可領金額*/
from tmp01 a;




call p_CyclePay_OverDoc(@inOUguid,@inPayYYYYMM,@inPayYYYYMM_Seq);

call p_CyclePay_Offdoc(@inOUguid,@inPayYYYYMM,@inPayYYYYMM_Seq);

end;




 