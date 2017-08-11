drop procedure if exists p_Cycle_payA;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_Cycle_payA`(
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
call p_Cycle_payA(
'microjet','ltUser','PID'
,'201408' # in_YYYYMM   varchar(36) # 年月 201406
,'0'      # in_seq      varchar(36) # default 0 
,'20140801' # in_DateStart  varchar(36)  # 20140601
,'20140831' # in_DateEnd    varchar(36)  # 20140630
,@a,@b,@c
);
 */
declare tlog_note text;
declare isCnt int;  
declare droptable int default 0; # 1 drop temptable /0 不drop 除錯用 
set err_code = 0; 

if err_code=0 then # 20 建立tmp table
  drop table if exists tmp00;
  create temporary table tmp00
  Select Empguid 
  from tperson a
  Where a.OUguid=in_OUguid
    And a.Arrivedate <= in_DateStart
    And ifnull(a.leavedate,'9999-12-31') >= in_DateEnd ;

  drop table if exists tmp09 ;
  CREATE /*temporary*/ TABLE `tmp09` (
  `rwid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ltdate` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `empguid` varchar(36) NOT NULL COMMENT '人員guid',
  `PayYYYYMM` int(11) NOT NULL,
  `PayYYYYMM_Seq` tinyint(4) NOT NULL DEFAULT '1' COMMENT '當初算薪次數，預設都是1，預留每月算薪多次時用',
  `closeStatus_z07` varchar(1) NOT NULL DEFAULT '0',
  `overA` decimal(64,30) DEFAULT NULL,
  `overB` decimal(64,30)  DEFAULT NULL,
  `overC` decimal(64,30)  DEFAULT NULL,
  `overPay_NoTax` decimal(64,30) DEFAULT NULL,
  `overPay_Tax`   decimal(64,30) DEFAULT NULL,
  `Off_Deduct`    decimal(64,30) DEFAULT NULL,
   Welfare_amt    decimal(64,30)  default null,
  PRIMARY KEY (`rwid`),
  UNIQUE KEY `uPK` (`empguid`,`PayYYYYMM`,`PayYYYYMM_Seq`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 ;

end if; # 20

if err_code=0 && 1 then # 30 加班費
  drop table if exists tmp01;
  create /*temporary*/ table tmp01 as
  Select a.empguid 
  ,cast((Case # A 月、B 日、C 時
   When type_z16='A' then Sum(PayMoney)/Days_per_Month/Hours_per_Day 
   When type_z16='B' then Sum(PayMoney)/Hours_per_Day 
   When type_Z16='C' then Sum(PayMoney)
   end ) as decimal(64,30)) Overpay_Base
  from tperson a
  left join tperson_payset b on a.empguid=b.empguid  
  left join tOUset c on a.OUguid=c.OUguid 
  where b.a06_guid in (select paytypeguid from tOUset_paybase where type_z06='A' # A 加班費 B 請假
   and ouguid=in_OUguid)
   and a.empguid in (select empguid from tmp00)
  Group by a.empguid;
  alter table tmp01 add index i01 (empguid);

  drop table if exists tmp02;
  create /*temporary*/ table tmp02 as 
  Select a.empguid
  ,cast(
   round(b.overpay_base*(a.payA+a.payB+a.payC+a.payH)/60,0) 
   as decimal(64,30)) OverPay_All
  ,cast(
   Round(Case 
   When ((a.overA+a.overB+a.overC)/60) <= c.Over_FreeTax_perMonth Then b.overpay_base*(a.payA+a.payB+a.payC)/60
   Else (((a.overA+a.overB+a.overC)/60) - c.Over_FreeTax_perMonth) * (a.payA+a.payB+a.payC)/(a.overA+a.overB+a.overC)/60
   End,0) as decimal(64,30)) overPay_NoTax 
  from tduty_sum_c a
  left join tmp01 b on a.empguid=b.empguid
  left join tOUset c on c.ouguid=in_OUguid
  Where a.PayYYYYMM=in_YYYYMM
    And a.PayYYYYMM_Seq=in_SEQ
  ;

  insert into tmp09
  (empguid,overPay_NoTax,overPay_Tax,payYYYYMM,payYYYYMM_Seq)
  Select 
  empguid,overpay_NoTax,overPay_All-overpay_NoTax,in_YYYYMM,in_SEQ
  from tmp02 a
  On duplicate key update
  overpay_NoTax=a.overpay_NoTax
  ,overPay_Tax=a.overPay_All-a.overpay_NoTax
  ;
end if; # 30 
 
if err_code=0 && 1 then # 50 請假扣薪 
  drop table if exists tmp01;
  create /*temporary*/ table tmp01 as
  Select a.empguid 
  ,cast(
   (Case # A 月、B 日、C 時
   When type_z16='A' then Sum(PayMoney)/Days_per_Month/Hours_per_Day 
   When type_z16='B' then Sum(PayMoney)/Hours_per_Day 
   When type_Z16='C' then Sum(PayMoney)
   end)
   as decimal(64,30)) Off_Base
  from tperson a
  left join tperson_payset b on a.empguid=b.empguid  
  left join tOUset c on a.OUguid=c.OUguid 
  where b.a06_guid in (select paytypeguid from tOUset_paybase where type_z06='B' # A 加班費 B 請假
   and ouguid=in_OUguid )
   and a.empguid in (select empguid from tmp00)
  Group by a.empguid;
  alter table tmp01 add index i01 (empguid);

  drop table if exists tmp02;
  create /*temporary*/ table tmp02 as
  Select a.empguid
  ,cast(Sum(deductMins*ifnull(b.off_Base,0))/60 as decimal(64,30)) Off_Deduct
  from tduty_sum_b a
  left join tmp01 b on a.empguid=b.empguid 
  Where payYYYYMM=in_YYYYMM
    And payYYYYMM_SEQ=in_SEQ
  group by a.empguid;

  insert into tmp09
  (empguid,off_deduct,payYYYYMM,payYYYYMM_Seq)
  Select
  empguid,off_deduct,in_YYYYMM,in_SEQ
  from tmp02 a
  On duplicate key update
  Off_Deduct=a.Off_Deduct 
  ;

end if; # 50 
 
if 1 && err_code=0 then # 60 福利金
  drop table if exists tmp01;
  create /*temporary*/ table tmp01 as
  Select a.empguid,cast((Sum(payMoney*c.welfare_rate)/100) as decimal(64,30)) Welfare_amt
  from tperson a
  left join tperson_payset b on a.empguid=b.empguid  
  left join tOUset c on a.OUguid=c.OUguid
  where 1=1 
  and  a06_guid in (select paytypeguid from tOUset_paybase where type_z06='C' # C 福利金
   and ouguid=in_OUguid)
  and a.empguid in (select empguid from tmp00)
  Group by a.empguid;

  drop table if exists tmp02;
  create /*temporary*/ table tmp02 as
  Select 
  a.empguid
  ,Case 
   When Duty_Days>=Range_Days Then a.Welfare_amt
   When Duty_Days>=c.days_per_month Then a.Welfare_amt
   Else Round(Duty_Days/Range_Days*a.Welfare_amt,0)
   end welfare_amt
  from tmp01 a
  left join tduty_sum_a b on a.empguid=b.empguid
  left join tOUset      c on c.OUguid=in_OUguid
  Where payYYYYMM=in_YYYYMM 
   And  payYYYYMM_Seq=in_Seq;

  insert into tmp09
  (empguid,Welfare_amt,payYYYYMM,payYYYYMM_Seq)
  Select
  empguid,Welfare_amt,in_YYYYMM,in_SEQ
  from tmp02 a
  On duplicate key update
  Welfare_amt=a.Welfare_amt 
  ;
end if; # 60

if 0 && err_code=0 then # 65 底薪、伙食津貼…依出勤天數計算之薪資

  drop table if exists tmp01; # 抓出每個人的月薪
  create /*temporary*/ table tmp01 as
  Select a.Empguid,A06_Guid
  ,Case 
   When type_z16='A' /*月薪*/ Then payMoney 
   When type_Z16='B' /*日薪*/ Then payMoney*Days_per_Month
   When type_Z16='C' /*時薪*/ Then payMoney*Days_per_Month*hours_per_day
   end payMoney
  from tperson_payset a
  left join tpaytype b on a.a06_guid=b.paytypeguid
  left join tperson  c on a.Empguid=c.Empguid
  left join tOUset   d on d.OUguid=in_OUguid
  where b.type_z10='A';

  create /*temporary*/ table tmp02 as
  Select a.Empguid,A06_Guid,
  Case 
  When a.Duty_Days=a.Range_Days Then b.PayMoney
  When a.Duty_Days>=c.days_per_month Then b.PayMoney
  Else a.Duty_Days*b.PayMoney/c.days_per_month
  end Money
  from tduty_sum_a a
  left join tmp01 b on a.empguid=b.empguid
  left join tOUset C on c.OUguid=in_OUguid
  Where payYYYYMM=in_YYYYMM
   and payYYYYMM_seq=in_seq ;

end if; # 65

end # Begin