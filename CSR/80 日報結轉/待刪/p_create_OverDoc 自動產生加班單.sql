# 自動產生加班單
# 利用tDuty_a 來計算

drop procedure if exists p_create_OverDoc;

delimiter $$

create procedure p_create_OverDoc(
inOUguid varchar(36),inDutydate date
)

begin

# call p_create_OverDoc('microjet','20140401');
  
  set sql_safe_updates=0;
  set @inOUguid=inOUguid;
  set @inDutydate=inDutydate;


drop table if exists tmp01;
create temporary table tmp01 as
select 
 a.empguid,a.dutydate,b.overTypeguid
,a.realon OverStart,a.realOff OverEnd
,floor((a.workA-a.restA)/c.overunit)*c.overunit   OverMins_Before
,floor((a.workC-a.restC)/c.overunit)*c.overunit   OverMins_After
,If(holiday=1,floor((a.workB-a.restB)/c.overunit),0) OverMins_holiday
,'系統自動產生' Note
,valid_type
,valid_time
,offtypeguid
,overtoOff_rate
from tduty_a a
left join tperson b on a.empguid=b.empguid
left join tovertype c on b.overtypeguid=c.overtypeguid
left join tworkinfo d on d.workguid=a.workguid 
where 
    b.ouguid=@inOUguid
and a.dutydate=@inDutydate
and (   (a.workA-a.restA) >= d.OverBeforMin /*提前加班超過可申報*/
     or (a.workC-a.restC) >= d.OverAfterMin /*延後加班超過可申報*/
     or a.holiday=1 and a.workB >= d.OverHolidayMin /*假日workB超過可申報*/
     );

delete from toverdoc
where 
    empguid in (select empguid from tperson where ouguid=@inOUguid)
and dutydate=@inDutydate
and ltpid='p_create_OverDoc';

insert into toverdoc
(overdocguid,empguid,dutydate,overTypeguid,OverStart,OverEnd,OverMins_Before,OverMins_After,OverMins_holiday
,Note,valid_type,valid_time,offtypeguid,overtoOff_rate
,ltpid)
select 
uuid(),a.empguid,a.dutydate,a.overTypeguid,OverStart,OverEnd,OverMins_Before,OverMins_After,OverMins_holiday
,Note,valid_type,valid_time,offtypeguid,overtoOff_rate
,'p_create_OverDoc'
from tmp01 a 
where 
 Not exists (select * from toverdoc b where a.empguid=b.empguid and a.dutydate=b.dutydate)
 ;

############################
## 產生 tDuty_c 日報加班部份
###########################
drop table if exists tmp02;
create temporary table tmp02
select rwid from toverdoc
where 
    empguid in (select empguid from tperson where ouguid=@inOUguid)
and dutydate=@inDutydate
and ltpid='p_create_OverDoc';

call p_tOverDoc_09('tmp02'); # 產生tDuty_c

############################



end;