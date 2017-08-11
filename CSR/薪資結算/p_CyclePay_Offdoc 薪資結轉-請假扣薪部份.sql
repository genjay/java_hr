# 每月薪資請假扣薪部份

drop procedure if exists p_CyclePay_Offdoc;
delimiter $$


create procedure p_CyclePay_Offdoc(
inOUguid varchar(36),
inPayYYYYMM varchar(7),
inPayYYYYMM_Seq varchar(3)
)

begin

# 薪資結轉程式

set @inOUguid=inOUguid;
set @inPayYYYYMM=replace(inPayYYYYMM,'-','');
set @inPayYYYYMM_Seq=if(inPayYYYYMM_Seq='','1',inPayYYYYMM_Seq);

set sql_safe_updates=0;

# 取得該ou的每月天數及每日小時數
SELECT Days_per_Month,Hours_per_Day
into  @Days_per_Month,@Hours_per_Day
FROM csrhr.touset
where ouguid=@inOUguid;

######################################################
### 請假扣款部份
######################################################

drop table if exists tmp03;
create table tmp03 as
select  /*請假扣薪基礎每小時多少錢*/
 a.empguid,a.offtypeguid  
,Sum(
 Case 
 When PayUnit = 'M' Then PayMoney/ @Days_per_Month/@Hours_per_Day
 When PayUnit = 'D' Then PayMoney/ @Hours_per_Day
 When PayUnit = 'H' Then PayMoney
 end) Money_perHour 
 -- ,(select codedesc from tcatcode x where a.offtypeguid=x.codeguid) offtype
from tduty_sum_b a
inner join tofftype_base b on a.Offtypeguid=b.Offtypeguid
left join tperson_payset c on a.empguid=c.empguid and b.paytypeguid=c.paytypeguid 
Where 
    a.empguid in (select empguid from tperson where ouguid=@inOUguid)
and a.PayYYYYMM    = @inPayYYYYMM
and a.PayYYYYMM_Seq= @inPayYYYYMM_Seq
Group by empguid,offtypeguid;

alter table tmp03 add index i01 (empguid,offtypeguid);

drop table if exists tmp04;
create table tmp04 as
select /*請假扣薪*/
 a.empguid,a.payYYYYMM,a.PayYYYYMM_Seq,a.Offtypeguid 
,OffMins
-- ,(select codedesc from tcatcode where a.offtypeguid=codeguid)
,ifnull(deduct_payMins/60*Money_perhour ,0) Deduct_Money
from tduty_sum_b a
left join tmp03 b on a.empguid=b.empguid and a.offtypeguid=b.offtypeguid
Where 
    a.empguid in (select empguid from tperson where ouguid=@inOUguid)
and a.payYYYYMM    = @inPayYYYYMM
and a.PayYYYYMM_Seq= @inPayYYYYMM_Seq;

/* tmp_fordel 刪除
  該OU、YYYYMM、seq、及未關帳的資料清單
*/
delete from tpayment_off  
where # 刪除已經無單頭的資料
     empguid in (select empguid from tperson where ouguid=@inOUguid)
 and PayYYYYMM=@inPayYYYYMM and PayYYYYMM_seq=@inPayYYYYMM_seq
 and 
 Not exists
 (select * from tcycle_pay_head b 
 where  
	 tpayment_off.empguid=b.empguid 
 and tpayment_off.payYYYYMM=b.PayYYYYMM
 and tpayment_off.PayYYYYMM_seq=b.PayYYYYMM_seq);


drop table if exists tmp_fordel;
create temporary table tmp_fordel as
select a.rwid from tcycle_pay_head  a
where 
 a.empguid in (select empguid from tperson where ouguid=@inOUguid)
and a.PayYYYYMM    = @inPayYYYYMM
and a.PayYYYYMM_seq= @inPayYYYYMM_seq
and exists
 (select * from tcycle_pay_head b
 where a.empguid=b.empguid and a.PayYYYYMM=b.PayYYYYMM
 and a.PayYYYYMM_seq=b.PayYYYYMM_seq
 and b.CloseStatus='0')
;

delete from tpayment_off
where rwid in (select rwid from tmp_fordel);

drop table if exists tmp_fordel;

insert into tpayment_off
(empguid,payYYYYMM,payYYYYMM_seq,Offtypeguid,Deduct_Money,OffMins)
select empguid,payYYYYMM,payYYYYMM_seq,Offtypeguid,Deduct_Money,OffMins
from tmp04 a
Where Not exists (select * from tpayment_off
Where 
    a.empguid      =tpayment_off.empguid
and a.payYYYYMM    =tpayment_off.PayYYYYMM
and a.PayYYYYMM_seq=tpayment_off.PayYYYYMM_seq
and a.Offtypeguid  =tpayment_off.Offtypeguid);


insert into tcycle_pay_head
# 新增未存在的單頭資料
(empguid,payYYYYMM,PayYYYYMM_seq,closeStatus)
select empguid,payYYYYMM,PayYYYYMM_seq,'0'
from tmp04 a
Where 
  Not exists (select * from tcycle_pay_head b where a.empguid=b.empguid 
  and a.payYYYYMM=b.PayYYYYMM and a.PayYYYYMM_seq=b.PayYYYYMM_seq)
Group by empguid,payYYYYMM,PayYYYYMM_seq;


insert into tcycle_pay
(empguid,PayYYYYMM,PayYYYYMM_seq,PayTypeguid,Pay_amt,Taxable_amt,Tax_free_Amt)
select 
 empguid
,PayYYYYMM
,PayYYYYMM_seq
,Offtypeguid PayTypeguid
,-1 * Round(Deduct_Money,0) Pay_amt
,-1 * Round(Deduct_Money,0) Taxable_amt
,'0' Tax_free_Amt
from tmp04 a
where Deduct_Money > 0 
 and Not exists 
	 (select * from tcycle_pay b where a.empguid=b.empguid
      and a.payYYYYMM=b.PayYYYYMM and a.PayYYYYMM_seq=b.PayYYYYMM_seq);



##############################
### 請假部份結束  
##############################


 

end;




 