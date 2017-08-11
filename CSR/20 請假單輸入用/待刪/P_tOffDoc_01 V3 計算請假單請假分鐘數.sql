drop procedure if exists P_tOffDoc_01;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `P_tOffDoc_01`
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/
,in_EmpID varchar(36)
,in_Type  varchar(36)
,in_DateStart varchar(36)
,in_DateEnd   varchar(36)
,in_Rwid   int
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


set @DropTmp = '0' ; # 0 結束後不刪除tmp table,1 刪除tmp table 
set @in_OUguid =in_OUguid;
set @in_ltUser =in_ltUser ;
set @in_ltpid  =in_ltpid;
set @in_EmpID  =in_EmpID  ;
set @in_Type  =in_Type  ; 
set @out_OffMins = 0;
set @in_EmpGuid='';
set @in_TypeGuid='';
set @in_Rwid=  in_Rwid; #  
set @outMsg='';  

set @xx1 = f_DtimeCheck(f_removeX(in_DateStart));
if @xx1 !='OK' Then set err_code=1; set @outMsg=concat("時間(起) ",@xx1); end if;
 
set @xx2 = f_DtimeCheck(f_removeX(in_DateEnd));
if @xx2 !='OK' Then set err_code=1;  set @outMsg=concat("時間(迄) ",@xx2); end if;
 
if err_code=0 Then 
set @in_DateStart= str_to_date(concat(f_removeX(in_DateStart)),'%Y%m%d%H%i');
set @in_DateEnd  = str_to_date(concat(f_removeX(  in_DateEnd)),'%Y%m%d%H%i'); 

end if;

insert into t_log(note) values ((Select concat(
"call P_tOffDoc_01("
,"'",@in_OUguid  
,"','",@in_ltUser  
,"','",@in_ltpid  
,"','",@in_EmpID  
,"','",@in_Type  
,"','",@in_DateStart 
,"','",@in_DateEnd    
,"','",@in_Rwid    ,"'"
,',@a'
,',@b'
,
");")));


if err_code=0 Then # B01 抓guid  
      Select empguid into @in_EmpGuid from  tperson where OUguid=@in_OUguid 
       and (@in_rwid=0 And (EmpID=@in_EmpID or EmpGuid=@in_EmpID)
        or empguid =(select empguid from tOffdoc where rwid=@in_rwid)); 
      if ifnull(@in_EmpGuid,'')='' Then set err_code=1; set @outMsg="工號錯誤"; end if;
 
end if; # B01

if err_code=0 Then
 
    Select 
    codeguid into @in_TypeGuid from tcatcode
    Where
    syscode = 'A00' and OUguid = @in_OUguid
        and (codeID = @in_Type or codeGuid = @in_Type);
   if ifnull(@in_TypeGuid,'')='' Then set err_code=1; set @outMsg="假別錯誤"; end if;
end if;

if err_code=0 Then # 01 判斷請假範圍內，是否包含假日，及假別是否含假日
   select IncludeHoliday into @In_Holiday from tofftype Where offtypeGuid=@in_TypeGuid;
     Select count(*) into @isCnt
     from vdutystd_emp
     Where Empguid=@in_empguid
      and @in_DateStart < Std_Off
      and @in_DateEnd  > Std_on
      and holiday=0;
    if @In_Holiday=0 And @isCnt=0 Then set err_code=1; set @outMsg="該假別，需包含上班時間"; end if;
end if; # 01 

if err_code=0 Then # C01 產生請假經過的出勤日資料 
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

if err_code=0 Then # D01 產生每日請假起迄

   drop table if exists tmp02;
   create temporary table tmp02
   select a.*
   ,if(std_on  > @in_Datestart,std_on,@in_Datestart) dutyoff_On #OffDuty_Fr
   ,if(std_off < @in_DateEnd,std_off ,@in_DateEnd) dutyoff_Off  #OffDuty_To
   from tmp01 a
   where 1=1
   and std_on  < @in_DateEnd  
   and std_off > @in_DateStart;
   alter table tmp02 add index i01(workguid);
end if;

if err_code=0 Then # E01 產生休息時刻表
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


if err_code=0  Then # 計算
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

if err_code=0 Then # 加總每日休息時間
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

if err_code=0 Then # 最後回傳值

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
   
   SELECT IFnull(sum(Off_Mins_left),0) into @OffLeftMins
   FROM csrhr.voffquota_status
   Where 
	   offTypeguid=@in_typeGuid
   and empguid=@in_Empguid
   and Off_Mins_left > 0 
   and  Quota_Valid_ST <= @in_DateStart
   and Quota_Valid_End > @in_DateStart;
	### X01 修改時，需加上自己的可休時數,只需處理quotaCtrl的假別
    set @RMins =  0;
   Select IFNULL(Sum(a.offdoc_mins) ,0) INTO  @RMins
   from tOffquota_used a
   left join vOffquota_status b on a.quotadocguid=b.quotadocguid
   Where offdocguid = (select offdocguid from toffdoc where rwid=@in_Rwid)
     and quota_valid_st < @in_DateStart
     and Quota_valid_end > @in_DateStart;
 
    set @OffLeftMins = @OffLeftMins + @RMins;
    ### x01
   Select quotactrl into @QuotaCtrl from tofftype 
    Where offtypeguid=@in_typeguid;
    IF @QuotaCtrl =1 Then  # 假別為特補休類才顯示
     Select codeDesc into @CodeDesc From tcatcode where codeguid=@in_Typeguid;
     set @outMsg=Concat("以請假(起)為基準，可用",@CodeDesc,': ',round(@OffLeftMins/60,0),'hr');
    End if;    
 
end if;

if @DropTmp Then # ZZ drop table 
   drop table if exists tmp01;
   drop table if exists tmp02;
   drop table if exists tmp03;
   drop table if exists tmp04;
   drop table if exists tmp_rest;
end if; # ZZ
  
   set outMsg=@outMsg;
end