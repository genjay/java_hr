drop procedure if exists p_tOffDoc_04;

delimiter $$

create procedure p_tOffDoc_04
(
 inEmpGuid varchar(36),
 inofftypeguid varchar(36),
 inDateStart  datetime,
 inDateEnd    datetime,
 inRwid int, /*要修改的假單rwid*/
out outDupRWID int, /*重疊的假單rwid*/
out outOverLeft dec(8,3), /*該假別可使用時數*/
out outYearUsed dec(8,3)  /*年度使用狀況*/
,out outError varchar(3) /* 錯誤代碼 0 無錯誤可以存檔*/
)

begin

/*
 判斷請假單是否有重疊，及查詢可休補休，及年度使用時數

call p_toffdoc_04(
 (select empguid from tperson where empid='a00024' and ouguid='microjet')
,(select codeguid from tcatcode where codeid='OFF15')
,'2014-05-05 10:00:00' 
,'2014-05-05 17:20:00'
,16436
,@x
,@y
,@z
,@a);
*/

declare dutyYear int;
declare dutyFr int;
declare dutyTo int;
declare YearQuota_hr dec(8,3);

set dutyYear=year(inDateStart);
set dutyFr=dutyYear*10000+0101;
set dutyTo=dutyYear*10000+1231;

 
select # 判斷是否有重疊的假單
if(count(*)=0,0,a.rwid)  into outDupRWID
from toffdoc a
inner join tofftype b on a.offtypeguid=b.offtypeguid and b.Can_Duplicate=0
where empguid=inEmpGuid
and offDoc_end   > inDateStart /*請假起*/
and offDoc_start < inDateEnd /*請假迄*/
and a.rwid != inRwid /*請假單rwid*/
limit 1;


select count(*) into @Is_Change /*若是補休的假別*/
from tovertype 
Where OfftypeGuid=inofftypeguid
;

select QuotaCtrl into @QuotaCtrl /*若是特休類假別*/
from tofftype 
Where OffTypeGuid=inofftypeguid ; 

IF @QuotaCtrl='Y' And  @Is_Change=0 Then /*特休類*/

select sum(Off_Mins_left)/60 into outOverLeft 
from voffquota_status
Where Off_Mins_left > 0
And Empguid = inEmpGuid
And OffTypeGuid = inofftypeguid
And Quota_Valid_ST < inDateStart 
And Quota_Valid_End > inDateStart
;
set outOverLeft=ifnull(outOverLeft,0); 
end if;


IF @Is_Change > 0 /*補休的假別*/
 THEN 
  select /*補休可用時數*/
   sum(off_mins_left)/60 into outOverLeft 
  from vOffquota_status a
  Where 
  a.Off_Mins_Left > 0
  and a.empGuid=inEmpGuid
  and a.offtypeguid=inofftypeguid 
  and a.Quota_valid_St < inDateStart /*請假起*/
  and a.Quota_valid_end > inDateStart /*請假起，不是迄*/;

set outOverLeft=ifnull(outOverLeft,0);

END IF;
 

select  # 以請假(起)為基準，該年度使用該假別的時數
 sum(OffMins)/60 into outYearUsed
from toffdoc_duty a
inner join toffdoc b on a.offdocguid=b.offdocguid
Where 
	b.empguid=inEmpGuid 
and b.offtypeguid=inofftypeguid
and a.dutydate between dutyFr and dutyTo;

set outYearUsed=ifnull(outYearUsed,0);
 

IF Not (@Is_Change>0 And @QuotaCtrl='Y') /*非補休、特休類時，以年度可用假計算可用數*/ 
Then

select Year_OffDays*8 into YearQuota_hr
from tofftype
where offtypeguid=inofftypeguid;

set YearQuota_hr=ifnull(YearQuota_hr,0);


IF YearQuota_hr - outYearUsed > 0 Then  Set outOverLeft= YearQuota_hr - outYearUsed ;
end if;
  
end if;
 
select IFNULL(Year_OffDays_Check,0) into @Check_type
from tofftype
Where OffTypeGuid=inofftypeguid;


select  
Case 
 When inDateStart > inDateEnd Then '01' /*起迄不合理*/
 When Can_Duplicate=1 And outDupRWID >= 0 Then '00' /*有重疊，但該假別可以重疊輸入*/
 When Can_Duplicate=0 And outDupRWID = 0  Then '00' /*無重疊可存檔*/
 When Can_Duplicate=0 And outDupRWID > 0  Then '02' /*有重疊，但不可存檔*/
 Else '09' /*不在上述狀況中*/ 
End into @Error_code
from tofftype
where offtypeguid =inofftypeguid;

SET outError=concat(@Check_type,@Error_code);

-- select sleep(3); # 測試前面遇到回應太慢，會發生什麼事用
 

end;