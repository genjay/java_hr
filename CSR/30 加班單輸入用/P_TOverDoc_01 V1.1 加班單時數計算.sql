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
,out isHoliday    int # 假日
,out outMsg text  # 訊息回傳
)

begin
declare err_code int default '0';
declare isCnt int ;
declare tmpXX text;
declare in_Empguid varchar(36);
declare in_OvertypeGuid varchar(36);
declare droptable int default 1; # 0 不drop/1 drop temp table
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



if err_code=0 Then # 10 
  set outMsg='時間(起)，轉換及判斷';
  set tmpXX=f_DtimeCheck(f_removeX(in_DateStart));
  if tmpXX !='OK' Then set err_code=1; set outMsg=concat("時間(起) ",tmpXX); 
   Else set in_DateStart=str_to_date(concat(f_removeX(in_DateStart)),'%Y%m%d%H%i');
  end if;
end if; # 10  
if err_code=0 Then # 10-2  
  set outMsg='時間(迄)，轉換及判斷';
  set tmpXX = f_DtimeCheck(f_removeX(in_DateEnd));
  if tmpXX !='OK' Then set err_code=1;  set outMsg=concat("時間(迄) ",tmpXX);
   Else set in_DateEnd=str_to_date(concat(f_removeX(in_DateEnd)),'%Y%m%d%H%i');
 end if;
end if; # 10-2
if err_code=0 Then # 10-3
  set outMsg='出勤日，轉換及判斷';
  set tmpXX = f_DtimeCheck(f_removeX(concat(in_Dutydate,'0000'))); 
  if tmpXX !='OK' Then set err_code=1;  set outMsg=concat("出勤日  ",tmpXX); 
   Else set in_Dutydate=str_to_date(concat(f_removeX(in_Dutydate)),'%Y%m%d');
  end if; 
end if; # 10-3 
if err_code=0 Then # 10-4
  if in_DateStart>in_DateEnd Then set err_code=1; set outMsg='加班起迄錯誤'; end if;
end if; # 10-4
if err_code=0 Then # 11 
  set isCnt=0;
  Select rwid,empguid into isCnt,in_Empguid from tperson Where OUguid=in_OUguid And (Empguid=in_EmpID or EmpID=in_EmpID);
  if isCnt=0 Then set err_code=1; set outMsg='無此人'; end if;
end if; # 11

if err_code=0 Then # 12
  set in_OvertypeGuid='';
  Select CodeGuid into in_OvertypeGuid from tCatcode Where Syscode='A02' And OUguid=in_OUguid And (CodeID=in_type or CodeGuid=in_type);
  if in_OvertypeGuid='' Then set err_code=1; set outMsg='加班類別錯誤'; end if;
end if; # 12
if err_code=0  Then # 20 判斷加班起
  set tmpXX=''; # 暫存昨天下班時間
  Select Std_Off into tmpXX From vDutyStd_Emp 
  Where OUguid=in_OUguid And (EmpID=in_EmpID or Empguid=in_EmpID)
   And dutydate = date(in_Dutydate) - interval 1 day; 
  if tmpXX>in_DateStart Then set err_code=1; set outMsg=concat('加班起，需大於',tmpXX); end if;
end if; # 20 
if err_code=0  Then # 20-1 判斷加班迄
  set tmpXX=''; # 暫存明天上班時間
  Select Std_On into tmpXX From vDutyStd_Emp 
  Where OUguid=in_OUguid And (EmpID=in_EmpID or Empguid=in_EmpID)
   And dutydate = date(in_Dutydate) + interval 1 day; 
  if tmpXX < in_DateEnd Then set err_code=1; set outMsg=concat('加班迄，需小於',tmpXX); end if;
end if; # 20-1 

if err_code = 0 Then # 30 tmp_P_tOverDoc_01_01 
  drop table if exists tmp_P_tOverDoc_01_01;
  create temporary table tmp_P_tOverDoc_01_01 as
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
  and a.empguid= in_empguid
  and a.dutydate = (in_Dutydate);
  select holiday  into isHoliday from tmp_P_tOverDoc_01_01;
#產生上班前加班起迄、下班後加班起迄、平時工作時間加班起迄
end if; # 30 tmp_P_tOverDoc_01_01 

if err_code=0 Then # 40 tmp_P_tOverDoc_01_02
  drop table if exists tmp_P_tOverDoc_01_02;
