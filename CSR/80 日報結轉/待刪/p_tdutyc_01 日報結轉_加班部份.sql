drop procedure if exists p_tdutyC_01 ;

delimiter $$

create procedure p_tdutyC_01 
(
inOUguid varchar(36),inDutyDate date,inTable varchar(50)
)

Begin

# call p_tdutyC_01('microjet',20140401,'tt');
# 日結加班單部份

declare yestoday date ;
declare nextday date;
declare next2day date;
set yestoday =(select inDutyDate -interval 1 day);
set nextday  =(select inDutyDate +interval 1 day);
set next2day =(select inDutyDate +interval 2 day);

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory mb大小


# 權限及人員範圍
 drop table if exists tmp_inputRWID ;
 
 if inTable in ('','all') Then 

 create temporary table tmp_inputRWID as
 select rwid from tperson where ouguid=inOUguid; 
 -- index 沒幫助 alter table tmp_inputRWID add index i01 (rwid);

 else 
 Set @sql= concat("create temporary table tmp_inputRWID as select rwid from ",inTable);
 prepare s1 from @sql;
 execute s1;
 
 -- index 沒幫助 
 alter table tmp_inputRWID add index i01 (rwid);
 
 end if;

drop table if exists tmp01;
create table tmp01 as
SELECT a.empguid,a.dutydate,a.overTypeGuid
,IF(OFFTypeGuid is Null,sum(OverMins_Before+OverMins_After),0 ) OverMins_WorkDay
,If(OFFTypeGuid is Null,sum(OverMins_Holiday),0) OverMins_Holiday
,If(OFFTypeGuid is Null,0,sum(OverMins_Before+OverMins_After+OverMins_Holiday)) OverChange
FROM tOverDoc A
inner join tperson B on a.empguid=b.empguid 
Where 
    b.OUguid=inOUguid
and a.dutydate=inDutyDate
and b.rwid in (select rwid from tmp_inputRWID)
Group by a.empguid,a.dutydate ,a.overtypeguid;

if inTable in ('','all') Then 
delete from tdutyc 
Where 
/*排除被關帳資料*/ 
Not exists (select * from tdutya b where tdutyc.empguid=b.empguid and tdutyc.dutydate=b.dutydate and b.dutystatus>0)
and 
/*只能刪該OU資料*/ 
exists (select * from tperson b where tdutyc.empguid=b.empguid and b.ouguid=inOUguid)
and tdutyc.dutydate=inDutydate;

Else
 
delete from tdutyc 
Where 
/*排除被關帳資料*/ 
Not exists (select * from tdutya b where tdutyc.empguid=b.empguid and tdutyc.dutydate=b.dutydate and b.dutystatus>0)
and 
/*只能刪該OU資料*/ 
exists (select * from tperson b where tdutyc.empguid=b.empguid and b.ouguid=inOUguid)
and tdutyc.dutydate=inDutydate
and empguid in (select empguid from tperson where rwid in (select rwid from tmp_inputRWID));

end if ;

drop table if exists tmp02;
create temporary table tmp02 as
select a.empguid,a.dutydate,a.overtypeguid
,Case 
 When OverMins_WorkDay > OverAMins Then OverAMins- 0
 When OverMins_WorkDay between 0 And OverAMins Then  OverMins_WorkDay
 else 0 end OverA  
,Case 
 When OverMins_WorkDay > OverBMins Then OverBMins-OverAMins
 When OverMins_WorkDay between OverAMins And OverBMins Then  OverMins_WorkDay-OverAMins
 else 0 end OverB
,Case 
 When OverMins_WorkDay > OverCMins Then OverCMins-OverBMins
 When OverMins_WorkDay between OverBMins And OverCMins Then  OverMins_WorkDay-OverBMins
 else 0 end OverC
,a.OverMins_Holiday
,a.OverChange
from tmp01 a
left join tOvertype b on a.overTypeguid=b.Overtypeguid; 

alter table tmp01 add index i01 (empguid,dutydate);

insert into tdutyc
(empguid,dutydate,overA,overB,overC,overH,OverChange)
select empguid,dutydate,sum(OverA),sum(OverB),sum(OverC),sum(OverMins_Holiday),sum(OverChange)
from tmp02
Group by empguid,dutydate;



end;