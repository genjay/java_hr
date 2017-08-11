drop procedure if exists P_tOverDoc_01;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `P_tOverDoc_01`
( 
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_EmpID  varchar(36) # 工號
,in_Type   varchar(36)  # 加班別
,in_Dutydate   varchar(36)      # 出勤日
,in_DateStart  varchar(36)  #加班起
,in_DateEnd    varchar(36)  #加班迄
,out iOverBefore  int      #提早加班
,out iOverHoliday int      #假日加班
,out iOverAfter   int      #延後加班 
,out isHoliday int # 假日
,out outMsg text  # 訊息回傳
)

begin
/*
執行範例 
call `P_tOverDoc_01`
( 
 'microjet'
,'ltUser'
,'ltPid'
,'A00514'
,'A' # 加班類別
,20140707
,'2014-07-07 08:00'  #加班起
,'2014-07-07 19:59'  #加班迄
,@a     #提早加班
,@b     #假日加班
,@c     #延後加班 
,@d     # 假日
,@e
);

select @a,@b,@c,@d,@e;
*/

DECLARE err_code int default '0'; 


set @droptable  = 0; # 1 drop temp table /0 test mode 
set @in_OUguid =in_OUguid;
set @in_ltUser =in_ltUser ;
set @in_ltpid  =in_ltpid;
set @in_EmpID  =in_EmpID  ;
set @in_Type   =in_Type  ;
set @in_Dutydate    =  in_Dutydate;
set @in_DateStart   =  in_DateStart  ;
set @in_DateEnd     =  in_DateEnd  ;   
set iOverBefore  =0;      #提早加班
set iOverHoliday =0;      #假日加班
set iOverAfter   =0;      #延後加班 
set isHoliday    =0;      # 假日

set @in_EmpGuid='';
set @in_TypeGuid='';
set @in_Rwid=0; # 此處用不到，只為抓guid sql，一致性 

set @xx1 = f_DtimeCheck(f_removeX(in_DateStart));
if @xx1 !='OK' Then set err_code=1; set @outMsg=concat("時間(起) ",@xx1); end if;
 
set @xx2 = f_DtimeCheck(f_removeX(in_DateEnd));
if @xx2 !='OK' Then set err_code=1;  set @outMsg=concat("時間(迄) ",@xx2); end if;

set @xx3 = f_DtimeCheck(f_removeX(concat(in_Dutydate,'0000'))); 
if @xx3 !='OK' Then set err_code=1;  set @outMsg=concat("出勤日  ",@xx3); end if; 


if err_code=0 Then 
set @in_DateStart= str_to_date(concat(f_removeX(in_DateStart)),'%Y%m%d%H%i');
set @in_DateEnd  = str_to_date(concat(f_removeX(  in_DateEnd)),'%Y%m%d%H%i'); 
set @in_Dutydate = str_to_date(concat(f_removeX(  in_Dutydate)),'%Y%m%d'); 
set @in_DutyNext = @in_Dutydate + interval 1 day;

end if;

if err_code=0 And ifnull(in_OUguid,'')='' Then set err_code=1; set @outMsg="OUguid 為必要輸入條件"; end if;
if err_code=0 And ifnull(in_EmpID,'')='' Then set err_code=1; set @outMsg="EmpID 為必要輸入條件"; end if;
if err_code=0 And ifnull(in_Type,'')=''   Then set err_code=1; set @outMsg="type為必要輸入";end if;
if err_code=0 And @in_DateStart>=@in_DateEnd Then set err_code=1; set @outMsg="時間起(迄)，錯誤"; end if;


if err_code=0 Then # B01 抓guid 

      Select empguid into @in_EmpGuid from  tperson where OUguid=@in_OUguid 
       and (EmpID=@in_EmpID or EmpGuid=@in_EmpID 
        or empguid =(select empguid from tOverdoc where rwid=@in_rwid));
Select 
    codeguid into @in_TypeGuid from tcatcode
Where
    syscode = 'A02' and OUguid = @in_OUguid
        and (codeID = @in_Type or codeGuid = @in_Type);
 
end if; # B01

if err_code=0 Then # A01 加班起迄，超過二天
   Select count(*) into @isCnt
   from vdutystd_emp
   where ouguid=@in_OUguid
   and empguid=@in_Empguid
   and @in_DateStart < std_off
   and @in_DateEnd   > std_On;
   if @isCnt > 0 Then set err_code=1; set @outMsg="加班起迄錯誤"; end if;
end if;

if err_code = 0 Then # tmp01 
   drop table if exists tmp01;
create temporary table tmp01 as
select  
 a.EmpGuid AS empguid,
 a.OUguid AS ouGuid,
 a.dutydate,
 a.holiday,
 a.workguid,
 a.Std_on,
 a.Std_off, 
 a.Range_on,
 a.Range_off,
 c.overUnit,
 d.OverBeforMin,d.OverAfterMin,d.OverHolidayMin   
from vdutystd_emp a
left join tperson b on a.empguid=b.empguid
left join tovertype c on b.overtypeguid=c.overtypeguid
left join tworkinfo d on a.workguid=d.workguid
where 1=1
and a.empguid=@in_empguid
and a.dutydate = (@in_Dutydate);
select holiday  into isHoliday from tmp01;
#產生上班前加班起迄、下班後加班起迄、平時工作時間加班起迄

