drop procedure if exists P_calDutyA;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `P_calDutyA`(inOUguid varchar(36),inDutyDate date,inTable varchar(50))
begin

declare yestoday date ;
declare nextday date;
declare next2day date;
set yestoday=(select inDutyDate -interval 1 day);
set nextday =(select inDutyDate +interval 1 day);
set next2day =(select inDutyDate +interval 2 day);

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory mb大小


if 1=1 then # 權限及人員範圍
 drop table if exists tmp_inputRWID ;
 
 if inTable in ('','all') Then 

 create temporary table tmp_inputRWID as
 select rwid from tperson where ouguid=inOUguid; 
 -- index 沒幫助 alter table tmp_inputRWID add index i01 (rwid);

 else 
 Set @sql= concat("create temporary table tmp_inputRWID as select rwid from ",inTable);
 prepare s1 from @sql;
 execute s1;
 
 -- index 沒幫助 alter table tmp_inputRWID add index i01 (rwid);
 
 end if;
 
end if;

if 2=2 Then # 產生應出勤資料
drop table if exists tmp01 ;

create   table tmp01  as
select 
 a.EmpGuid AS empguid,
 a.OUguid AS ouGuid,
 b.dutydate AS dutydate,
 ifnull(c.Holiday, b.Holiday) AS holiday,
 ifnull(c.WorkGuid, b.WorkGuid) AS workguid,
 (str_to_date(concat(b.dutydate, d.OnDutyHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OnNext day) AS Std_on,
 (str_to_date(concat(b.dutydate, d.OffDutyHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OffNext day) AS Std_off,
 (str_to_date(concat(b.dutydate, d.OverSTHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OverNext day) AS Over_on,
 ((str_to_date(concat(b.dutydate, d.OnDutyHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OnNext day) + interval -(d.RangeSt) minute) AS Range_on,
 ((str_to_date(concat(b.dutydate, d.OverSTHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OverNext day) + interval d.RangeEnd minute) AS Range_off,
 a.CardNo AS cardno
    from
        tperson a
        left join tschdep b ON a.DepGuid = b.DepGuid 
        left join tschemp c ON a.EmpGuid = c.EmpGuid and b.dutydate = c.dutydate 
        left join tworkinfo d ON d.WorkGuid = ifnull(c.WorkGuid, b.WorkGuid)
    where
        ((b.dutydate >= a.ArriveDate)
            and (b.dutydate <= (case when (a.LeaveDate > 0) then a.LeaveDate else 99991231 end))
            and (b.dutydate <= (case when (a.stopDate > 0) then a.stopDate else 99991231  end)))
            and a.ouguid=inOUguid
			and b.dutydate=inDutydate
			and a.rwid in  (select rwid from tmp_inputRWID );

alter table tmp01 add index i01 (ouguid,cardno);

end if ;

if 3=3 Then # 抓取所需要的tcardtime

drop table if exists tmp02;

create temporary table tmp02  as    
select  cardno,dtcardtime from tcardtime a
where ouguid='microjet'
and exists (select * from tmp01 b where a.ouguid=b.ouguid and a.cardno=b.cardno)
and a.dtcardtime 
 between str_to_date(inDutyDate,'%Y-%m-%d%h:%m')- interval 1 day
  and    str_to_date(inDutyDate,'%Y-%m-%d%h:%m')+ interval 2 day;

alter table tmp02 add index i01 (cardno) ;

 end if;

if 4=4 Then # 計算上下班時間

drop table if exists tmp03;
create  table tmp03   as
select empguid,min(b.dtcardtime) realOn,max(b.dtcardtime) realOff
from tmp01 a
left join tmp02 b on a.cardno=b.cardno
 and b.dtcardtime between a.range_on and a.range_off
group by empguid;

alter table tmp03 add index i01 (empguid);

drop table if exists tmp_Dutyreal;
create table tmp_Dutyreal as
select a.*,b.realOn,b.realOff 
,Case 
 When b.realOn < a.Std_on And b.realOff >= a.Std_on Then f_minute(timediff(b.realon,a.std_on)) else 0 end WorkA
,f_minute(timediff(IF(b.realOn < a.Std_on,a.Std_on,b.realOn)
,IF(b.realOff > a.Std_off,a.Std_off,b.realOff))) WorkB
,Case 
 When b.realOn < a.Std_off And b.realOff >= a.Std_off Then f_minute(timediff(b.realoff,a.std_off)) else 0 end WorkC
from tmp01 a
left join tmp03 b on a.empguid=b.empguid;

if 1=1 then 
drop table tmp01; # 應出勤時間班別
drop table tmp02; # 所需要的刷卡時間
drop table tmp03; # 計算後的上下班時間
end if ;

end if; # --------------------------------

if 5=5 Then # 產生休息時刻表

drop table if exists tmp05_a;
create table tmp05_a (a_date date);

insert into tmp05_a (a_date) values
(yestoday),(inDutyDate),(nextday),(next2day);

drop table if exists tmp05;
create table tmp05 as 
 select a.workguid,a.holiday,a.restno,a.cuttime,a.sthhmm,a.enhhmm
-- ,concat(inDutyDate,a.enhhmm) aa
,str_to_date(concat(A_date,a.sthhmm),'%Y-%m-%d%H:%i:%s') + interval stNext day restST
,str_to_date(concat(A_date,a.enhhmm),'%Y-%m-%d%H:%i:%s') + interval enNext day restEnd
from tworkrest a
inner join tcatcode b on a.workguid=b.codeguid
left join (select * from tmp05_a) c on 1=1
where b.OUguid=inOUguid;
 
alter table tmp05 add index (workguid,holiday);

end if;

if 6=6 Then # 計算使用休息時間明細

drop table if exists tmp_restUsed;
create table tmp_restUsed as
select a.empguid,dutydate,a.realon,a.realoff,"RestB" restType
,f_minute(timediff(
 Case When a.realOn <= b.restST Then b.restST Else a.realOn end  
,Case When a.realOff >= b.restEnd Then b.restEnd Else a.realOff end )) rest_Mins
,b.restST,b.restEnd
from tmp_dutyreal a
left join tmp05 b on a.workguid=b.workguid and a.holiday=b.holiday
Where
 /*使用到的休息*/ a.realon < b.restEnd and a.realoff > b.restST
 and a.std_on < b.restEnd and a.std_off > b.restST  /*上班時間使用的休息*/;

insert into tmp_restUsed
(empguid,dutydate,realon,realoff,restType,rest_Mins,restST,restEnd)
select a.empguid,dutydate,a.realon,a.realoff,"RestC" restType
,f_minute(timediff(
 Case When a.realOn <= b.restST Then b.restST Else a.realOn end  
,Case When a.realOff >= b.restEnd Then b.restEnd Else a.realOff end )) rest_Mins
,b.restST,b.restEnd
from tmp_dutyreal a
left join tmp05 b on a.workguid=b.workguid and a.holiday=b.holiday
Where
 /*使用到的休息*/ a.realon < b.restEnd and a.realoff > b.restST
 and b.restEnd > a.std_off /*下班後*/;

insert into tmp_restUsed
(empguid,dutydate,realon,realoff,restType,rest_Mins,restST,restEnd)
select a.empguid,dutydate,a.realon,a.realoff,"RestA" restType
,f_minute(timediff(
 Case When a.realOn <= b.restST Then b.restST Else a.realOn end  
,Case When a.realOff >= b.restEnd Then b.restEnd Else a.realOff end )) rest_Mins
,b.restST,b.restEnd
from tmp_dutyreal a
left join tmp05 b on a.workguid=b.workguid and a.holiday=b.holiday
Where
 /*使用到的休息*/ a.realon < b.restEnd and a.realoff > b.restST
 and b.restST < a.std_On /*上班前*/;


alter table tmp_restused add index i01 (empguid,dutydate);

drop table if exists tmp_restSum;
create table tmp_restSum as
select a.empguid,a.dutydate
,Sum(ifnull(b.rest_Mins,0)) RestA
,Sum(ifnull(c.rest_Mins,0)) RestB
,Sum(ifnull(d.rest_Mins,0)) RestC
from tmp_dutyreal a 
left join tmp_restused b on a.empguid=b.empguid and a.dutydate=b.dutydate
 and b.restType='RestA'
left join tmp_restused c on a.empguid=c.empguid and a.dutydate=c.dutydate
 and c.restType='RestB'
left join tmp_restused d on a.empguid=d.empguid and a.dutydate=d.dutydate
 and d.restType='RestC'
Group by a.empguid,a.dutydate
;

alter table tmp_restSum add index i01 (empguid,dutydate);

end if;

if 1=1 then

drop table if exists tmp_dutyRealB;
create table tmp_dutyRealB as
select @rownum:=@rownum+1 rwid,a.*, b.RestA,b.RestB,b.RestC
from tmp_dutyreal a
left join tmp_restSum b on a.empguid=b.empguid and a.dutydate=b.dutydate
left join (select @rownum:=0 ) c on 1=1;

alter table tmp_dutyRealB add index i01 (empguid,dutydate);

 
end if;

if 0=1 then # 刪除當日已關帳的tduty，新增未存在的資料

delete from tdutya  
where  dutystatus=0 and  dutydate=inDutyDate 
and exists 
(select * from tperson b where tdutya.empguid=b.empguid 
 and b.ouguid=inOUguid);

insert into tdutya
(empguid,dutydate,holiday,workguid,Std_on,Std_off,Over_on,Range_on,Range_off,cardno,realOn,realOff,WorkA,WorkB,WorkC,RestA,RestB,RestC)
select empguid,dutydate,holiday,workguid,Std_on,Std_off,Over_on,Range_on,Range_off,cardno,realOn,realOff,WorkA,WorkB,WorkC,RestA,RestB,RestC 
from tmp_dutyrealb a
where Not exists (select * from tdutya b where a.empguid=b.empguid
and a.dutydate=b.dutydate);

end if ;

if 1=1 Then 

drop table if exists tmp06a;
create table tmp06a as
# 將假單變成該出勤日起迄為依據
select a.rwid toffdoc_rwid,a.empguid,b.dutydate,b.workguid,b.holiday,offtypeguid,offdoc_unit
,if(a.offdoc_start<b.std_on,b.std_on,a.offdoc_start) dutyOff_On
,if(a.offdoc_end>b.std_off,b.std_off,a.offdoc_end)   dutyOff_Off
-- ,offdoc_start,offdoc_end
from toffdoc a
inner join tperson c on a.empguid=c.empguid
left join tdutya b on a.empguid=b.empguid and offdoc_start<std_off
and offdoc_end>std_on
where c.ouguid=inOUguid and b.dutydate=inDutydate;



drop table if exists tmp06b;
create table tmp06b as 
# 每筆請假串上經過的休息時間
select a.toffdoc_rwid
,IF(a.dutyOff_On >b.restST,a.dutyOff_On,b.restST) restUse_On
,IF(a.dutyOff_Off<b.restEnd,a.dutyOff_Off,b.restEnd) restUse_Off
,f_minute(timediff(
 IF(a.dutyOff_On >b.restST,a.dutyOff_On,b.restST) 
,IF(a.dutyOff_Off<b.restEnd,a.dutyOff_Off,b.restEnd) 
)) restMins
-- ,b.*
from tmp06a a
left join tmp05 b on a.workguid=b.workguid and a.holiday=b.holiday
Where 
  a.dutyOff_On < b.restEnd and a.dutyOff_Off > b.restST;

alter table tmp06b add index i01 (toffdoc_rwid);

drop table if exists tmp06c;
create table tmp06c as 
#準備匯入tdutyb的資料，每人每假別只會有一筆
select a.empguid,a.dutydate,offtypeguid,
ceil((f_minute(timediff(dutyOff_on,dutyOff_Off))-ifnull(sum_restMins,0))/offdoc_unit)
 *offdoc_unit
OffMins
from tmp06a a
left join (select toffdoc_rwid,Sum(restMins) sum_restMins from tmp06b
group by toffdoc_rwid) b on a.toffdoc_rwid=b.toffdoc_rwid
group by a.empguid,a.dutydate,offtypeguid;
 
delete from tdutyb
where dutydate=inDutyDate 
and exists (select * from tdutya b where tdutyb.empguid=b.empguid
 and tdutyb.dutydate=b.dutydate and b.dutystatus=0)
and exists (select * from tperson b where tdutyb.empguid=b.empguid
 and b.ouguid=inOUguid);
 
insert into tdutyb
(empguid,dutydate,offtypeguid,OffMins)
select empguid,dutydate,offtypeguid,OffMins
from tmp06c a
where Not exists (select * from tdutyb b where a.empguid=b.empguid
 and a.dutydate=b.dutydate);

end if ;

-- 日報tdutyc 加班單部份

drop table if exists tmp07;
create table tmp07 as
select empguid,dutydate,overtypeguid
,sum(OverMins) Sum_OverMins,sum(Holiday_OverMins) Sum_Holiday_OverMins
from toverdoc
where dutydate=inDutyDate
and exists (select * from tperson b 
where toverdoc.empguid=b.empguid and b.ouguid=inOUguid)
Group by empguid,dutydate,overtypeguid;

drop table if exists tmp07b;
create table tmp07b as
select 
a.empguid,a.dutydate,a.overtypeguid
,Case When Sum_OverMins between         0 and OverAMins Then Sum_OverMins Else OverAMins end OverA
,Case When Sum_OverMins between OverAMins and OverAMins+OverBMins Then Sum_OverMins-OverAMins Else 0 end OverB
,Case When Sum_OverMins between OverAMins+OverBMins and OverAMins+OverBMins+OverCMins Then Sum_OverMins-OverAMins-OverBMins Else 0 end OverC
,Sum_holiday_OverMins OverH
-- ,b.OverAMins,b.OverBMins,b.OverCMins,b.HoverPay
from tmp07 a
left join tovertype b on a.overtypeguid=b.overtypeguid ;

alter table tmp07b add index i01 (empguid,dutydate,overtypeguid);

delete from tdutyC
where dutydate=inDutyDate 
and exists (select * from tdutya b where tdutyC.empguid=b.empguid
 and tdutyC.dutydate=b.dutydate and b.dutystatus=0)
and exists (select * from tperson b where tdutyC.empguid=b.empguid
 and b.ouguid=inOUguid);

# 因為給錢加班，補休加班，並無限制一日內不能同時發生
# 所以在分完ABC時段後，要在相加
insert into tdutyC
(empguid,dutydate,overtypeguid,overa,overb,overc,overh)
select empguid,dutydate,overtypeguid,Sum(overa),Sum(overb),Sum(overc),Sum(overh)
from tmp07b a
where Not exists
(select * from tdutyC b where a.empguid=b.empguid
 and a.dutydate=b.dutydate and a.overtypeguid=b.overtypeguid)
Group by empguid,dutydate,overtypeguid;


end