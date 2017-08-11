drop procedure if exists p_Duty_MonthSum;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_Duty_MonthSum`(
 in_OUguid   varchar(36)
,in_ltUser   varchar(36)
,in_ltpid    varchar(36)  
,in_YYYYMM   varchar(36) # 年月 201406
,in_seq      varchar(36) # default 0 
,in_DateStart  varchar(36)  # 20140601
,in_DateEnd    varchar(36)  # 20140630
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)
begin
/*
call p_Duty_MonthSum(
'microjet','ltUser','PID'
,'201406' # in_YYYYMM   varchar(36) # 年月 201406
,'0'      # in_seq      varchar(36) # default 0 
,'20140601' # in_DateStart  varchar(36)  # 20140601
,'20140630' # in_DateEnd    varchar(36)  # 20140630
,@a,@b,@c
);
 */
declare tlog_note text;
declare isCnt int; 
declare in_RangeDays int;
declare droptable int default 0; # 1 drop temptable /0 不drop 除錯用 
set err_code = 0;
set tlog_note= concat("call p_Duty_MonthSum(\n'"
,in_OUguid    ,"',\n'"
,in_ltUser    ,"',\n'"
,in_ltpid     ,"',\n'"
,in_YYYYMM    ,"',\n'"
,in_seq       ,"',\n'"
,in_DateStart ,"',\n'"
,in_DateEnd   ,"',\n"  
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");");
call p_tlog(in_ltPid,tlog_note);
call p_SysSet(1);
set outMsg='p_Duty_MonthSum,開始';

if err_code=0 then # 10 請假月結
  drop table if exists tmp01;
  Create temporary table tmp01 as
  Select b.Empguid,a.Offtypeguid
  ,in_YYYYMM PayYYYYMM,in_seq PayYYYYMM_SEQ
  ,c.deduct_percent 
 # ,(Select concat(codeid,' ',codedesc) from tcatcode where codeguid=a.Offtypeguid) offtype
  ,Sum(floor(c.Deduct_percent/100*a.OffMins)) DeductMins
  ,Sum(a.OffMins) OffMins
  from tOffDoc_duty a
  left join tOffDoc b on a.OffDocGuid=b.OffDocGuid
  left join tOfftype c on c.Offtypeguid=b.Offtypeguid
  left join tCatcode d on a.Offtypeguid=d.codeguid
  where a.dutydate between in_DateStart and in_DateEnd
   and b.empguid in (select empguid from tperson where OUguid=in_OUguid)
  Group by Empguid,a.Offtypeguid ;
end if; 

if err_code=0 then # 20 加班月結
 set outMsg='20開始';
  drop table if exists tmp02;
  create temporary table tmp02 as
  Select a.empguid ,a.Overtypeguid
  ,in_YYYYMM PayYYYYMM,in_seq PayYYYYMM_SEQ
,Sum(a.overA) overA
,Sum(a.overB) overB
,Sum(a.overC) overC
,Sum(a.overH) overH
,Sum(a.OverCh) overCh
,Sum(a.OverA*c.OverApay) PayA
,Sum(a.OverB*c.OverBpay) PayB
,Sum(a.OverC*c.OverCpay) PayC
,Sum(a.OverH*c.OverHpay) PayH 
from tOverdoc_duty a
left join tOvertype c on a.Overtypeguid=c.Overtypeguid
where a.dutydate between in_DateStart and in_DateEnd
   and a.empguid in (select empguid from tperson where OUguid=in_OUguid)
group by a.empguid ;

end if; # 20

if err_code=0 then # 30
  set in_RangeDays=datediff(in_DateEnd,in_DateStart)+1;
  drop table if exists tmp03;
  create temporary table tmp03 as
  SELECT a.empguid
  ,in_YYYYMM PayYYYYMM,in_seq PayYYYYMM_seq,in_RangeDays Range_Days
  ,in_DateStart DutyFr,in_DateEnd DutyTo
  ,Sum(WorkMins) WorkMins # 工作時間，日薪或時薪用
  ,count(*) duty_Days # 出勤天數
  FROM tDuty_a a
  Where a.dutydate between in_DateStart and in_DateEnd
   and a.empguid in (select empguid from tperson where OUguid=in_OUguid)
   group by a.empguid;

end if; # 30

if err_code=0 then # 90 資料存入 tduty_sum_a,tduty_sum_b
  delete from tduty_sum_B 
  Where empguid in (select empguid from tperson where ouguid=in_OUguid)
   And PayYYYYMM = in_YYYYMM
   And PayYYYYMM_SEQ = in_seq;
  insert into tduty_sum_B
  (Empguid,Offtypeguid,PayYYYYMM,PayYYYYMM_SEQ,OffMins,DeductMins)
  Select Empguid,Offtypeguid,PayYYYYMM,PayYYYYMM_SEQ,OffMins,DeductMins
  from tmp01 ;
  
  delete from tduty_sum_C
  Where empguid in (select empguid from tperson where ouguid=in_OUguid)
   And PayYYYYMM = in_YYYYMM
   And PayYYYYMM_SEQ = in_seq;
  insert into tduty_sum_c
  (ltUser,ltpid,empguid,PayYYYYMM,PayYYYYMM_Seq,overtypeguid,overA,overB,overC,overH,payA,payB,payC,payH)
  Select  'ltUser','ltPid'
  ,a.empguid,a.PayYYYYMM,a.PayYYYYMM_Seq,overtypeguid
  ,a.overA,a.overB,a.overC,a.overH,a.payA,a.payB,a.payC,a.payH
  from tmp02 a;

  delete from tduty_sum_A
  Where empguid in (select empguid from tperson where ouguid=in_OUguid)
   And PayYYYYMM = in_YYYYMM
   And PayYYYYMM_SEQ = in_seq;
  insert into tduty_sum_a
  (ltUser,ltpid ,
   empguid,PayYYYYMM,PayYYYYMM_Seq
   ,DutyFr,DutyTo,Duty_Days,Range_Days,WorkMins)
  Select 'ltUser','ltPid',
   empguid,PayYYYYMM,PayYYYYMM_Seq
   ,DutyFr,DutyTo,Duty_Days,Range_Days,WorkMins
  from tmp03;


end if; # 90 

end # Begin