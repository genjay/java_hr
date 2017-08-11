# 薪資結轉加班單部份

drop procedure if exists p_CyclePay_OverDoc;
delimiter $$

create procedure p_CyclePay_OverDoc(
inOUguid varchar(36),
inPayYYYYMM varchar(7),
inPayYYYYMM_Seq varchar(3)
)

begin

# 薪資結轉程式
# call p_CyclePay_OverDoc('microjet',201404,'1');

set @inOUguid=inOUguid;
set @inPayYYYYMM=replace(inPayYYYYMM,'-','');
set @inPayYYYYMM_Seq=if(inPayYYYYMM_Seq='','1',inPayYYYYMM_Seq);

set sql_safe_updates=0;

# 取得該ou的每月天數及每日小時數
SELECT Days_per_Month,Hours_per_Day
into  @Days_per_Month,@Hours_per_Day
FROM csrhr.touset
where ouguid=@inOUguid;

## 加班部份

drop table if exists tmp03;
create table tmp03 as
select # 產生加班時薪
 a.empguid,a.Overtypeguid 
,Sum(
 Case 
 When d.Paytype = 'B' /*加班費固定金額*/ Then d.OverAmt_Per_Hr
 When d.Paytype = 'A' /*一般加班計算方式*/ And PayUnit = 'M' Then PayMoney/ @Days_per_Month/@Hours_per_Day
 When d.Paytype = 'A' /*一般加班計算方式*/ And PayUnit = 'D' Then PayMoney/ @Hours_per_Day
 When d.Paytype = 'A' /*一般加班計算方式*/ And PayUnit = 'H' Then PayMoney
 When d.Paytype = 'C' /*補休*/ Then  '0' 
 end) Money_perHour  
from tduty_sum_c a
left join tOverType d on d.Overtypeguid=a.Overtypeguid
left join tOverType_Base b on a.Overtypeguid=b.Overtypeguid
left join tperson_payset c on a.empguid=c.empguid and b.Paytypeguid=c.paytypeguid
Where 
    a.empguid in (select empguid from tperson where ouguid=@inOUguid)
and a.PayYYYYMM     = @inPayYYYYMM
and a.PayYYYYMM_Seq = @inPayYYYYMM_Seq
Group by a.empguid,a.Overtypeguid ;

drop table if exists tmp04;
create table tmp04 as
select /*加班給薪*/
 a.empguid,a.Overtypeguid ,a.PayYYYYMM,a.PayYYYYMM_seq
,(a.PayAmins+a.PayBmins+a.PayCmins+a.PayHmins) /60 
*b.Money_perHour /*加班費*/ Overpay 
,a.TaxPayMins/60*b.Money_perHour /*應稅加班費*/ TaxPay
from tduty_sum_c a 
left join tmp03 b on a.empguid=b.empguid and a.overtypeguid=b.overtypeguid
Where
 a.empguid in (select empguid from tperson where ouguid=@inOUguid)
and a.PayYYYYMM     = @inPayYYYYMM
and a.PayYYYYMM_seq = @inPayYYYYMM_seq
;

drop table if exists tmp_fordel;

delete from tpayment_over  
where # 刪除已經無單頭的資料
     empguid in (select empguid from tperson where ouguid=@inOUguid)
 and PayYYYYMM=@inPayYYYYMM and PayYYYYMM_seq=@inPayYYYYMM_seq
 and 
 Not exists
 (select * from tcycle_pay_head b 
 where  
	 tpayment_over.empguid=b.empguid 
 and tpayment_over.payYYYYMM=b.PayYYYYMM
 and tpayment_over.PayYYYYMM_seq=b.PayYYYYMM_seq);

create temporary table tmp_fordel as
select a.rwid /*抓取tpayment_over未關帳相關資料的rwid,用來刪除*/
from tpayment_over  a
where 
 a.empguid in (select empguid from tperson where ouguid=@inOUguid)
and a.PayYYYYMM=@inPayYYYYMM
and a.PayYYYYMM_seq=@inPayYYYYMM_seq
and exists
 (select * from tcycle_pay_head b
 where a.empguid=b.empguid and a.PayYYYYMM=b.PayYYYYMM
 and a.PayYYYYMM_seq=b.PayYYYYMM_seq
 and b.CloseStatus='0')
;

delete from tpayment_over # 刪除當期未關帳相關資料
where rwid in (select rwid from tmp_fordel);

insert into tpayment_over
(empguid,overtypeguid,payYYYYMM,PayYYYYMM_seq,Overpay,Taxpay)
select empguid,overtypeguid,payYYYYMM,PayYYYYMM_seq,Overpay,Taxpay
from tmp04 a
Where 
 Not exists (select * from tpayment_over b
 where a.empguid=b.empguid and a.payYYYYMM=b.payYYYYMM
 and a.PayYYYYMM_seq=b.PayYYYYMM_seq
 and a.overtypeguid=b.overtypeguid);

delete from tcycle_pay  
where 
     empguid in (select empguid from tperson where ouguid=@inOUguid)
 and payYYYYMM = @inPayYYYYMM
 and PayYYYYMM_seq = @inPayYYYYMM_seq  
 and # 排除已經關帳資料
 Not exists 
 (select * from tcycle_pay_head b
 where tcycle_pay.empguid=b.empguid and tcycle_pay.payyyyymm=b.payyyyymm
 and tcycle_pay.payyyyymm_seq=b.payyyyymm_seq
 and b.closestatus>'0');

insert into tcycle_pay
(empguid,PayYYYYMM,PayYYYYMM_seq,PayTypeguid,Pay_amt,Taxable_amt,Tax_free_Amt)
select empguid,PayYYYYMM,PayYYYYMM_seq
,Overtypeguid PayTypeguid
,Round(OverPay,0) Pay_amt
,Round(TaxPay,0) Taxable_amt
,Round(OverPay,0)-Round(TaxPay,0) Tax_free_Amt
from tpayment_over a
where 
 empguid in (select empguid from tperson where ouguid=@inOUguid)
and payYYYYMM=@inPayYYYYMM
and PayYYYYMM_seq=@inPayYYYYMM_seq
and Not exists 
	 (select * from tcycle_pay b where a.empguid=b.empguid
      and a.payYYYYMM=b.PayYYYYMM and a.PayYYYYMM_seq=b.PayYYYYMM_seq);

################################################
#######  加班費部份結束
################################################

end;




 