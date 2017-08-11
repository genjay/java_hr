drop procedure if exists p_Duty_MonthSum;

delimiter $$

create procedure p_Duty_MonthSum(
 inOUguid varchar(36)
,inPayYYYYMM varchar(7)
,inDateFR date
,inDateTo date
,inPayYYYYMM_seq varchar(3) /*保留，用於每計算多次用*/
)

begin

set @inOUguid=inOUguid;
set @inPayYYYYMM= replace(inPayYYYYMM,'-','');
set @inDateFR=inDateFR;
set @inDateTo=inDateTo;
set @inPayYYYYMM_seq=if(inPayYYYYMM_seq='','1',inPayYYYYMM_seq);

set sql_safe_updates=0;

# 出勤月結程式

# call p_Duty_MonthSum('microjet','2014-05','2014-05-01','2014-05-31','');

drop table if exists tmp01;
create temporary table tmp01 as
select 
 empguid
,@inPayYYYYMM PayYYYYMM
,@inPayYYYYMM_seq PayYYYYMM_Seq
,@inDateFR DutyFr
,@inDateTo DutyTo
,count(a.empguid) duty_days /*該員工出勤天數*/
,abs(datediff(@inDateFR,@inDateTo))+1 range_days /*結轉範圍天數*/
,sum(a.WorkMins) WorkMins
from tduty_a a
Where  
    a.dutydate between @inDateFR and @inDateTo
and a.empguid in 
    (select empguid from tperson b where b.ouguid=@inOUguid)
Group by empguid;

drop table if exists tmp03;
/*
 抓取 tduty_sum_a 的rwid，用來下一段sql刪除用
1．該ou的人員
2．當期的資料 payyyyymm,payyyyymm_seq
3．未關帳資料
*/
create temporary table tmp03 as
select rwid tduty_sum_a_rwid from tduty_sum_a a
Where
 empguid in (select empguid from tperson b where b.ouguid=@inOUguid)
and /*當期資料*/a.PayYYYYMM=@inPayYYYYMM and a.PayYYYYMM_Seq=@inPayYYYYMM_Seq
and dutyStatus=0
; 

delete from tduty_sum_a 
Where rwid in (select tduty_sum_a_rwid from tmp03);

insert into tduty_sum_a
(
empguid,PayYYYYMM,PayYYYYMM_Seq,DutyFr,DutyTo,duty_days,range_days
,WorkMins
)
select 
empguid,PayYYYYMM,PayYYYYMM_Seq,DutyFr,DutyTo,duty_days,range_days
,WorkMins
from tmp01 a
Where 
Not exists (select * from tduty_sum_a b
 where a.empguid=b.empguid and a.payyyyymm=b.payyyyymm 
 and a.PayYYYYMM_Seq=b.PayYYYYMM_Seq);

#---------------------------------------------------------
/*以下為請假部份結轉
 是否關帳需join到 tduty_sum_a 的 dutyStatus
*/

drop table if exists tmp02 ;
create temporary table tmp02 as
select 
 a.empguid
,a.OfftypeGuid
,@inPayYYYYMM payYYYYMM
,@inPayYYYYMM_seq PayYYYYMM_Seq
,b.deduct_percent /*扣薪比率*/
,sum(DutyOffMins) OffMins 
,sum(DutyOffMins)*b.deduct_percent/100 deduct_payMins /*換算後，扣薪分鐘數*/
from tduty_b a
left join tofftype b on a.offtypeguid=b.offtypeguid
where a.dutydate between @inDateFR and @inDateTo
and empguid in (select empguid from tperson where ouguid=@inOUguid)
Group by a.empguid,a.OfftypeGuid,deduct_percent;

drop table if exists tmp03;
create temporary table tmp03 as /*卻刪除的rwid清單*/
select a.rwid tduty_sum_b_rwid from tduty_sum_b a
Where 
 /*該ou的人員*/ 
 empguid in (select b.empguid from tperson b where b.ouguid=@inOUguid)
and /*當期資料*/a.PayYYYYMM=@inPayYYYYMM and a.PayYYYYMM_Seq=@inPayYYYYMM_Seq
and /*未關帳資料*/
 exists (select * from tduty_sum_a b where a.empguid=b.empguid
 and a.PayYYYYMM=b.PayYYYYMM
 and a.PayYYYYMM_Seq=b.PayYYYYMM_Seq
 and b.dutyStatus='0') ; 

delete from tduty_sum_b
where rwid in (select tduty_sum_b_rwid from tmp03);

insert into tduty_sum_b
(
empguid,payYYYYMM,PayYYYYMM_Seq,OfftypeGuid
,OffMins,deduct_payMins)
select 
empguid,payYYYYMM,PayYYYYMM_Seq,OfftypeGuid
,OffMins,deduct_payMins
from tmp02 a
Where 
Not exists (select * from tduty_sum_b b 
 where 
     a.empguid=b.empguid
 and a.PayYYYYMM=b.PayYYYYMM
 and a.PayYYYYMM_Seq=b.PayYYYYMM_Seq);


#----加班部份結轉

drop table if exists tmp04;
create table tmp04 as
select a.empguid
-- ,a.OvertypeGuid
,@inPayYYYYMM
,@inPayYYYYMM_seq
,sum(a.OverA) OverA
,sum(a.OverB) OverB
,sum(a.OverC) OverC
,sum(a.OverH) OverH
,sum(a.PayAMins) PayAmins
,sum(a.PayBMins) PayBmins
,sum(a.PayCMins) PayCmins
,sum(a.PayHMins) PayHmins
from tDuty_C a
Where 
    a.empguid in (select empguid from tperson where ouguid=@inOUguid)
and a.dutydate between @inDateFR And @inDateTo
Group by a.empguid
-- ,a.Overtypeguid
;

drop table if exists tmp03;
create temporary table tmp03 as /*卻刪除的rwid清單*/
select a.rwid tduty_Over_sum_rwid from tduty_sum_c a
Where 
 /*該ou的人員*/ 
 empguid in (select b.empguid from tperson b where b.ouguid=@inOUguid)
and /*當期資料*/a.PayYYYYMM=@inPayYYYYMM and a.PayYYYYMM_Seq=@inPayYYYYMM_Seq
and /*未關帳資料*/
 exists (select * from tduty_sum_a b where a.empguid=b.empguid
 and a.PayYYYYMM=b.PayYYYYMM
 and a.PayYYYYMM_Seq=b.PayYYYYMM_Seq
 and b.dutyStatus='0') ; 


delete from tduty_sum_c 
Where rwid in (select tduty_Over_sum_rwid from tmp03);



select # 取該OU每月免稅加班額度(小時)
 Over_FreeTax_perMonth into @Over_FreeTax_perMonth
from touset
where ouguid=@inOUguid;


insert into tduty_sum_c
(
empguid,payYYYYMM,PayYYYYMM_seq
-- ,overtypeguid
,overA,overB,overC,OverH
,payAmins,payBmins,payCmins,payHmins
,TaxPayMins
)
select 
empguid,@inPayYYYYMM,@inPayYYYYMM_seq
-- ,overtypeguid
,overA,overB,overC,OverH
,payAmins,payBmins,payCmins,payHmins 
,IF((overA+overB+overC)>@Over_FreeTax_perMonth*60
   , (payAmins/overA) /*加班比率*/
     *(overA+overB+overC) -@Over_FreeTax_perMonth*60
   ,0) TaxMins
from tmp04;


end ;
