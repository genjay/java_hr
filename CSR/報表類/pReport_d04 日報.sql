drop procedure if exists pReport_D04;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pReport_D04`(
 in_OUguid   varchar(36)
,in_ltUser   varchar(36)
,in_ltpid    varchar(36)  
,in_Dutydate varchar(36) 
,out_Table   varchar(36)
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)
begin
 
declare tlog_note text;
declare outA,outB,outC text;
declare tmpVar_A text; 
declare isCnt int;
set err_code=0;
set outRwid=0;

set outMsg='日報產生中';

if err_code=0 && substring(out_Table,1,3)!='tmp' then
  set err_code=1; set outMsg='table 名稱，一定要tmp開頭';
end if;

if err_code=0 then
  set isCnt=0;
  select count(*) into isCnt from information_schema.tables
  where table_schema=schema() and table_name=out_Table;
  if isCnt>0 then set err_code=1; set outMsg='table 已被使用'; end if;
end if;

if err_code=0 Then # 10 請假單部份
  drop table if exists tmp01; 
  create table tmp01 
  (empguid varchar(36),dutydate date,offtype varchar(36),OffMins int);

  insert into tmp01 (empguid,dutydate,offtype,offMins) 
  Select c.empguid,a.dutydate,e.codeID offtype,Sum(a.offMins) OffMins
  from tOffdoc_duty a
  left join tOffDoc b on a.OffDocguid=b.Offdocguid
  left join tperson c on c.empguid=b.empguid
  left join tcatcode e on a.offtypeguid=e.codeguid
  Where 1=1 And c.OUguid=in_OUguid and a.dutydate=in_Dutydate
  Group by  c.empguid,a.dutydate,e.codeID  
  ;

  insert into tmp01 (empguid,dutydate,offtype) 
  select '',null,codeid from tcatcode where syscode='A00';

    call p03('empguid','offtype','OffMins','tmp01','tmp01A');

  drop table if exists tmp01;
 
end if; # 10 加班單部份

if err_code=0 Then # 20 上下班時間、加班時間
  drop table if exists tmp02;
  create temporary table tmp02 as
  Select e.codeID depID,c.EmpID,c.EmpName,d.codeID WorkID
  ,a.dutydate,a.holiday,a.realon,a.realoff,a.OverA,a.OverB,a.OverC,a.OverH,a.OverCh
  ,b.*
  from tduty_a a
  left join tmp01A b on a.empguid=b.empguid 
  left join tperson c on a.empguid=c.empguid
  left join tCatcode d on a.workguid=d.codeguid
  left join tCatcode e on c.depguid=e.codeguid
  where c.OUguid=in_OUguid And a.dutydate=in_Dutydate;
set err_code=1;
end if; # 20 上下班時間、加班時間

if err_code=0 then # 90 
  drop table if exists out_Table;
  set @sql=concat('alter table tmp02 rename to ',out_Table,';');
  prepare s1 from @sql;
  execute s1;

end if; # 90
 

end # end Begin