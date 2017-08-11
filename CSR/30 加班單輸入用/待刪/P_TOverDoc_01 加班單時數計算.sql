drop procedure if exists P_tOverDoc_01;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `P_tOverDoc_01`
( 
 inEmpGuid varchar(36)  # 人員
,inOvertypeGuid varchar(36) # 加班類別
,inOverStart datetime  # 加班起
,inOverEnd datetime  # 加班迄
,inDutydate date # 出勤日
,inRwid int # 當前的加班單rwid，若新增則輸入 0
,out outOverBefor_hr dec(5,3) # 上班前加班小時
,out outOverH_hr dec(5,3) # 假日正常工作時間 小時
,out outOverAfter_hr dec(5,3) # 延後加班小時
,out outHoliday int # 是否為假日
,out outError int # 錯誤代碼 0 為無錯誤
,out outDupRwid int # 重疊的加班單rwid
)
begin

/*
執行範例
call p_toverDoc_01(
 (select empguid from tperson where ouguid='microjet' and empid='a00514')
,'microjet-nopay'
,'2014-05-06 22:50'
,'2014-05-06-23:50'
,'2014-05-06'
,21505
,@a,@b,@c,@d,@e,@f);

*/

Set @inEmpGuid= inEmpGuid ;
Set @inOvertypeGuid=inOvertypeGuid; 
Set @inOverStart=inOverStart;  
Set @inOverEnd= inOverEnd ;
Set @inDutydate=inDutydate; 
Set @inRwid= inRwid;

#tmp01 該empguid，請假範圍內的出勤資料

