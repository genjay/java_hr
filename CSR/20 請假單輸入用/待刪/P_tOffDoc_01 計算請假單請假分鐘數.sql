drop procedure if exists P_tOffDoc_01;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `P_tOffDoc_01`
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/
,inEmpGuid varchar(36)
,inOfftypeGuid varchar(36)
,inDtimeFr datetime
,inDtimeTo datetime
,out outOffMins dec(10,3)
,out ougMsg text
)
begin
# 計算請假單單人請假總分鐘數

#tmp01 該empguid，請假範圍內的出勤資料
/*
CALL P_tOffDoc_01 (
'microjet','a00514','',
'C153AE60-B2A2-4300-BB33-48374A98E79F'
,'31300A47-1320-47DB-BC6A-2E577DACDDFB'
,'2014-05-12 08:00:00','2014-05-12 10:00:00',@X);
*/

drop table if exists tmp01 ;
create temporary table tmp01  as
select 
 a.EmpGuid AS empguid,
 a.OUguid AS ouGuid,
 b.dutydate AS dutydate,
 ifnull(c.Holiday, b.Holiday) AS holiday,
 ifnull(c.WorkGuid, b.WorkGuid) AS workguid,
 (str_to_date(concat(b.dutydate, d.OnDutyHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OnNext_z04 day) AS Std_on,
 (str_to_date(concat(b.dutydate, d.OffDutyHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OffNext_z04 day) AS Std_off,
 (str_to_date(concat(b.dutydate, d.OverSTHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OverNext_z04 day) AS Over_on,
 ((str_to_date(concat(b.dutydate, d.OnDutyHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OnNext_z04 day) + interval -(d.RangeSt) minute) AS Range_on,
 ((str_to_date(concat(b.dutydate, d.OverSTHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OffNext_z04 day) + interval d.RangeEnd minute) AS Range_off
    from
        tperson a
        left join tschdep b ON a.DepGuid = b.DepGuid 
        left join tschemp c ON a.EmpGuid = c.EmpGuid and b.dutydate = c.dutydate 
        left join tworkinfo d ON d.WorkGuid = ifnull(c.WorkGuid, b.WorkGuid)
    where
        ((b.dutydate >= a.ArriveDate)
            and (b.dutydate <= (case when (a.LeaveDate > 0) then a.LeaveDate else 99991231 end))
            and (b.dutydate <= (case when (a.stopDate > 0)  then a.stopDate  else 99991231  end)))
          --  and a.ouguid=inOUguid
            and a.empGuid=inEmpGuid
            and inDtimeFr < /*std_off*/(str_to_date(concat(b.dutydate, d.OffDutyHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OffNext_z04 day)
            and inDtimeTo > /*std_on*/ (str_to_date(concat(b.dutydate, d.OnDutyHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OnNext_z04 day) 
;

#tmp02 該empguid，請假範圍內每個出勤日，請假起迄時間
drop table if exists tmp02;
create temporary table tmp02 as
select a.empguid,a.dutydate,a.holiday,a.workguid,a.Std_on,a.Std_off
,Case When inDtimeFr < std_on  Then std_on  Else inDtimeFr end dutyoff_ON
,Case When inDtimeTo > std_off Then std_off Else inDtimeTo end dutyoff_Off
from tmp01 a;

#-------產生休息時刻表
#tmp05_a 需產生休息時刻表的那幾天
#tmp05 休息時刻表
drop table if exists tmp05_a;

create temporary table tmp05_a (a_date date) as
select dutydate a_date
from tmp02;

insert into tmp05_a (a_date) select min(dutydate)-interval 1 day from tmp02;
insert into tmp05_a (a_date) select max(dutydate)+interval 1 day from tmp02; 

drop table if exists tmp05;
create temporary table tmp05 as 
 select a.workguid,a.holiday,a.cuttime,a.sthhmm,a.enhhmm
-- ,concat(inDutyDate,a.enhhmm) aa
,str_to_date(concat(A_date,a.sthhmm),'%Y-%m-%d%H:%i:%s') + interval stNext_z04 day restST
,str_to_date(concat(A_date,a.enhhmm),'%Y-%m-%d%H:%i:%s') + interval enNext_z04 day restEnd
from tworkrest a
inner join tcatcode b on a.workguid=b.codeguid
left join (select * from tmp05_a) c on 1=1 
where exists (select * from tmp01 b where b.workguid=a.workguid );
 
alter table tmp05 add index (workguid,holiday);

#------------
# 產生經過的休息時間明細
drop table if exists tmp03;
create temporary table tmp03 as
select a.empguid,dutydate,a.holiday,a.dutyoff_On,a.dutyoff_Off,"RestB" restType
,f_minute(timediff(
 Case When a.dutyoff_On <= b.restST Then b.restST Else a.dutyoff_On end  
,Case When a.dutyoff_Off >= b.restEnd Then b.restEnd Else a.dutyoff_Off end )) rest_Mins
,b.restST,b.restEnd
from tmp02 a
left join tmp05 b on a.workguid=b.workguid and a.holiday=b.holiday
Where
 /*使用到的休息*/ a.dutyoff_On < b.restEnd and a.dutyoff_Off > b.restST
 /*上班時間使用的休息*/ and a.std_on < b.restEnd and a.std_off > b.restST  ;

alter table tmp03 add index i01 (empguid,dutydate);

#--------
# 將每日休息時間日總
drop table if exists tmp04;
create temporary table tmp04 as
select a.empguid,a.dutydate,a.holiday,c.includeholiday
,Case 
 When a.holiday=1 and c.includeHoliday=0 Then 0 
  Else f_minute(timediff(dutyoff_on,dutyoff_off))-ifnull(b.sum_restMins,0)
  End offMins
from tmp02 a
left join (select empguid,dutydate,sum(rest_mins) sum_restMins
from tmp03 group by empguid,dutydate) b on a.empguid=b.empguid and a.dutydate=b.dutydate
left join tofftype c on c.offtypeguid=inOfftypeGuid ;

alter table tmp04 add index i01 (empguid);

#---


select offunit,offMin into @offunit,@offMin
from tofftype
where offtypeguid=inOfftypeGuid;

select 
Case 
 When sum(OffMins)=0 Then 0 
 When sum(offMins) < @offMin Then @offMin/60 #小於最少請假單位，則等於最少請假單位
 Else ceil(sum(offMins)/ @offunit)*@offunit /60
 End
into outOffMins
from tmp04
group by empguid;








end