drop procedure if exists p_OU_Prepare;

delimiter $$ 

create procedure p_OU_Prepare
(
 in_OUid varchar(36) # OUid
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare in_OUguid varchar(36);
declare in_ltPid varchar(36);

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
    set outMsg='sql error';
    set err_code=1;
  end if;
END;  
 
set in_ltPid='p_OU_Prepare';
set err_code=0; set outRwid=0; set outMsg='p_OU_Prepare 執行中';

if err_code=0 then # 判斷有無此OU
 set isCnt=0;
Select 
    rwid, OUguid
into isCnt , in_OUguid from
    tOUset
where
    OUid = in_OUid;
 if isCnt=0 then set err_code=1; set outMsg='無此OU'; end if;
end if;

if err_code=0 then # 90 新增資料
insert into tcatcode_sys  
(ltpid,OUguid,syscode,codeid,codedesc,codeseq,stop_used,note)
SELECT in_ltPid,in_OUguid,syscode,codeid,codedesc,codeseq,stop_used,note
FROM tcatcode_sys b
where ouguid='**common**'
on duplicate key update
 ltPid=in_ltPid,
 codedesc=b.codedesc,
 codeseq=b.codeseq,
 stop_used=b.stop_used,
 note=b.note;
end if; #90

if err_code=0 then # 91
insert into tcatcode 
(ltPid,CodeGuid,OUguid,syscode,codeid,codedesc,codeseq,stop_used,note)
SELECT in_ltPid,uuid(),in_OUguid,syscode,codeid,codedesc,codeseq,stop_used,note
FROM tcatcode  b
where ouguid='**common**'
on duplicate key update
 ltPid=in_ltPid,
 codeid=b.codeid,
 codedesc=b.codedesc,
 codeseq=b.codeseq,
 stop_used=b.stop_used,
 note=b.note;
end if; # 91
 
if err_code=0 then # 92
insert into tofftype
(ltpid,offType_Guid,OUguid
,Offtype_ID,Offtype_Desc,OffUnit,OffMin,Deduct_percent,CutFullDuty,IncludeHoliday,Can_Duplicate,QuotaCtrl,Stop_used,Quota_type,note)
select 
in_ltpid,uuid(),in_OUguid,Offtype_ID,Offtype_Desc,OffUnit,OffMin,Deduct_percent,CutFullDuty,IncludeHoliday,Can_Duplicate,QuotaCtrl,Stop_used,Quota_type,note
from tofftype b
where OUguid='**common**'
on duplicate key update 
ltpid=in_ltpid,  
Offtype_ID=b.Offtype_ID,
Offtype_Desc=b.Offtype_Desc,
OffUnit=b.OffUnit,
OffMin=b.OffMin,
Deduct_percent=b.Deduct_percent,
CutFullDuty=b.CutFullDuty,
IncludeHoliday=b.IncludeHoliday,
Can_Duplicate=b.Can_Duplicate,
QuotaCtrl=b.QuotaCtrl,
Stop_used=b.Stop_used,
Quota_type=b.Quota_type,
note=b.note;
end if; # 92

if err_code=0 then # 93
insert into tovertype 
 (ltpid,OverType_Guid,OUguid,Overtype_ID,Overtype_Desc,Paytype_Z01,OverA_Mins,OverB_Mins,OverA_Rate,OverB_Rate,OverC_Rate,OverH_Rate,OverA_Money,OverB_Money,OverC_Money,OverH_Money,Over_Unit,Valid_time,Valid_time_Z08,Stop_used,note) Select 
 in_ltpid,uuid(),in_OUguid,Overtype_ID,Overtype_Desc,Paytype_Z01,OverA_Mins,OverB_Mins,OverA_Rate,OverB_Rate,OverC_Rate,OverH_Rate,OverA_Money,OverB_Money,OverC_Money,OverH_Money,Over_Unit,Valid_time,Valid_time_Z08,Stop_used,note
  from tovertype b
 where OUguid='**common**'
  on duplicate key update  
  Overtype_ID=b.Overtype_ID
 ,Overtype_Desc=b.Overtype_Desc
 ,Paytype_Z01=b.Paytype_Z01
 ,OverA_Mins=b.OverA_Mins
 ,OverB_Mins=b.OverB_Mins
 ,OverA_Rate=b.OverA_Rate
 ,OverB_Rate=b.OverB_Rate
 ,OverC_Rate=b.OverC_Rate
 ,OverH_Rate=b.OverH_Rate
 ,OverA_Money=b.OverA_Money
 ,OverB_Money=b.OverB_Money
 ,OverC_Money=b.OverC_Money
 ,OverH_Money=b.OverH_Money
 ,Over_Unit=b.Over_Unit
 ,Valid_time=b.Valid_time
 ,Valid_time_Z08=b.Valid_time_Z08
 ,Stop_used=b.Stop_used
 ,note=b.note ;
 
end if; # 93

if err_code=0 then # 94 tworktype
insert into tworktype 
 (ltpid,Worktype_Guid,OUguid,worktype_ID,worktype_Desc,OnNext_Z04,OnDutyHHMM,OffNext_Z04,OffDutyHHMM,BeforeBuffer,DelayBuffer,OverBeforMin,OverAfterMin,OverHolidayMin,RangeSt,RangeEnd,Working_Mins,Stop_used,note) Select 
 in_ltpid,uuid(),in_OUguid,worktype_ID,worktype_Desc,OnNext_Z04,OnDutyHHMM,OffNext_Z04,OffDutyHHMM,BeforeBuffer,DelayBuffer,OverBeforMin,OverAfterMin,OverHolidayMin,RangeSt,RangeEnd,Working_Mins,Stop_used,note
  from tworktype b
 where OUguid="**common**"
  on duplicate key update  
  worktype_ID=b.worktype_ID
 ,worktype_Desc=b.worktype_Desc
 ,OnNext_Z04=b.OnNext_Z04
 ,OnDutyHHMM=b.OnDutyHHMM
 ,OffNext_Z04=b.OffNext_Z04
 ,OffDutyHHMM=b.OffDutyHHMM
 ,BeforeBuffer=b.BeforeBuffer
 ,DelayBuffer=b.DelayBuffer
 ,OverBeforMin=b.OverBeforMin
 ,OverAfterMin=b.OverAfterMin
 ,OverHolidayMin=b.OverHolidayMin
 ,RangeSt=b.RangeSt
 ,RangeEnd=b.RangeEnd
 ,Working_Mins=b.Working_Mins
 ,Stop_used=b.Stop_used
 ,note=b.note
 ;
end if; # 94 tworktype

if err_code=0 then # 95 tOUset_paytype
insert into tOUset_paytype 
 (ltpid,Paytype_Guid,OUguid,Paytype_ID,Paytype_Desc,Break_Month_Z22,Stop_used,type_Z16,note) Select 
 in_ltpid,uuid(),in_OUguid,Paytype_ID,Paytype_Desc,Break_Month_Z22,Stop_used,type_Z16,note
  from tOUset_paytype b
 where OUguid="**common**"
  on duplicate key update 
  Paytype_ID=b.Paytype_ID
 ,Paytype_Desc=b.Paytype_Desc
 ,Break_Month_Z22=b.Break_Month_Z22
 ,Stop_used=b.Stop_used
 ,type_Z16=b.type_Z16
 ,note=b.note
 ;
end if; # 95 tOUset_paytype

if err_code=0 then # 96 tOUset_insurance
 # 無法直接複制，請手動設定
 set isCnt=0;
end if; # 96 

if err_code=0 then # touset_subsidy
insert into touset_subsidy 
 (ltpid,OUguid,Subsidy_ID,Subsidy_Desc,subsidy_rate,Note) Select 
 in_ltpid,in_OUguid,Subsidy_ID,Subsidy_Desc,subsidy_rate,Note
  from touset_subsidy b
 where OUguid="**common**"
  on duplicate key update 
 Subsidy_ID=b.Subsidy_ID
 ,Subsidy_Desc=b.Subsidy_Desc
 ,subsidy_rate=b.subsidy_rate
 ,Note=b.Note
 ;
end if; # touset_subsidy

if err_code=0 then # tOUset_paytypebase
 # 無法直接複制，請手動設定
 set isCnt=0;
end if; # tOUset_paytypebase

if err_code=0 then # tOUset_lvlist
delete from tOUset_lvlist where OUguid=in_OUguid;
insert into tOUset_lvlist 
 (ltpid,OUguid,type_z18,m_Amt) 
Select 
 in_ltpid,in_OUguid,type_z18,m_Amt
  from tOUset_lvlist b
 where OUguid="**common**"
  on duplicate key update 
 type_z18=b.type_z18
 ,m_Amt=b.m_Amt
 ;
end if; # tOUset_lvlist

if err_code=0 then # touset_offspecial_lvlist
insert into touset_offspecial_lvlist 
 (ltpid,OUguid,JobAges_m,OffDays,Note)
  Select 
 in_ltpid,in_OUguid,JobAges_m,OffDays,Note
  from touset_offspecial_lvlist b
 where OUguid="**common**"
  on duplicate key update 
 JobAges_m=b.JobAges_m
 ,OffDays=b.OffDays
 ,Note=b.Note; 
end if; # touset_offspecial_lvlist

if err_code=0 then # tOUset_calendar
insert into tOUset_calendar 
 (ltpid,OUGuid,CalDate,holiday)
  Select 
 in_ltpid,in_OUGuid,CalDate,holiday
  from tOUset_calendar b
 where OUguid="**common**"
  on duplicate key update 
 CalDate=b.CalDate
 ,holiday=b.holiday
 ;
end if; # tOUset_calendar


end; # begin