drop table if exists tmp01 ;
create temporary table tmp01  as
select 
 a.EmpGuid AS empguid,
 a.OUguid AS ouGuid,
 b.dutydate AS dutydate,
 ifnull(c.Holiday, b.Holiday) AS holiday,
 ifnull(c.WorkGuid, b.WorkGuid) AS workguid,
 e.OverUnit,d.OverBeforMin,d.OverAfterMin,d.OverHolidayMin,
 (str_to_date(concat(b.dutydate, d.OnDutyHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OnNext_Z04 day) AS Std_on,
 (str_to_date(concat(b.dutydate, d.OffDutyHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OffNext_Z04 day) AS Std_off,
 (str_to_date(concat(b.dutydate, d.OverSTHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OverNext_Z04 day) AS Over_on,
 ((str_to_date(concat(b.dutydate, d.OnDutyHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OnNext_Z04 day) + interval -(d.RangeSt) minute) AS Range_on,
 ((str_to_date(concat(b.dutydate, d.OverSTHHMM),'%Y-%m-%d%H:%i:%s') + interval d.OffNext_Z04 day) + interval d.RangeEnd minute) AS Range_off
    from
        tperson a
        left join tschdep b ON a.DepGuid = b.DepGuid 
        left join tschemp c ON a.EmpGuid = c.EmpGuid and b.dutydate = c.dutydate 
        left join tworkinfo d ON d.WorkGuid = ifnull(c.WorkGuid, b.WorkGuid)
		left join tovertype e ON e.overtypeGuid=@inOvertypeGuid
    where
        ((b.dutydate >= a.ArriveDate)
            and (b.dutydate <= (case when (a.LeaveDate > 0) then a.LeaveDate else 99991231 end))
            and (b.dutydate <= (case when (a.stopDate > 0)  then a.stopDate  else 99991231  end))) 
            and a.empGuid =@inEmpGuid
            and b.dutydate=@inDutyDate;

select holiday  into outHoliday from tmp01;
#產生上班前加班起迄、下班後加班起迄、平時工作時間加班起迄


drop table if exists tmp02;
create  temporary table tmp02 as
select a.empguid,a.dutydate,a.holiday,a.workguid,'Befor' ABC_type
,inOverStart Overtime_ST
,Case When inOverEnd > Std_On Then Std_on      
 Else  inOverEnd end Overtime_End
,OverUnit,OverBeforMin OverNeedMins
from tmp01 a 
Where inOverStart < Std_On /*加班起要在上班時間前，才有可能提加加班*/
and inOverEnd > Range_On;

insert into tmp02 
(empguid,dutydate,holiday,workguid,ABC_type,Overtime_ST,Overtime_End
 ,OverUnit,OverNeedMins)
select a.empguid,a.dutydate,a.holiday,a.workguid,'After' ABC_type
,Case When inOverStart <= Std_Off Then Std_off    
 Else  inOverStart end AfterOver_On
,inOverEnd AfterOver_Off
,OverUnit,OverAfterMin 
from tmp01 a 
Where inOverEnd > Std_Off /*加班迄超過下班時間，才會有延後加班*/
and inOverStart < Range_Off;

insert into tmp02
(empguid,dutydate,holiday,workguid,ABC_type,Overtime_ST,Overtime_End
 ,OverUnit,OverNeedMins)
select a.empguid,a.dutydate,a.holiday,a.workguid,'OverH' ABC_type
,Case When inOverStart < Std_On Then Std_On      
 Else inOverStart End OverH_On
,Case When inOverEnd > Std_Off Then Std_Off     
 Else inOverEnd End OverH_Off
,OverUnit,OverHolidayMin
from tmp01 a 
Where holiday>0 And inOverStart < Std_Off And inOverEnd > Std_On
;

# 還不能刪tmp01   -- drop table if exists tmp01;


#-------產生休息時刻表
#tmp05_a 需產生休息時刻表的那幾天
#tmp05 休息時刻表
drop table if exists tmp05_a;

create  temporary table tmp05_a (a_date date) as
select dutydate a_date
from tmp01;

insert into tmp05_a (a_date) select min(dutydate)-interval 1 day from tmp01;
insert into tmp05_a (a_date) select max(dutydate)+interval 1 day from tmp01; 

drop table if exists tmp05;
create temporary table tmp05 as 
 select a.workguid,a.holiday,a.cuttime,a.sthhmm,a.enhhmm
-- ,concat(inDutyDate,a.enhhmm) aa
,str_to_date(concat(A_date,a.sthhmm),'%Y-%m-%d%H:%i:%s') + interval stNext_Z04 day restST
,str_to_date(concat(A_date,a.enhhmm),'%Y-%m-%d%H:%i:%s') + interval enNext_Z04 day restEnd
from tworkrest a
inner join tcatcode b on a.workguid=b.codeguid
left join (select * from tmp05_a) c on 1=1 
where exists (select * from tmp01 b where b.workguid=a.workguid );
 
drop table if exists tmp05_a;
-- drop table if exists tmp01;
alter table tmp05 add index (workguid,holiday);

# 計算使用的休息時間
drop table if exists tmp03;
create  temporary table tmp03 as
select a.empguid,a.dutydate,a.holiday,a.workguid,a.abc_type
,b.cuttime
,overtime_st,overtime_end,restst,restend
,Case When a.Overtime_ST < b.restST    Then b.restST Else a.Overtime_ST End   Use_restSt
,Case When a.Overtime_End > b.restEnd  Then b.restEnd Else a.Overtime_End End Use_restEnd
from tmp02 a
inner join tmp05 b on a.workguid=b.workguid and a.holiday=b.holiday 
 and a.Overtime_ST < b.restEnd and a.Overtime_End > b.restST
Where Not (b.restST is null and b.restEnd is null);

drop table if exists tmp05;
-- 還不能刪 tmp02 , 後面還要用 drop table if exists tmp02;

# tmp04 加總應扣除的休息時間

drop table if exists tmp04;
create  temporary table tmp04 as
select a.empguid,a.dutydate,a.holiday,a.abc_type
,Sum(Case When cuttime=1 Then f_minute(timediff(Use_restST,Use_restEnd)) Else 0 End) UseCutRestMins
from tmp03 a
where cuttime=1
Group by a.empguid,a.dutydate,a.holiday,a.abc_type
;

drop table if exists tmp03;

#tmp06 計算出三段加班時間
drop table if exists tmp06;
create  temporary table tmp06 as
select 
a.empguid,a.dutydate,a.holiday,a.workguid,a.abc_type,Overtime_ST,Overtime_End
,a.OverUnit,a.OverNeedMins
,f_minute(timediff(Overtime_ST,Overtime_End))-ifnull(b.UseCutRestMins,0) OverMins
from tmp02 a
left join tmp04 b on a.empguid=b.empguid and a.dutydate=b.dutydate and a.abc_type=b.abc_type;

drop table if exists tmp02;
drop table if exists tmp04;


# tmp07可申報小時
drop table if exists tmp07;
create table tmp07 as
select empguid,abc_type
,Case When OverMins>OverNeedMins
 Then if(holiday=0 and abc_type='OverH',0,floor(OverMins/OverUnit)*OverUnit/60)
 Else floor(OverMins/OverUnit)*OverUnit/60 end OverHours
# OverMins/OverUnit 等於多少申報單位
# floor(OverMins/OverUnit) 無條件捨去
# *OverUnit 換成可申報分鐘數
# /60 換成單位小時
from tmp06;

drop table if exists tmp06;

#回傳out值
select 
  Sum(Case When abc_type='Befor' Then OverHours Else 0 End)
, Sum(Case When abc_type='OverH' Then OverHours Else 0 End)
, Sum(Case When abc_type='After' Then OverHours Else 0 End)
into outOverBefor_hr,outOverH_hr,outOverAfter_hr
from tmp07
Group by empguid;

drop table if exists tmp07;


#處理 error 代碼
select 
Case 
 When @inOverStart > @inOverEnd Then 1 /*起迄不合理*/
 When @inOverStart Not between Range_On And Range_Off Then 2 /*加班起不在合理範圍內*/
 When @inOverEnd   Not between Range_On And Range_Off Then 3 /*加班迄不在合理範圍內*/
 
Else 0 /*正常可存檔*/
End  into outError
from tmp01;

# outError=4 代表加班單時間重疊
 
select ifnull(a.rwid,0),if(a.rwid>0,4,outError) ,count(*)
into outDupRwid,outError,@cnt
from toverdoc a
Where a.empguid=inEmpGuid 
 and a.overStart < @inOverEnd  
 and a.overEnd   > @inOverStart  
 and a.rwid != @inRwid
limit 1 ; 
 

end