create  temporary table tmp_P_tOverDoc_01_02 as
select a.empguid,a.dutydate,a.holiday,a.workguid
,'Befor' ABC_type
,in_DateStart Overtime_ST
,Case When in_DateEnd > Std_On Then Std_on      
 Else  in_DateEnd end Overtime_End
,OverUnit,OverBeforMin OverNeedMins
from tmp_P_tOverDoc_01_01 a 
Where in_DateStart < Std_On /*加班起要在上班時間前，才有可能提加加班*/
and   in_DateEnd > Range_On;

insert into tmp_P_tOverDoc_01_02 
(empguid,dutydate,holiday,workguid,ABC_type,Overtime_ST,Overtime_End
 ,OverUnit,OverNeedMins)
select a.empguid,a.dutydate,a.holiday,a.workguid,'After' ABC_type
,Case When in_DateStart <= Std_Off Then Std_off    
 Else  in_DateStart end AfterOver_On
,in_DateEnd AfterOver_Off
,OverUnit,OverAfterMin 
from tmp_P_tOverDoc_01_01 a 
Where in_DateEnd > Std_Off /*加班迄超過下班時間，才會有延後加班*/
and in_DateStart < Range_Off;

insert into tmp_P_tOverDoc_01_02
(empguid,dutydate,holiday,workguid,ABC_type,Overtime_ST,Overtime_End
 ,OverUnit,OverNeedMins)
select a.empguid,a.dutydate,a.holiday,a.workguid,'OverH' ABC_type
,Case When in_DateStart < Std_On Then Std_On      
 Else in_DateStart End OverH_On
,Case When in_DateEnd > Std_Off Then Std_Off     
 Else in_DateEnd End OverH_Off
,OverUnit,OverHolidayMin
from tmp_P_tOverDoc_01_01 a 
Where holiday>0 And in_DateStart < Std_Off And in_DateEnd > Std_On;

end if;  # 40 tmp_P_tOverDoc_01_02

if err_code=0 Then # 50 tmp_P_tOverDoc_01_05 休息時刻表
drop table if exists tmp_P_tOverDoc_01_05_a;

create  temporary table tmp_P_tOverDoc_01_05_a (a_date date) as
select dutydate a_date
from tmp_P_tOverDoc_01_01;

insert into tmp_P_tOverDoc_01_05_a (a_date) values 
(in_Dutydate-interval 1 day),(in_Dutydate+interval 1 day); 

drop table if exists tmp_P_tOverDoc_01_05;
create temporary table tmp_P_tOverDoc_01_05 as 
 select a.workguid,a.holiday,a.cuttime,a.sthhmm,a.enhhmm
-- ,concat(inDutyDate,a.enhhmm) aa
,str_to_date(concat(A_date,a.sthhmm),'%Y-%m-%d%H:%i:%s') + interval stNext_Z04 day restST
,str_to_date(concat(A_date,a.enhhmm),'%Y-%m-%d%H:%i:%s') + interval enNext_Z04 day restEnd
from tworkrest a
inner join tcatcode b on a.workguid=b.codeguid
left join (select * from tmp_P_tOverDoc_01_05_a) c on 1=1 
where exists (select * from tmp_P_tOverDoc_01_01 b where b.workguid=a.workguid );

if droptable =1 Then drop table if exists tmp_P_tOverDoc_01_05_a; end if;
-- drop table if exists tmp_P_tOverDoc_01_01;
alter table tmp_P_tOverDoc_01_05 add index (workguid,holiday);

end if; # 50 tmp_P_tOverDoc_01_05 休息時刻表

# 計算使用的休息時間
if err_code=0 Then # 60 tmp_P_tOverDoc_01_03
drop table if exists tmp_P_tOverDoc_01_03;
create  temporary table tmp_P_tOverDoc_01_03 as
select a.empguid,a.dutydate,a.holiday,a.workguid,a.abc_type
,b.cuttime
,overtime_st,overtime_end,restst,restend
,Case When a.Overtime_ST < b.restST    Then b.restST Else a.Overtime_ST End   Use_restSt
,Case When a.Overtime_End > b.restEnd  Then b.restEnd Else a.Overtime_End End Use_restEnd
from tmp_P_tOverDoc_01_02 a
inner join tmp_P_tOverDoc_01_05 b on a.workguid=b.workguid and a.holiday=b.holiday 
 and a.Overtime_ST < b.restEnd and a.Overtime_End > b.restST