select count(*) into @isCnt from tmp01 where dutydate=@in_dutydate And @in_DateStart < Range_Off And @in_DateEnd > range_on;
if err_code=0 And @isCnt=0 Then set err_code=1; set @outMsg="出勤日與加班起(迄)，沒有交集"; end if;

end if; # tmp01 

if err_code=0 Then # tmp02
drop table if exists tmp02;
create  temporary table tmp02 as
select a.empguid,a.dutydate,a.holiday,a.workguid
,'Befor' ABC_type
,@in_DateStart Overtime_ST
,Case When @in_DateEnd > Std_On Then Std_on      
 Else  @in_DateEnd end Overtime_End
,OverUnit,OverBeforMin OverNeedMins
from tmp01 a 
Where @in_DateStart < Std_On /*加班起要在上班時間前，才有可能提加加班*/
and   @in_DateEnd > Range_On;

insert into tmp02 
(empguid,dutydate,holiday,workguid,ABC_type,Overtime_ST,Overtime_End
 ,OverUnit,OverNeedMins)
select a.empguid,a.dutydate,a.holiday,a.workguid,'After' ABC_type
,Case When @in_DateStart <= Std_Off Then Std_off    
 Else  @in_DateStart end AfterOver_On
,@in_DateEnd AfterOver_Off
,OverUnit,OverAfterMin 
from tmp01 a 
Where @in_DateEnd > Std_Off /*加班迄超過下班時間，才會有延後加班*/
and @in_DateStart < Range_Off;

insert into tmp02
(empguid,dutydate,holiday,workguid,ABC_type,Overtime_ST,Overtime_End
 ,OverUnit,OverNeedMins)
select a.empguid,a.dutydate,a.holiday,a.workguid,'OverH' ABC_type
,Case When @in_DateStart < Std_On Then Std_On      
 Else @in_DateStart End OverH_On
,Case When @in_DateEnd > Std_Off Then Std_Off     
 Else @in_DateEnd End OverH_Off
,OverUnit,OverHolidayMin
from tmp01 a 
Where holiday>0 And @in_DateStart < Std_Off And @in_DateEnd > Std_On
;
end if;  # tmp02

#-------產生休息時刻表
#tmp05_a 需產生休息時刻表的那幾天
#tmp05 休息時刻表

if err_code=0 Then # tmp05 休息時刻表
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

if @droptable =1 Then drop table if exists tmp05_a; end if;
-- drop table if exists tmp01;
alter table tmp05 add index (workguid,holiday);

end if; # tmp05 休息時刻表


# 計算使用的休息時間
if err_code=0 Then # tmp03
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

if @droptable =1 Then drop table if exists tmp05; end if;
-- 還不能刪 tmp02 , 後面還要用 drop table if exists tmp02;

end if; # tmp03

# tmp04 加總應扣除的休息時間
if err_code=0 Then  # tmp04 加總應扣除的休息時間
drop table if exists tmp04;
create  temporary table tmp04 as
select a.empguid,a.dutydate,a.holiday,a.abc_type
,Sum(Case When cuttime=1 Then f_minute(timediff(Use_restST,Use_restEnd)) Else 0 End) UseCutRestMins
from tmp03 a
where cuttime=1
Group by a.empguid,a.dutydate,a.holiday,a.abc_type
;
if @droptable =1 Then drop table if exists tmp03; end if;

end if; # tmp04 加總應扣除的休息時間

#tmp06 計算出三段加班時間
if err_code=0 Then # tmp06
drop table if exists tmp06;
create  temporary table tmp06 as
select 
a.empguid,a.dutydate,a.holiday,a.workguid,a.abc_type,Overtime_ST,Overtime_End
,a.OverUnit,a.OverNeedMins
,f_minute(timediff(Overtime_ST,Overtime_End))-ifnull(b.UseCutRestMins,0) OverMins
from tmp02 a
left join tmp04 b on a.empguid=b.empguid and a.dutydate=b.dutydate and a.abc_type=b.abc_type;

if @droptable =1 Then # s01 drop temp table
drop table if exists tmp02;
drop table if exists tmp04; end if; # s01 drop temp table

end if; # tmp06


# tmp07可申報小時
if err_code=0 Then # tmp07
drop table if exists tmp07;
create temporary table tmp07 as
select empguid,abc_type
,Case When OverMins>OverNeedMins
 Then if(holiday=0 and abc_type='OverH',0,floor(OverMins/OverUnit)*OverUnit/60)
 Else floor(OverMins/OverUnit)*OverUnit/60 end OverHours
# OverMins/OverUnit 等於多少申報單位
# floor(OverMins/OverUnit) 無條件捨去
# *OverUnit 換成可申報分鐘數
# /60 換成單位小時
from tmp06;

if @droptable =1 Then drop table if exists tmp06; end if;

#回傳out值
select 
  Sum(Case When abc_type='Befor' Then OverHours Else 0 End)
, Sum(Case When abc_type='OverH' Then OverHours Else 0 End)
, Sum(Case When abc_type='After' Then OverHours Else 0 End)
into iOverBefore,iOverHoliday,iOverAfter
from tmp07
Group by empguid;

if @droptable =1 Then drop table if exists tmp07; end if;
if @droptable =1 Then drop table if exists tmp01; end if;

end if; # tmp07

 set outMsg= ifnull(@outMsg,'時數計算完成'); 

end; # begin



