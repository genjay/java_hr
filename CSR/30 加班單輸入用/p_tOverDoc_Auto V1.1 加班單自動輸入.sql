drop procedure if exists p_tOverDoc_Auto;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_tOverDoc_Auto`
( 
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_EmpID  varchar(36) # 工號 
,in_Dutydate   varchar(36)      
,out outMsg text  # 訊息回傳
,out outRwid int
,out err_code int 
)

begin 
declare isCnt int;
declare in_note text;
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
END;

set err_code=0; set outMsg='p_tOverDoc_Auto 執行中'; set outRwid=0;
set in_note='自動程式產生';

if err_code=0 then # 05 判斷關帳沒
  set isCnt=0;
  select rwid into isCnt from tOUset 
  Where OUguid=in_OUguid 
   And  Close_Date >= in_Dutydate;
  if isCnt>0 then set err_code=1; set outMsg='已超過關帳日'; end if;
end if; # 05

if err_code=0 then # 10
  drop table if exists tmp_p_tOverDoc_Auto_00;
  create temporary table tmp_p_tOverDoc_Auto_00 as
  Select OUguid,empguid,OvertypeGuid from tperson 
  where ouguid=in_OUguid 
  And Arrivedate<=in_Dutydate
  And ifnull(LeaveDate,'99991231') >= in_Dutydate;
  alter table tmp_p_tOverDoc_Auto_00 add index i01 (empguid);
end if; # 10

if err_code=0 then # 20 取得實際上下班時間
  drop table if exists tmp_p_tOverDoc_Auto_01;
  create temporary table tmp_p_tOverDoc_Auto_01 as
  select b.OUguid,a.empguid,a.dutydate,a.holiday,a.workguid
  ,a.realOn,a.realOff
  ,b.Overtypeguid,d.Overunit
  ,a.WorkA,a.WorkB,a.WorkC,A.RestA,a.RestB,A.RestC,a.delayBuffer_Repay,a.delayBuffer_Use
  ,c.OverBeformin,c.OverAfterMin,c.OverHolidayMin
  ,d.Valid_type_z08,d.Valid_time,d.OverToOff_Rate,d.Offtypeguid
  from tduty_a a
  inner join tmp_p_tOverDoc_Auto_00 b on a.empguid=b.empguid
  left join tworkinfo c on a.workguid=c.workguid
  left join tOvertype d on b.Overtypeguid=d.Overtypeguid
  where dutydate=in_Dutydate
   And realon is not null
   And realon <> realoff
   ;
  alter table tmp_p_tOverDoc_Auto_01 add index i01 (empguid,dutydate);
end if; 

if err_code=0 then # 30 計算加班時數
drop table if exists tmp_p_tOverDoc_Auto_02;
create temporary table tmp_p_tOverDoc_Auto_02 as
select uuid() OverDocGuid,a.OUguid,a.Empguid,a.dutydate,a.holiday
,a.realon overStart
,a.realoff overEnd
,a.Overtypeguid
,Case 
 When (a.WorkA - a.RestA) >= a.OverBeforMin Then floor((a.WorkA - a.RestA)/a.Overunit)*a.Overunit
 else 0
 end OverMins_Before
,Case
 When (a.WorkC - a.RestC-a.delayBuffer_Repay) >= a.OverAfterMin Then floor((a.WorkC - a.RestC-a.delayBuffer_Repay)/a.Overunit)*a.Overunit
 else 0 end Overmins_After
,Case 
 When a.holiday>0 Then floor((a.WorkB-a.RestB)/a.Overunit)*a.Overunit
 Else 0 end OverMins_Holiday
,a.Valid_type_z08,a.Valid_time,a.OverToOff_Rate,a.Offtypeguid
from tmp_p_tOverDoc_Auto_01 a;
  alter table tmp_p_tOverDoc_Auto_02 add index i01 (empguid,dutydate);
  alter table tmp_p_tOverDoc_Auto_02 add index i02 (Overdocguid);
end if; # 30 

if err_code=0 then # 90 新增加班單


start transaction; # 修改的 commit
  insert into toverdoc 
  (OverDocGuid,empguid,dutydate,overtypeguid,overStart,overEnd,OverMins_Before,OverMins_After,OverMins_Holiday
  ,Valid_type_z08,Valid_time,Offtypeguid,OverToOff_Rate
  ,ltUser,ltPid,note
  )
  select OverDocGuid,empguid,dutydate,overtypeguid,overStart,overEnd,OverMins_Before,OverMins_After,OverMins_Holiday
  ,Valid_type_z08,Valid_time,Offtypeguid,OverToOff_Rate
  ,in_ltUser,in_ltPid,in_note
  from tmp_p_tOverDoc_Auto_02 a
  Where 
   Not (OverMins_Before=0 and OverMins_After=0 and OverMins_Holiday=0)
   and Not exists
  (Select * from tOverdoc x where x.empguid=a.empguid and x.dutydate=a.dutydate);
 
  insert into tOffQuota
  (QuotaDocGuid,EmpGuid,Quota_Year,OffTypeGuid,Quota_seq,Quota_OffMins,Quota_Valid_ST,Quota_Valid_End,isOverDoc)
  Select OverDocGuid,EmpGuid,year(overStart),offtypeguid,0,(OverMins_Before+OverMins_After+OverMins_Holiday)*OverToOff_Rate quota_offmins
  ,OverEnd
  ,Case 
   When Valid_type_z08='m' Then OverEnd + interval ifnull(Valid_time,0) month
   When Valid_type_z08='d' Then OverEnd + interval ifnull(Valid_time,0) day
   When Valid_type_z08='y' Then OverEnd + interval ifnull(Valid_time,0) year
   end Valid_End
  ,b'1' isOverdoc 
  from tmp_p_tOverDoc_Auto_02 a  
  where 1=1
   and Not (OverMins_Before=0 and OverMins_After=0 and OverMins_Holiday=0)
   and Not exists (select * from tOffQuota x where x.QuotaDocGuid=a.OverDocGuid) 
   And IFNULL(a.offtypeguid,'')!=''; 
 set outMsg='加班單輸入完成';
 commit; 
 
end if; # 90 

if droptable=1 then
  drop table if exists tmp_p_tOverDoc_Auto_00;
  drop table if exists tmp_p_tOverDoc_Auto_01;
  drop table if exists tmp_p_tOverDoc_Auto_02; 
end if;

end; # begin



