drop procedure if exists p_tduty_B_save;

DELIMITER $$
# 請假單日結
CREATE DEFINER=`root`@`localhost` PROCEDURE `p_tduty_B_save`(
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
  set err_code=0; set outRwid=0; set outMsg='p_tduty_B_save 執行中';

if err_code=0 then # 10 處理 in_EmpX
  drop table if exists tmp00;
  create temporary table tmp00 as 
  Select empguid from tperson where OUguid=in_OUguid
  And Arrivedate<= in_Dutydate
  and ifnull(leavedate,'99991231')>=in_Dutydate;
  alter table tmp00 add index i01 (empguid);
end if; # 10

if err_code=0 then # 20 產生未關帳的資料 
  drop table if exists tmp01;
  create temporary table tmp01 as
  select b.empguid,a.dutydate,a.offtypeguid,Sum(a.offMins) DutyOffMins
  from tOffdoc_duty a
  left join tOffdoc b on a.offdocguid=b.offdocguid
  left join tduty_a c on b.empguid=c.empguid and a.dutydate=c.dutydate
  where b.empguid in (select empguid from tmp00)
  and a.dutydate=in_Dutydate
  and c.CloseStatus_z07='0'
  Group by b.empguid,a.dutydate,a.offtypeguid ;

end if; # 20

if err_code=0 then # 90 資料修改

  delete tduty_b  
  from tduty_b  
  left join tduty_a x on x.empguid=tduty_b.empguid and x.dutydate=tduty_b.dutydate
  where x.dutydate=in_Dutydate
   and x.CloseStatus_z07=0 
   and tduty_b.empguid in (select empguid from tperson where OUguid=in_OUguid);

  insert into tduty_b
  (empguid,dutydate,offtypeguid,dutyoffmins)
  select 
  empguid,dutydate,offtypeguid,dutyoffmins
  from tmp01;

end if; # 90

end # end Begin