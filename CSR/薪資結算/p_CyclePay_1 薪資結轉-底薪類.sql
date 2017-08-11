# 薪資結轉個人薪資部份payset

drop procedure if exists p_CyclePay_1;
delimiter $$

create procedure p_CyclePay_1(
 inOUguid varchar(36)
,inPayYYYYMM varchar(7)
,inPayYYYYMM_Seq varchar(3)
,inLoginGuid varchar(36)
)

begin

# 薪資結轉程式
# call p_CyclePay_1('microjet','201404','');

set @inOUguid=inOUguid;
set @inPayYYYYMM=replace(inPayYYYYMM,'-','');
set @inPayYYYYMM_Seq=if(inPayYYYYMM_Seq='','1',inPayYYYYMM_Seq);
set @inLoginGuid = inLoginGuid;

set sql_safe_updates=0;

# 取得該ou的每月天數及每日小時數
SELECT Days_per_Month,Hours_per_Day
into  @Days_per_Month,@Hours_per_Day
FROM csrhr.touset
where ouguid=@inOUguid;

drop table if exists tmp01;
create temporary table tmp01 as
select 
 a.empguid,a.payYYYYMM,a.PayYYYYMM_seq,a.Duty_Days,a.Range_Days,a.WorkMins
,b.PaytypeGuid,b.PayMoney,b.Payunit_z06   
,c.taxtype_z05
,(select b.codedesc from tcatcode2 b where b.syscode='z05' and code_value=taxtype_z05) taxtypedesc
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
and a.empguid in (select empguid from tperson where ouguid=@inOUguid)
and c.paytypeguid in 
    ('30f6c57b-e4ae-11e3-a9f9-000c29364755' /*底薪*/
    ,'30f888ab-e4ae-11e3-a9f9-000c29364755' /*伙食津貼*/
    );

drop table if exists tmp02;
create temporary table tmp02 as
select a.empguid,a.payYYYYMM,a.PayYYYYMM_seq,a.PaytypeGuid,codeseq
,Case 
 When a.days_per_month>'0' /*大於0，使用固定天數*/ and a.Payunit_z06='M' /*M代表月薪*/
 Then PayMoney*(@Days_per_Month-IF(Duty_Days=Range_Days,0,Range_Days-Duty_Days))/@Days_per_Month
 When a.days_per_month='0' /* 0，使用range_days*/ and a.Payunit_z06='M' /*M代表月薪*/
 Then PayMoney*Duty_Days/Range_Days
 When a.Payunit_z06='D' /*日薪*/ Then PayMoney/@Hours_per_Day*(a.WorkMins/60)
 When a.Payunit_z06='H' /*時薪*/ Then PayMoney*(a.WorkMins/60)
 Else '0'
 end Payamt /*當月可領金額*/
from tmp01 a;

insert into tcycle_pay
(empguid,PayYYYYMM,PayYYYYMM_seq,Paytypeguid
,Pay_Amt,Taxable_amt,Tax_free_Amt,ltpid,cruser)
select 
a.empguid,PayYYYYMM,PayYYYYMM_seq,a.paytypeguid 
,payamt
,if(b.Taxtype_z05='A',payamt,0) Taxable
,if(b.Taxtype_z05='B',payamt,0) Tax_Free  
,'p_CyclePay_1' pid
,@inLoginGuid
from tmp02 a
left join tpaytype b on a.paytypeguid=b.paytypeguid
on duplicate key update 
 taxable_amt =if(b.Taxtype_z05='A',payamt,0)
,Tax_free_Amt=if(b.Taxtype_z05='B',payamt,0)
,pay_amt=payamt
,ltpid='p_CyclePay_1'
,cruser=@inLoginGuid;

end;




 