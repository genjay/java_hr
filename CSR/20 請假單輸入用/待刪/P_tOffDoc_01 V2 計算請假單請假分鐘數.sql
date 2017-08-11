drop procedure if exists P_tOffDoc_01;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `P_tOffDoc_01`
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/
,in_EmpID varchar(36)
,in_Type varchar(36)
,in_DateStart datetime
,in_DateEnd   datetime
,out out_OffMins dec(10,3) 
,out outMsg text
)
begin
# 計算請假單單人請假總分鐘數

#tmp01 該empguid，請假範圍內的出勤資料
/*
CALL P_tOffDoc_01 (
'microjet' #ouguid
,'a00514'  #ltUser
,'',       #ltPid
'a00514'   # empid/empguid
,'off01'   # offtype/offtypeGuid
,'2014-05-12 08:00:00' # 請假起
,'2014-05-12 10:00:00' # 請假迄
,@X
,@y
);
*/
DECLARE err_code int default '0'; 


set @RunType = 0; # 0/1 測試/正常 測式中不 drop table 
set @in_OUguid =in_OUguid;
set @in_ltUser =in_ltUser ;
set @in_ltpid  =in_ltpid;
set @in_EmpID  =in_EmpID  ;
set @in_Type  =in_Type  ; 
set @in_DateStart   =  in_DateStart  ;
set @in_DateEnd     =  in_DateEnd  ;   
set @out_OffMins = 0;

set @in_EmpGuid='';
set @in_TypeGuid='';
set @in_Rwid=0; # 此處用不到，只為抓guid sql，一致性  
set @outMsg='';
set @err_code=0;

/*
if @err_code=0 And ifnull(in_OUguid,'')='' Then set @err_code=1; set @outMsg="OUguid 為必要輸入條件"; end if;
if @err_code=0 And ifnull(in_EmpID,'')='' Then set @err_code=1; set @outMsg="EmpID 為必要輸入條件"; end if;
if @err_code=0 And ifnull(in_Type,'')=''   Then set @err_code=1; set @outMsg="type為必要輸入";end if;
if @err_code=0 And ifnull(in_DateStart,'')='' Then set @err_code=1; set @outMsg="請假起，為必要輸入"; end if;
if @err_code=0 And ifnull(in_DateEnd,'')='' Then set @err_code=1; set @outMsg="請假迄，為必要輸入"; end if;
if @err_code=0 And in_DateStart>in_DateEnd Then set @err_code=1; set @outMsg="時間起迄，不合理"; end if;
  */

if @err_code=0 Then # B01 抓guid  
      Select empguid into @in_EmpGuid from  tperson where OUguid=@in_OUguid 
       and (EmpID=@in_EmpID or EmpGuid=@in_EmpID 
        or empguid =(select empguid from tOverdoc where rwid=@in_rwid));
      if ifnull(@in_EmpGuid,'')='' Then set @err_code=1; set @outMsg="工號錯誤"; end if;
 
Select 
    codeguid into @in_TypeGuid from tcatcode
Where
    syscode = 'A00' and OUguid = @in_OUguid
        and (codeID = @in_Type or codeGuid = @in_Type);
   if ifnull(@in_TypeGuid,'')='' Then set @err_code=1; set @outMsg="假別錯誤"; end if;
 
end if; # B01
######  B01   結束 ###############

if @err_code=0 Then # C01 產生請假經過的出勤日資料 
   drop table if exists tmp01;
   create temporary table tmp01 as
   select a.empguid,a.dutydate,a.holiday,a.workguid,a.std_on,a.std_off
   from vdutystd_emp a
   where 1=1
   And a.ouguid=@in_OUguid
   and a.empGuid=@in_EmpGuid
   And a.std_on <  (date(@in_DateEnd)+interval 1 day)
   And a.std_off > (date(@in_DateStart)-interval 1 day) ;  
end if;

if @err_code=0 Then # D01 產生每日請假起迄

   drop table if exists tmp02;
   create temporary table tmp02
   select a.*
   ,if(std_on > @in_Datestart,std_on,@in_Datestart) dutyoff_On #OffDuty_Fr
   ,if(std_off < @in_DateEnd,std_off,@in_DateEnd) dutyoff_Off #OffDuty_To
   from tmp01 a
   where 1=1
   and std_on < @in_DateEnd  
   and std_off > @in_DateStart;
alter table tmp02 add index i01(workguid);
end if;

if @err_code=0 Then # E01 產生休息時刻表
drop table if exists tmp_rest;
create temporary table tmp_rest
select 
    b.workguid,
    a.dutydate,
    b.holiday,
    str_to_date(concat(a.dutydate, b.sthhmm),
            '%Y-%m-%d%H:%i:%s') + interval stNext_z04 day restST,
    str_to_date(concat(a.dutydate, b.enhhmm),
            '%Y-%m-%d%H:%i:%s') + interval enNext_z04 day restEnd
from
    tmp02 a
    left join tworkrest b on b.workguid=a.workguid and a.holiday=b.holiday;

    alter table tmp_rest add index i01 (workguid,dutydate,holiday); 
end if; # E01 產生休息時刻表




if @err_code=0  Then # 計算
drop table if exists tmp03;
create temporary table tmp03 as
select a.empguid,a.dutydate,a.holiday,a.dutyoff_On,a.dutyoff_Off,"RestB" restType
,f_minute(timediff(
 Case When a.dutyoff_On <= b.restST Then b.restST Else a.dutyoff_On end  
,Case When a.dutyoff_Off >= b.restEnd Then b.restEnd Else a.dutyoff_Off end )) rest_Mins
,b.restST,b.restEnd
from tmp02 a
left join tmp_rest b on a.workguid=b.workguid and a.dutydate=b.dutydate and a.holiday=b.holiday
Where 1=1
and a.dutyoff_On < b.restEnd and a.dutyoff_Off > b.restST
and a.std_on < b.restEnd and a.std_off > b.restST  ;

alter table tmp03 add index i01 (empguid,dutydate);
end if;

if @err_code=0 Then # 加總每日休息時間
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
left join tofftype c on c.offtypeguid=@in_typeGuid ;

alter table tmp04 add index i01 (empguid);
end if;

if @err_code=0 Then # 最後回傳值
   select offunit,offMin into @offunit,@offMin
from tofftype
where offtypeguid=@in_typeGuid;

select 
Case 
 When sum(OffMins)=0 Then 0 
 When sum(offMins) < @offMin Then @offMin/60 #小於最少請假單位，則等於最少請假單位
 Else ceil(sum(offMins)/ @offunit)*@offunit /60 # 請假已大於最小請假單位，無條件進位
 End
into @out_OffMins
from tmp04
group by empguid;

set out_OffMins=@out_OffMins; 

end if;

if @RunType=1 Then # drop table 
   drop table if exists tmp01;
   drop table if exists tmp02;
   drop table if exists tmp03;
   drop table if exists tmp04;
   drop table if exists tmp_rest;
end if;
 set outMsg="執行完成";
end