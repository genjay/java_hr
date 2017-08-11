drop procedure if exists p_Duty_DaySum;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_Duty_DaySum`(
 inOUguid varchar(36)
,inDutyDate date
,inTable varchar(50))
begin

# 出勤日結程式，可影響多table
# 計算每日實際上下班時間 tduty_a

# call p_Duty_DaySum('microjet',20140401,'');

/*
declare yestoday date ;
declare nextday date;
declare next2day date;
*/

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory mb大小

set @inOUguid=inOUguid;
set @inDutyDate=replace(inDutyDate,'-','');
set @inTable=inTable;
set @yestoday =(select @inDutyDate -interval 1 day);
set @nextday  =(select @inDutyDate +interval 1 day);
set @next2day =(select @inDutyDate +interval 2 day);


# 權限及人員範圍
 drop table if exists tmp_inputRWID ;
 
 if @inTable in ('') Then 

 create temporary table tmp_inputRWID as
 select rwid from tperson where ouguid=@inOUguid; 
 -- index 沒幫助 alter table tmp_inputRWID add index i01 (rwid);

 else 
 Set @sql= concat("create temporary table tmp_inputRWID as select rwid from ",@inTable);
 prepare s1 from @sql;
 execute s1;
 
 -- index 沒幫助 
 -- alter table tmp_inputRWID add index i01 (rwid);
 
 end if;

if 2=2 Then # 產生應出勤資料
drop table if exists tmp01 ;

create  temporary table tmp01  as
select 
 a.rwid as emp_rwid,
-- b.dutydate AS dutydate,
 ifnull(c.Holiday, b.Holiday) AS holiday,
 ifnull(c.WorkGuid, b.WorkGuid) AS workguid,
 (str_to_date(concat(b.dutydate, d.OnDutyHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OnNext_z04 day) AS Std_on,
 (str_to_date(concat(b.dutydate, d.OffDutyHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OffNext_z04 day) AS Std_off,
 (str_to_date(concat(b.dutydate, d.OverSTHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OverNext_z04 day) AS Over_on,
 ((str_to_date(concat(b.dutydate, d.OnDutyHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OnNext_z04 day) + interval -(d.RangeSt) minute) AS Range_on,
 ((str_to_date(concat(b.dutydate, d.OverSTHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OffNext_z04 day) + interval d.RangeEnd minute) AS Range_off,
 d.delaybuffer,
 a.CardNo AS cardno
    from
        tperson a
        left join tschdep b ON a.DepGuid = b.DepGuid 
        left join tschemp c ON a.EmpGuid = c.EmpGuid and b.dutydate = c.dutydate 
        left join tworkinfo d ON d.WorkGuid = ifnull(c.WorkGuid, b.WorkGuid)
    where
        b.dutydate >= a.ArriveDate # 到職後
            and (b.dutydate <= (case when (a.LeaveDate > 0) then a.LeaveDate else 99991231 end)) # 離職前
            and (b.dutydate <= (case when (a.stopDate  > 0) then a.stopDate  else 99991231 end)) # 留停前
            and a.ouguid=@inOUguid # 該OUguid ，避免inTable 直接傳入 tperson，多算其他ou的資料
			and b.dutydate=@inDutydate
			and a.rwid in (select rwid from tmp_inputRWID );

alter table tmp01 add index i01 (cardno);

drop table if exists tmp_inputRWID;

end if ;

if 3=3 Then # 抓取所需要的tcardtime

drop table if exists tmp02;

create temporary table tmp02  as    
select  cardno,dtcardtime from tcardtime a
where 
    ouguid=@inOUguid
and exists (select * from tmp01 b where a.cardno=b.cardno)
and a.dtcardtime 
 between @yestoday and @next2day;

alter table tmp02 add index i01 (cardno) ;

 end if;

if 4=4 Then # 計算上下班時間

drop table if exists tmp03;
create  temporary  table tmp03   as
select emp_rwid,min(b.dtcardtime) realOn,max(b.dtcardtime) realOff
from tmp01 a
left join tmp02 b on a.cardno=b.cardno
 and b.dtcardtime between a.range_on and a.range_off
group by emp_rwid;

alter table tmp03 add index i01 (emp_rwid);
drop table if exists tmp02;

#-------------------------
drop table if exists tmp04;
/* 產生
 上班前 時間起迄
 上班中 時間起迄
 下班後 時間起迄
*/
CREATE temporary TABLE `tmp04` (
  `emp_rwid` int(10) unsigned NOT NULL DEFAULT '0',
  `wType` varchar(5) NOT NULL DEFAULT '',
  `dTimeFr` datetime DEFAULT NULL,
  `dTimeTo` datetime DEFAULT NULL,
  UNIQUE KEY `u01` (`emp_rwid`,`wType`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
# WorkA 上班前部份
insert into tmp04
(emp_rwid,wType,dTimeFr,dTimeTo)
select a.emp_rwid
,'WorkA' wType
,IF(realOn>Std_on,Std_On,realOn)   # realOn 需放在後面(false處)，否則要在處理realOn=Null
,IF(realOff>Std_On,Std_On,realOff) # realOff 需放在後面(false處),否則要在處理realOff=Null
from tmp01 a
left join tmp03 b on a.emp_rwid=b.emp_rwid;
# WorkB 上班中部份
insert into tmp04
(emp_rwid,wType,dTimeFr,dTimeTo)
select a.emp_rwid
,'WorkB' wType
,IF(realOn <Std_On ,Std_On,realOn)   # realOn 需放在後面(false處)，否則要在處理realOn=Null
,IF(realOff>Std_Off,Std_Off,realOff) # realOff 需放在後面(false處),否則要在處理realOff=Null
from tmp01 a
left join tmp03 b on a.emp_rwid=b.emp_rwid;
# WorkC 下班後部份
insert into tmp04
(emp_rwid,wType,dTimeFr,dTimeTo)
select a.emp_rwid
,'WorkC' wType
,IF(realOn <Std_Off,Std_Off,realOn)     # realOn 需放在後面(false處)，否則要在處理realOn=Null
,IF(realOff < Std_Off,Std_Off,realOff)  # realOff 需放在後面(false處),否則要在處理realOff=Null
from tmp01 a
left join tmp03 b on a.emp_rwid=b.emp_rwid;

drop table if exists tmp04_sum;
create temporary table tmp04_sum as
select emp_rwid,wType,f_minute(timediff(dTimeFr,dTimeTo)) WorkMins
from tmp04
;
alter table tmp04_sum add index i01(emp_rwid);
 
end if; 

# --------------------------------
/* 
 tmp05 產生可能用到的休息時刻表
*/
drop table if exists tmp05_a;

create  temporary table tmp05_a (a_date date) ;

insert into tmp05_a values 
(@yestoday),(@inDutyDate),(@nextday),(@next2day);

drop table if exists tmp05;
create temporary table tmp05 as 
 select a.workguid,a.holiday,a.restno,a.cuttime,a.sthhmm,a.enhhmm
,str_to_date(concat(A_date,a.sthhmm),'%Y-%m-%d%H:%i:%s') + interval stNext_z04 day restST
,str_to_date(concat(A_date,a.enhhmm),'%Y-%m-%d%H:%i:%s') + interval enNext_z04 day restEnd
from tworkrest a
inner join tcatcode b on a.workguid=b.codeguid 
left join (select * from tmp05_a) c on 1=1 
where ouguid=@inOUguid;
 
alter table tmp05 add index (workguid,holiday);

drop table if exists tmp05_a;

#tmp06 每一時段經過的休息時間明細
drop table if exists tmp06;
create temporary table tmp06 as
select a.emp_rwid,wType,cuttime
,IF(dTimeFr>restST,dTimeFr,restST)   UseRestST
,IF(dTimeTo<restEnd,dTimeTo,restEnd) UseRestEnd 
,restST,restEnd
from tmp01 a
 left join tmp04 b on a.emp_rwid=b.emp_rwid
inner join tmp05 c on a.workguid=c.workguid and a.holiday=c.holiday 
      and b.dTimefr<restEnd and b.dTimeTo>restST
;

drop table if exists tmp05;
drop table if exists tmp06_sum;
create table tmp06_sum as
select emp_rwid,wType,Sum(f_minute(timediff(UseRestST,UseRestEnd))) RestMins
from tmp06 A
group by  emp_rwid,wType
; 
ALTER TABLE tmp06_sum ADD INDEX I01(emp_rwid,wType);

DROP TABLE IF EXISTS tmp_tdutya;
CREATE   TABLE `tmp_tdutya` (
emp_rwid int,
 -- `empguid` varchar(36) NOT NULL COMMENT '人員guid',
  `dutydate` date DEFAULT NULL COMMENT '出勤日',
  `holiday` tinyint(4) DEFAULT NULL,
  `workguid` varchar(36) DEFAULT NULL,
  `Std_on` datetime DEFAULT NULL,
  `Std_off` datetime DEFAULT NULL,
  `Over_on` datetime DEFAULT NULL,
  `Range_on` datetime DEFAULT NULL,
  `Range_off` datetime DEFAULT NULL,
  `cardno` varchar(50) DEFAULT NULL COMMENT '刷卡卡號',
  `realOn` datetime DEFAULT NULL,
  `realOff` datetime DEFAULT NULL,
  `WorkA` int(11) DEFAULT '0',
  `WorkB` int(11) DEFAULT '0',
  `WorkC` int(11) DEFAULT '0',
  `RestA` int(11) DEFAULT '0',
  `RestB` int(11) DEFAULT '0',
  `RestC` int(11) DEFAULT '0',
  `CloseStatus` varchar(1) NOT NULL DEFAULT '0' COMMENT '當初關帳，0 未關，1 已關',
  `delayBuffer` int(11) DEFAULT '0' COMMENT '彈性分鐘數',
  `delayBuffer_Use` int(11) DEFAULT '0' COMMENT '彈性使用分鐘數' 
,delayBuffer_repay int(11) default '0' 
,error_code varchar(1) default '9' 
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

insert into tmp_tdutya
(dutydate,emp_rwid ,holiday,workguid,Std_on,Std_off,Over_on
,Range_on,Range_off,delaybuffer
,cardno,realOn,realOff)
SELECT inDutyDate,
a.emp_rwid ,a.holiday,a.workguid,a.Std_on,a.Std_off,a.Over_on
,a.Range_on,a.Range_off,a.delaybuffer
,a.cardno,c.realOn,c.realOff 
FROM TMP01 A
LEFT JOIN TPERSON B ON A.emp_rwid=B.rwid
LEFT JOIN TMP03 C ON A.emp_rwid=C.emp_rwid;

drop table if exists tmp01;
drop table if exists tmp03;

# 補上 工作時間分鐘
update tmp_tdutya a,tmp04_sum b
set WorkA=IFNULL(b.WorkMins,0)
where a.emp_rwid=b.emp_rwid and b.wType='WorkA';
update tmp_tdutya a,tmp04_sum b
set WorkB=IFNULL(b.WorkMins,0)
where a.emp_rwid=b.emp_rwid and b.wType='WorkB';
update tmp_tdutya a,tmp04_sum b
set WorkC=IFNULL(b.WorkMins,0)
where a.emp_rwid=b.emp_rwid and b.wType='WorkC';

drop table if exists tmp04_sum;

# 補上休息時間
update tmp_tdutya a,tmp06_sum b 
set restA=IFNULL(b.RestMins,0)
where a.emp_rwid=b.emp_rwid and b.wType='WorkA';
update tmp_tdutya a,tmp06_sum b 
set restB=IFNULL(b.RestMins,0)
where a.emp_rwid=b.emp_rwid and b.wType='WorkB';
update tmp_tdutya a,tmp06_sum b 
set restC=IFNULL(b.RestMins,0)
where a.emp_rwid=b.emp_rwid and b.wType='WorkC';

drop table if exists tmp06_sum;

# 計算使用彈性分鐘數
update tmp_tdutya 
set 
delayBuffer_Use=
 (Case When realOn between Std_on And Std_on + interval delayBuffer minute 
 Then f_minute(timediff(std_on,realon))
 else 0 end )
;

# 計算可歸還彈性分鐘數
update tmp_tdutya 
set 
delayBuffer_Repay=
 (Case When WorkC > delayBuffer_Use Then delayBuffer_Use else WorkC end )
;

# 新增至 tduty_a
 if @inTable in ('') Then 
# 無指定人員範圍時，刪除當日該ou所有未關帳資料，避免有離職類不需日結，但卻一直存在
delete from tduty_a
where 
	empguid in (select empguid from tperson where ouguid=@inOUguid)
and dutydate=@inDutyDate 
and CloseStatus='0' /*未關帳*/;
else
delete from tduty_a
where 
	empguid in (select empguid from tperson where ouguid=@inOUguid)
and dutydate=@inDutyDate 
and CloseStatus='0' /*未關帳*/
and empguid in (select empguid from tperson where rwid in 
		(select rwid from tmp_inputRWID)) ;
end if;

update tmp_tdutya a
set error_code=
Case 
 When (a.realOn <= a.Std_On And a.realOff >= a.Std_Off) Then '0' /*正常*/
 When (a.WorkB  + delayBuffer_repay - RestB) >= @DayWorkMins Then '0' /*使用彈性，已還清*/
 Else '1'
 End
;


insert into tduty_a 
(empguid,dutydate,holiday,workguid,Std_on,Std_off,Over_on,Range_on,Range_off,cardno,realOn,realOff
,WorkA,WorkB,WorkC,RestA,RestB,RestC,CloseStatus,delayBuffer,delayBuffer_Use,delayBuffer_Repay
,error_code
)
select empguid,dutydate,holiday,workguid,Std_on,Std_off,Over_on,Range_on,Range_off,a.cardno,realOn,realOff
,WorkA,WorkB,WorkC,RestA,RestB,RestC,CloseStatus,delayBuffer,delayBuffer_Use,delayBuffer_Repay
,error_code
from tmp_tdutya a
left join tperson b on a.emp_rwid=b.rwid;

drop table if exists tmp_tdutya;


#----------------------------------
# 請假部份日結
delete from tduty_b 
Where 
    empguid in (select empguid from tperson where ouguid=@inOUguid)
and dutydate=@inDutyDate
and exists /*只能刪除未關帳資料*/
    (select * from tduty_a b where tduty_b.empguid=b.empguid
 and tduty_b.dutydate=b.dutydate and b.CloseStatus='0');

insert into tduty_b
(dutydate,empguid,offtypeguid,DutyOffMins)
SELECT 
a.dutydate,b.empguid,a.offtypeguid,sum(a.offmins) DutyOffMins
FROM toffdoc_duty a
inner join toffdoc b on a.offdocguid=b.offdocguid
inner join tperson c on b.empguid=c.empguid
Where 
    dutydate = @inDutyDate
and c.ouguid = @inOUguid
group by a.dutydate,b.empguid,a.offtypeguid;


end