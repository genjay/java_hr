drop procedure p_tOverDoc_09;

DELIMITER $$

CREATE DEFINER=`admin`@`%` PROCEDURE `p_tOverDoc_09`(
inRwid varchar(36)
)
Begin


# call p_tOverDoc_09(16001);
# call p_tOverDoc_09('tt');
# tt 儲放 tOverdoc 的 rwid
# 日結加班單部份
# 加班單存入toverdoc 後，才能執行

/* 
*/

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory mb大小

drop table if exists tmp_rwid;

if f_IsNum(inRWid)=1  /*inRwid為全數字時，單筆處理*/
   Then set @sql=concat('create temporary table tmp_rwid as select rwid from toverdoc where rwid=',inRwid);
  prepare s1 from @sql;
  execute s1;

else
  /*多筆處理*/
  Set @sql=concat('create temporary table  tmp_rwid as select rwid from ',inRwid);
  prepare s1 from @sql;
  execute s1;

end if;

select dutydate into @dutydate from toverdoc b where b.rwid in (select rwid from tmp_rwid) 
limit 1;

drop table if exists tmp01;
create temporary table  tmp01 as
SELECT a.empguid,a.dutydate,a.overTypeGuid
,IF(OFFTypeGuid is Null,sum(OverMins_Before+OverMins_After),0 ) OverMins_WorkDay
,If(OFFTypeGuid is Null,sum(OverMins_Holiday),0) OverMins_Holiday
,If(OFFTypeGuid is Null,0,sum(OverMins_Before+OverMins_After+OverMins_Holiday)) OverChange
FROM tOverDoc A
inner join tperson B on a.empguid=b.empguid 
Where 
    a.dutydate = @dutydate
and a.empguid  in (select empguid  from toverdoc b where b.rwid in (select rwid from tmp_rwid)) 
Group by a.empguid,a.dutydate ,a.overtypeguid;

drop table if exists tmp02;
create temporary table tmp02 as
select a.empguid,a.dutydate,a.overtypeguid
,Case 
 When OverMins_WorkDay >= OverAMins Then OverAMins- 0
 When OverMins_WorkDay between 0 And OverAMins Then  OverMins_WorkDay
 else 0 end OverA  
,Case 
 When OverMins_WorkDay >= OverBMins Then OverBMins-OverAMins
 When OverMins_WorkDay between OverAMins And OverBMins Then  OverMins_WorkDay-OverAMins
 else 0 end OverB
,Case 
 When OverMins_WorkDay >= OverCMins Then OverCMins-OverBMins
 When OverMins_WorkDay between OverBMins And OverCMins Then  OverMins_WorkDay-OverBMins
 else 0 end OverC
,a.OverMins_Holiday
,a.OverChange
from tmp01 a
left join tOvertype b on a.overTypeguid=b.Overtypeguid; 
 

delete from tDuty_C
Where 
    dutydate = @dutydate
and empguid in (select empguid from toverdoc b where b.rwid in (select rwid from tmp_rwid))
; 

drop table if exists tmp03;
create temporary table  tmp03 as
select empguid,dutydate,overtypeguid
,sum(OverA) OverA
,sum(OverB) OverB
,sum(OverC) OverC
,sum(OverMins_Holiday) OverH
,sum(OverChange) OverChange
from tmp02
Group by empguid,dutydate,overtypeguid;

drop table if exists tmp04;
create temporary table  tmp04 as
select a.empguid,a.dutydate,a.overtypeguid
,OverA,OverB,OverC,OverH,OverChange
,OverA*OverAPay PayAMins
,OverB*OverBPay PayBMins
,OverC*OverCPay PayCMins
,OverH*OverHPay PayHMins
from tmp03 a
left join tovertype b on a.overtypeguid=b.overtypeguid;
 
insert into tDuty_C
(empguid,dutydate,overtypeguid,overA,overB,overC,overH,OverChange
 ,payAmins,payBmins,PayCMins,payHmins)
select empguid,dutydate,overtypeguid,overA,overB,overC,overH,OverChange
 ,payAmins,payBmins,PayCMins,payHmins
from tmp04;
 

end