Where Not (b.restST is null and b.restEnd is null);

if droptable =1 Then drop table if exists tmp_P_tOverDoc_01_05; end if;
-- 還不能刪 tmp_P_tOverDoc_01_02 , 後面還要用 drop table if exists tmp_P_tOverDoc_01_02;

end if; # 60 tmp_P_tOverDoc_01_03

# tmp_P_tOverDoc_01_04 加總應扣除的休息時間
if err_code=0 Then  # 70 tmp_P_tOverDoc_01_04 加總應扣除的休息時間
drop table if exists tmp_P_tOverDoc_01_04;
create  temporary table tmp_P_tOverDoc_01_04 as
select a.empguid,a.dutydate,a.holiday,a.abc_type
,Sum(Case When cuttime=1 Then f_minute(timediff(Use_restST,Use_restEnd)) Else 0 End) UseCutRestMins
from tmp_P_tOverDoc_01_03 a
where cuttime=1
Group by a.empguid,a.dutydate,a.holiday,a.abc_type
;
if droptable =1 Then drop table if exists tmp_P_tOverDoc_01_03; end if;

end if; # 70 tmp_P_tOverDoc_01_04 加總應扣除的休息時間

#tmp_P_tOverDoc_01_06 計算出三段加班時間
if err_code=0 Then # 80 tmp_P_tOverDoc_01_06
drop table if exists tmp_P_tOverDoc_01_06;
create  temporary table tmp_P_tOverDoc_01_06 as
select 
a.empguid,a.dutydate,a.holiday,a.workguid,a.abc_type,Overtime_ST,Overtime_End
,a.OverUnit,a.OverNeedMins
,f_minute(timediff(Overtime_ST,Overtime_End))-ifnull(b.UseCutRestMins,0) OverMins
from tmp_P_tOverDoc_01_02 a
left join tmp_P_tOverDoc_01_04 b on a.empguid=b.empguid and a.dutydate=b.dutydate and a.abc_type=b.abc_type;

if droptable =1 Then # s01 drop temp table
drop table if exists tmp_P_tOverDoc_01_02;
drop table if exists tmp_P_tOverDoc_01_04; end if; # s01 drop temp table

end if; # 80 tmp_P_tOverDoc_01_06


# tmp_P_tOverDoc_01_07可申報小時
if err_code=0 Then # 90 tmp_P_tOverDoc_01_07
drop table if exists tmp_P_tOverDoc_01_07;
create temporary table tmp_P_tOverDoc_01_07 as
select empguid,abc_type
,Case When OverMins>OverNeedMins
 Then if(holiday=0 and abc_type='OverH',0,floor(OverMins/OverUnit)*OverUnit/60)
 Else floor(OverMins/OverUnit)*OverUnit/60 end OverHours
# OverMins/OverUnit 等於多少申報單位
# floor(OverMins/OverUnit) 無條件捨去
# *OverUnit 換成可申報分鐘數
# /60 換成單位小時
from tmp_P_tOverDoc_01_06;

if droptable =1 Then drop table if exists tmp_P_tOverDoc_01_06; end if;

#回傳out值
select 
  Sum(Case When abc_type='Befor' Then OverHours Else 0 End)
, Sum(Case When abc_type='OverH' Then OverHours Else 0 End)
, Sum(Case When abc_type='After' Then OverHours Else 0 End)
into iOverBefore,iOverHoliday,iOverAfter
from tmp_P_tOverDoc_01_07
Group by empguid;

if droptable =1 Then drop table if exists tmp_P_tOverDoc_01_07; end if;
if droptable =1 Then drop table if exists tmp_P_tOverDoc_01_01; end if;
set outMsg='計算完成'; 
end if; # 90 tmp_P_tOverDoc_01_07

if droptable=1 then # 結束後，刪除tmp table
  drop table if exists tmp_P_tOverDoc_01_01;
  drop table if exists tmp_P_tOverDoc_01_02;
  drop table if exists tmp_P_tOverDoc_01_03;
  drop table if exists tmp_P_tOverDoc_01_04;
  drop table if exists tmp_P_tOverDoc_01_05;
  drop table if exists tmp_P_tOverDoc_01_06;
  drop table if exists tmp_P_tOverDoc_01_07;
end if;

end; # begin



