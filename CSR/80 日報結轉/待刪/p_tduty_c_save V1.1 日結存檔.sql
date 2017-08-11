drop procedure if exists p_tduty_c_save;

DELIMITER $$
#加班單日結
CREATE DEFINER=`root`@`localhost` PROCEDURE `p_tduty_c_save`(
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
  set err_code=0; set outRwid=0; set outMsg='p_tduty_c_save 執行中';

if err_code=0 then # 10 處理 in_EmpX
  drop table if exists tmp00;
  create temporary table tmp00 as 
  Select empguid from tperson where OUguid=in_OUguid
  And Arrivedate<= in_Dutydate
  and ifnull(leavedate,'99991231')>=in_Dutydate;
  alter table tmp00 add index i01 (empguid);
end if; # 10

if err_code=0 then # 20
  drop table if exists tmp01;
  create temporary table tmp01 as 
  Select a.empguid,a.dutydate,a.overtypeguid
  ,(a.OverMins_Before+a.OverMins_After) OverMins
  ,(a.OverMins_Holiday) OverMins_H 
  from tOverdoc a
  left join tduty_a b on a.empguid=b.empguid and a.dutydate=b.dutydate
  where a.dutydate=in_Dutydate
  and a.empguid in (select empguid from tmp00)
  and b.CloseStatus_z07='0'
  ;

end if; # 20

if err_code=0 then # 30 計算ABC時段
  drop table if exists tmp02;
  create temporary table tmp02 as
  select a.empguid,a.dutydate,a.Overtypeguid
  ,Case 
   When ifnull(offTypeGuid,'')!='' then a.OverMins+a.OverMins_H 
   else 0 
   end  OverChange
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
  from tmp01 a
  left join tOvertype b on b.OvertypeGuid=a.OvertypeGuid;
  end if; # 30
 alter table tmp02 add index i01 (empguid,dutydate);

if err_code=0 then # 90

  delete tduty_c
  from tduty_c
  left join tduty_A x On tduty_c.empguid=x.empguid and tduty_c.dutydate=x.dutydate
  where x.CloseStatus_z07='0';

  insert into tduty_c  
  (empguid,dutydate,overtypeguid,overA,overB,overC,overH,overChange)
  select 
  empguid,dutydate,overtypeguid,overA,overB,overC,overH,overChange
  from tmp02 B;

end if; # 90


end # end Begin

