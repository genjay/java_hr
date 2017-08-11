drop procedure if exists p_tOverDoc_duty;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_tOverDoc_duty`(
 in_OUguid   varchar(36)
,in_ltUser   varchar(36)
,in_ltpid    varchar(36)  
,in_Dutydate varchar(36)
,in_EmpX      text # 預設'',字串時，未來指定單筆empguid、多筆empguid、單筆depguid、多筆depguid
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)
begin
/*
call p_tOverDoc_duty(
'microjet','ltuser','ltpid'
,'20140828'
,'' #,in_EmpX      text # 預設'',字串時，未來指定單筆empguid、多筆empguid、單筆depguid、多筆depguid
,@a,@b,@c
);
select @a,@b,@c;
*/
declare tmpVar_A text; 
declare droptable int default '0';
declare in_Close_Date date;
declare isCnt int;
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
END;

set err_code=0;
set sql_safe_updates=0;
set outMsg='p_tOverDoc_duty 執行中';

if err_code=0 then # 10 日期轉換
  set in_Dutydate=str_to_date(concat(f_removeX(in_Dutydate)),'%Y%m%d'); 
end if; # 10 

if err_code=0 then #15 判斷 tOUset 關帳日
  set isCnt=0;
  Select rwid,Close_Date into isCnt,in_Close_Date from tOUset 
  Where Close_Date >= in_DutyDate; 
  if isCnt>0 then set err_code=1; set outMsg=concat('已關帳',in_Close_Date); end if;

end if; # 15 

if err_code=0 then # 20 人員
  if in_EmpX='' then  # 空白代表執行全部
    Drop table if exists tmp01;
    Create temporary table tmp01 as
    Select Empguid from tperson 
    where OUguid=in_OUguid
     And  Arrivedate <= in_Dutydate
     And  IFNULL(Leavedate,'99991231') >= in_Dutydate;
    alter table tmp01 add index i01 (empguid);
   ELSE # 代表指定，部份人員(用到時，再撰寫)   
    Drop table if exists tmp01;
    Create temporary table tmp01 as
    Select Empguid from tperson 
    where OUguid=in_OUguid
     And  Arrivedate <= in_Dutydate
     And  IFNULL(Leavedate,'99991231') >= in_Dutydate; 
    alter table tmp01 add index i01 (empguid);
  end if;
end if; # 20 

if err_code=0 then # 30 
  
  drop table if exists tmp02;
  create temporary table tmp02 as  
  Select a.empguid,a.dutydate,a.overtypeguid
  ,Sum(a.OverMins_Before+a.OverMins_After) OverMins
  ,Sum(a.OverMins_Holiday) OverMins_H 
  from tOverdoc a
  left join tduty_a b on a.empguid=b.empguid and a.dutydate=b.dutydate
  where a.dutydate=in_Dutydate
  and a.empguid in (select empguid from tperson where ouguid=in_OUguid)
  and a.empguid in (select empguid from tmp01)
  and ifnull(b.CloseStatus_Z07,'0')='0'
  Group by a.empguid,a.dutydate,a.overtypeguid  ;
  alter table tmp02 add index i01 (empguid,dutydate);

  if droptable=1 then drop table tmp01; end if;

  drop table if exists tmp03;
  create temporary table tmp03 as
  select a.empguid,a.dutydate,a.Overtypeguid
  ,Case 
   When ifnull(offTypeGuid,'')!='' then a.OverMins+a.OverMins_H 
   else 0 
   end  OverCH
  ,Case 
   When a.OverMins>OverAMins Then b.OverAMins
   Else a.OverMins 
   end * isnull(offTypeGuid) OverA
  ,Case
   When a.OverMins>OverBMins Then b.OverBMins-b.OverAMins
   Else if(a.OverMins-b.OverAMins<0,0,a.OverMins-b.OverAMins) 
   end * isnull(offTypeGuid) OverB
  ,Case 
   When a.OverMins>OverBMins Then a.OverMins-b.OverBMins
   else 0 
   end * isnull(offTypeGuid) OverC
  ,OverMins_H * isnull(offTypeGuid) OverH
  from tmp02 a
  left join tOvertype b on b.OvertypeGuid=a.OvertypeGuid;
  alter table tmp03 add index i01 (empguid,dutydate);


  if droptable=1 then drop table tmp02; end if;
  
  drop table if exists tmp04;
  create /*temporary*/ table tmp04 as
  Select Empguid,dutydate,Overtypeguid,Sum(OverH) OverH,Sum(OverA) OverA
  ,Sum(OverB) OverB,Sum(OverC) OverC,Sum(OverCH) OverCH
  from tmp03
  Group by Empguid,dutydate,Overtypeguid;
  alter table tmp04 add index (empguid,dutydate); 
  if droptable=1 then drop table tmp03; end if;

start transaction; # 修改的 commit
  delete tOverDoc_duty  
  from tOverDoc_duty    ,tmp04  a
  Where tOverDoc_duty.empguid=a.empguid 
    and tOverDoc_duty.dutydate=a.dutydate
    and tOverDoc_duty.overtypeguid=a.overtypeguid;

  Insert into tOverdoc_duty
  (Empguid,dutydate,Overtypeguid,overA,overB,overC,overH,overCH
  ,ltUser,ltPid) 
  Select 
  Empguid,dutydate,Overtypeguid,overA,overB,overC,overH,overCH
   ,in_ltUser,in_ltPid
  from tmp04 a
  On duplicate key update
   overA=a.overA
  ,overB=a.overB
  ,overC=a.overC
  ,overH=a.overH
  ,overCH=a.overCH
  ,ltUser=in_ltUser,ltPid=in_ltPid
  ;
  commit;
 
  if droptable=1 then drop table tmp04; end if;
end if; # 30

end # end Begin