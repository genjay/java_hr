drop procedure if exists p_toffdoc_duty_save;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_toffdoc_duty_save`
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_Rwid int)
begin
declare err_code int default 0;
declare in_leftMins int;
declare isCnt int;
declare sTmpA text;
declare in_EmpID  varchar(36); # 因前端舊程式，有可能丟empid、empguid
declare in_Type   varchar(36);# 請假假別,offtype,offtypeguid 都有
declare in_DateStart datetime;
declare in_DateEnd   datetime;
declare outMsg text;
declare out_OffMins int;
declare droptable int default 1;
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
END;
set out_OffMins=0; set outMsg='p_toffdoc_duty_save';

if err_code=0 then # 40 抓出 P_tOffDoc_01 所需變數
   
  Select Empguid,offtypeguid,OffDoc_Start,OffDoc_End
   into in_EmpID,in_Type,in_DateStart,in_DateEnd
  from toffdoc 
  where rwid=in_Rwid ;
end if; # 40 
  

-- 以下複制 P_tOffDoc_01 主程式-----
if err_code=0 then # 50 產生請假經歷出勤日
  drop table if exists tmp01_P_tOffDoc_01;
  create temporary  table tmp01_P_tOffDoc_01 as
  Select ouguid,empid,dutydate,holiday,workid,std_on,std_off,workminutes
  ,in_DateStart Off_St
  ,in_DateEnd   Off_End
  ,in_Type      Off_type
  from vdutystd_emp
  where ouguid=in_OUguid 
  and (empid=in_EmpID or empguid=in_EmpID) # 因前端舊程式，丟的是empguid
  and std_ON  < in_DateEnd
  and std_Off > in_DateStart; 
end if;

if err_code=0 then # 60 產生每日請假起迄，及請假整天時，以workminute當請假時間(分)
  drop table if exists tmp02_P_tOffDoc_01;
  create temporary  table tmp02_P_tOffDoc_01 as
  select a.OUguid,a.Empid,a.dutydate,a.holiday
  ,a.workid,a.std_on,a.std_off 
  ,if(a.std_on<=a.off_st,a.Off_st,a.std_on) dutyoff_st
  ,if(a.std_off>=a.Off_end,a.Off_end,a.std_off) dutyoff_end
  ,Case 
   When a.off_st<=a.std_on && a.Off_end>=a.std_off then a.workminutes
   else 0 end dutyoff_Mins 
  ,a.off_type 
  from tmp01_P_tOffDoc_01 a ;
  alter table tmp02_P_tOffDoc_01 add index i01 (ouguid,empid,dutydate);
  if droptable=1 then drop table if exists tmp01_P_tOffDoc_01; end if;
end if; # 60 

if err_code=0 then # 70 產生休息時刻表
  # 只產生 dutyoff_Mins=0 的部份
  drop table if exists tmpRest_P_tOffDoc_01;
  create temporary  table tmpRest_P_tOffDoc_01 as
  select 
  a.ouguid,
  a.empid,
  a.dutydate,
  a.workid,
  a.holiday,
  f_OffsetDtime(stNext_z04,a.dutydate,b.sthhmm) rest_ST , 
  f_OffsetDtime(enNext_z04,a.dutydate,b.enhhmm) rest_End,
  cuttime 
  from
    tmp02_P_tOffDoc_01 a
    left join tworkrest b on b.workguid=
    (select codeguid from tcatcode where ouguid=a.ouguid and syscode='A01' and a.workid=codeid) 
    and a.holiday=b.holiday
  where a.dutyoff_Mins=0; 
  alter table tmpRest_P_tOffDoc_01 add index i01 (ouguid,empid,dutydate);
end if; # 70
if err_code=0 then # 80 產生使用休息時間起迄
  drop table if exists tmp03_P_tOffDoc_01;
  create temporary  table tmp03_P_tOffDoc_01 as
  select a.ouguid,a.empid,a.dutydate ,a.cuttime
  ,if( dutyoff_st>rest_st,dutyoff_st,rest_st) UseRest_St
  ,if(dutyoff_end<rest_end,dutyoff_end,rest_end) UseRest_End
  #,a.rest_st,a.rest_End,b.dutyoff_st,b.dutyoff_end
  from tmpRest_P_tOffDoc_01 a
  left join tmp02_P_tOffDoc_01 b on a.ouguid=b.ouguid and a.empid=b.empid and a.dutydate=b.dutydate
  where a.rest_st<b.dutyoff_end and a.rest_end>b.dutyoff_st;
  alter table tmp03_P_tOffDoc_01 add index i01 (ouguid,empid,dutydate);
  if droptable=1 then drop table if exists tmpRest_P_tOffDoc_01; end if;
end if; 

if err_code=0 then # 85 產生需扣除休息時間
  drop table if exists tmp04_P_tOffDoc_01;
  create temporary  table tmp04_P_tOffDoc_01 as
  select a.ouguid,a.empid,a.dutydate
  ,sum(f_minute(timediff(UseRest_St,UseRest_End))) useRestMins
  from tmp03_P_tOffDoc_01 a
  where a.cuttime=1
  group by a.ouguid,a.empid,a.dutydate;
  alter table tmp04_P_tOffDoc_01 add index i01 (ouguid,empid,dutydate);
  if droptable=1 then drop table if exists tmp03_P_tOffDoc_01; end if;
end if; # 85

if err_code=0 then # 87 產生每日請假時間(分)，已扣除休息時間
  drop table if exists tmp05_P_tOffDoc_01;
  create temporary  table tmp05_P_tOffDoc_01 as
  select a.ouguid,a.empid,a.dutydate,a.holiday,a.Off_type
  ,if(dutyoff_Mins=0
  ,f_minute(timediff(a.dutyoff_st,a.dutyoff_end))-ifnull(b.useRestMins,0)
  ,dutyoff_Mins) dutyoff_mins
  from tmp02_P_tOffDoc_01 a
  left join tmp04_P_tOffDoc_01 b on a.ouguid=b.ouguid and a.empid=b.empid and a.dutydate=b.dutydate;
  alter table tmp05_P_tOffDoc_01 add index i01 (ouguid,empid,dutydate);
  if droptable=1 then drop table if exists tmp04_P_tOffDoc_01; end if;
  if droptable=1 then drop table if exists tmp02_P_tOffDoc_01; end if;

end if; # 87

if err_code=0 then # 90
  drop table if exists tmp06_P_tOffDoc_01;
  create temporary  table tmp06_P_tOffDoc_01 as
  select a.ouguid,a.empid,a.dutydate,a.off_type
  ,Case
   When a.dutyoff_mins = 0 then 0
   When a.dutyoff_mins < c.Offmin Then c.Offmin
   Else Ceil(a.dutyoff_mins/c.offUnit)*c.OffUnit
   End  
   *if(a.holiday=0,'1',(if(c.includeholiday=b'1','1','0')))
   /60 Off_hr  
  from tmp05_P_tOffDoc_01 a
  left join tcatcode b on a.ouguid=b.ouguid and b.syscode='A00' and (b.codeguid=a.off_type or b.codeid=a.off_type)
  left join tofftype c on b.codeguid=c.offtypeguid;
end if;  

if err_code=0 then # 95 回傳請假小時數
select sum(off_hr) into out_OffMins from tmp06_P_tOffDoc_01;

end if; # 95

if err_code=0 then # 96 回傳特補休，可休時間
  set in_leftMins=0;
  SELECT ifnull(Sum(Off_Mins_left),0) into in_leftMins
  FROM csrhr.voffquota_status 
  where Off_Mins_left > 0
  and (Empid=in_EmpID or EmpGuid=in_EmpID)
  and (offtype=in_Type or offtypeguid=in_Type)
  and Quota_Valid_ST  < in_DateStart
  and Quota_Valid_End > in_DateStart;
 
  select in_leftMins +ifnull(sum(OffDoc_Mins),0) # 修改時，要加回自身的請假時數，否則會一直出現不足
  into in_leftMins from tOffquota_used
  where OffDocGuid=(select offdocguid from toffdoc where rwid=in_Rwid);

set isCnt=0;set sTmpA='';
 Select a.rwid,concat(b.codeid,' ',b.codedesc) into isCnt,sTmpA
  from tOfftype a
 left join tcatcode b on a.offtypeguid=b.codeguid
 where QuotaCtrl=1 
 and ((b.OUguid=in_OUguid and b.syscode='A00' and codeid=in_Type) 
      or codeguid=in_Type) ; 

if isCnt>0 then 
  set outMsg=concat(sTmpA,' 可用：',round(in_leftMins/60,2),'hr');
else set outMsg='';
end if;

end if; # 96

-- 以上複制 P_tOffDoc_01 主程式-----

if err_code=0 then # 請假單日結部份
  drop table if exists tmp07_p_toffdoc_duty_save;
  create temporary table tmp07_p_toffdoc_duty_save as 
  select offdocguid,offtypeguid ,b.dutydate,off_hr*60 OffMins
  from toffdoc a
  left join tmp06_P_tOffDoc_01 b on 1=1
  where rwid=in_Rwid;

 start transaction;
  delete from tOffDoc_duty
  where offdocguid=(select offdocguid from tOffDoc x Where x.rwid=in_RWID);

  insert into tOffDoc_duty
  (ltuser,ltpid,OffDocGuid,dutydate,OffTypeGuid,OffMins)
  select in_ltUser,in_ltPid,a.OffDocGuid,a.dutydate,a.OffTypeGuid,a.OffMins 
  from tmp07_p_toffdoc_duty_save a;
 commit;

  if droptable=1 then 
   drop table if exists tmp01_P_tOffDoc_01;
   drop table if exists tmp02_P_tOffDoc_01;
   drop table if exists tmp03_P_tOffDoc_01;
   drop table if exists tmp04_P_tOffDoc_01;
   drop table if exists tmp05_P_tOffDoc_01;
   drop table if exists tmp06_P_tOffDoc_01;
   drop table if exists tmp07_p_toffdoc_duty_save;

  end if;

end if;



end