drop procedure if exists p_Cycle_payA;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_Cycle_payA`(
 in_OUguid   varchar(36)
,in_ltUser   varchar(36)
,in_ltpid    varchar(36)  
,in_payYYYYMM        varchar(36) # 年月 201406
,in_payYYYYMM_seq  varchar(36) # default 0 
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
set sql_safe_updates=0;

if err_code=0 then # 10 判斷能否執行相關防呆
  # 判斷薪資設定是否全部設定完成
  set @x=0;
end if; # 10

if err_code=0 then # 20 建立tmp table
  drop table if exists tmp00;
  create temporary table tmp00 engine=myisam
  Select a.OUguid,Empguid 
  from tperson a
  Where a.OUguid=in_OUguid
    And a.Arrivedate <= in_DateStart
    And ifnull(a.leavedate,'9999-12-31') >= in_DateEnd ;
  alter table tmp00 add index i01 (empguid);

  drop table if exists tmp01;
  create temporary table tmp01 engine=myisam
  Select a.OUguid,a.empguid
  ,c.a06_guid,b.type_z16
  ,cast(Case 
   When b.type_Z16='M' Then c.PayMoney
   When b.type_Z16='D' Then c.PayMoney*d.Days_per_Month
   When b.type_Z16='H' Then c.PayMoney*d.Hours_per_Day*d.Days_per_Month
   End as decimal(40,5)) Money_M 
  ,d.Days_per_Month,d.Hours_per_Day
  ,d.Over_FreeTax_perMonth
  ,b.Welfare_rate
  from tmp00 a
  left join tperson b on a.empguid=b.empguid
  left join tperson_payset c on a.empguid=c.empguid
  left join tOUset  d on d.OUguid=b.OUguid;
  alter table tmp01 add index i01 (empguid);

end if; # 20 

if err_code=0 then # 25
  drop table if exists tmp09A;
  create temporary table tmp09A engine=myisam
  Select * from tcycle_pay_head
  limit 0;
  alter table tmp09A add unique index u01(empguid,payYYYYMM,payYYYYMM_seq);

  drop table if exists tmp09B;
  create temporary table tmp09B
  SELECT * FROM csrhr.tcycle_pay limit 0;
  alter table tmp09B add unique index u01(empguid,payYYYYMM,payYYYYMM_seq,paytypeguid);
end if; # 25


if err_code=0 then # 請假
  drop table if exists tmp03;
  create temporary table tmp03 engine=myisam
  Select a.empguid ,a.payYYYYMM,a.payYYYYMM_Seq
  ,cast(ifnull(Sum(a.DeductMins/60
   *b.Money_M/Days_per_Month/Hours_per_day),0)
   as decimal(10,3)) Off_deduct 
  from tduty_sum_b a
  left join tmp01 b on a.empguid=b.empguid
  Where b.a06_guid in 
   (select paytypeguid from tOUset_paybase x Where x.OUguid=in_OUguid and x.type_z06='B'/*B請假*/)
    And payYYYYMM=in_payYYYYMM
    And payYYYYMM_Seq=in_payYYYYMM_seq
  Group by a.empguid;

  insert into tmp09A
  (empguid,payYYYYMM,payYYYYMM_Seq,Off_deduct)
  Select
   empguid,payYYYYMM,payYYYYMM_Seq,Off_deduct
  from tmp03 a
  on duplicate key update
  Off_deduct=a.Off_deduct;

end if; # 30 請假

if err_code=0 then # 40 加班
  drop table if exists tmp03;
  create temporary table tmp03 engine=myisam
  Select a.empguid,a.payYYYYMM,a.payYYYYMM_seq
  ,Over_freetax_perMonth
  ,Sum((a.payA+a.payB+a.payC)/60
   *b.money_m/days_per_month/hours_per_day) overPay_ABC
  ,Sum((a.payA+a.payB+a.payC+a.payH)/60
   *b.money_m/days_per_month/hours_per_day) overPay_all
  ,Sum((a.overA+a.overB+a.overC))/60 overABC_hr 
  from tduty_sum_c a
  left join tmp01 b on a.empguid=b.empguid 
  Where b.a06_guid in 
   (select paytypeguid from tOUset_paybase x Where x.OUguid=in_OUguid and x.type_z06='A'/*A加班*/)
    And payYYYYMM=in_payYYYYMM
    And payYYYYMM_Seq=in_payYYYYMM_Seq
  Group by a.empguid;

  drop table if exists tmp03a;
  create temporary table tmp03a engine=myisam
  Select a.empguid,a.payYYYYMM,a.payYYYYMM_seq
  ,a.overPay_all  
  ,Case 
   When overABC_hr > Over_freetax_perMonth Then
    overPay_ABC/overABC_hr*Over_freetax_perMonth # 用平均法來算 46小時免稅金額
   Else overPay_all End overPay_noTax
  from tmp03 a ;
  alter table tmp03 add index i01 (empguid);

  insert into tmp09A
  (empguid,overPay_NoTax,overPay_tax,payYYYYMM,payYYYYMM_seq)
  Select
   empguid,overPay_noTax,overPay_all-overPay_noTax,payYYYYMM,payYYYYMM_seq
  from tmp03a a
  On duplicate key update
   overPay_noTax=a.overPay_noTax
  ,overPay_tax=a.overPay_all-a.overPay_noTax;
end if; # 40

if err_code=0 then # 45 福利金
  drop table if exists tmp03;
  create temporary table tmp03 engine=myisam
  Select a.empguid,b.payYYYYMM,b.payYYYYMM_seq
  ,Sum(Case 
   When b.duty_days>=b.Range_days     Then a.money_m*a.welfare_rate/100
   When b.duty_days>=a.days_per_month Then a.money_m*a.welfare_rate/100
   Else b.duty_days*a.money_m*a.welfare_rate/100/days_per_month
   end) Welfare 
  from tmp01 a
  left join tduty_sum_a b on a.empguid=b.empguid
  where a.a06_guid in 
   (select paytypeguid from tOUset_paybase x Where x.OUguid=in_OUguid and x.type_z06='C'/*C福利金*/)
   And b.PayYYYYMM=in_PayYYYYMM
   And b.payYYYYMM_seq=in_payYYYYMM_seq
  Group by a.empguid;
  alter table tmp03 add index i01 (empguid);

  Insert into tmp09A
  (empguid,Welfare,payYYYYMM,payYYYYMM_seq)
  Select
  empguid,Welfare,payYYYYMM,payYYYYMM_seq
  from tmp03 a
  on duplicate key update
  Welfare=a.Welfare;

end if; # 45 福利金

if err_code=0 then # 50 底薪、伙食津貼 type_z10='A' 
  drop table if exists tmp03;
  create temporary table tmp03 engine=myisam
  Select a.empguid,b.payYYYYMM,b.payYYYYMM_seq
  ,a06_guid paytypeguid
  ,Case 
   When b.duty_days>=b.Range_days      Then a.Money_m
   When b.duty_days>=a.days_per_month  Then a.Money_m
   When b.duty_days < a.days_per_month Then a.Money_m/a.days_per_month*duty_days
   end pay_Amt 
  from tmp01 a 
  left join tduty_sum_a b on a.empguid=b.empguid
  where a.a06_guid in
   (Select a06_guid from tOUset_paytype_h where type_z10='A'/*依天數計算的薪資類別*/)
   And  b.payYYYYMM=in_payYYYYMM
   And  b.payYYYYMM_seq=in_payYYYYMM_seq;

  insert into tmp09B
  (empguid,paytypeguid,pay_Amt,payYYYYMM,payYYYYMM_seq)
  Select empguid,paytypeguid,ifnull(pay_Amt,0),payYYYYMM,payYYYYMM_seq
  from tmp03 a
  on duplicate key update
  pay_Amt=a.pay_Amt;

end if; # 50 底薪、伙食津貼 type_z10='A' 


if err_code=0 && 1 then # 55 勞保費
  # 勞保、勞退，都以每月 30天計算
  # 2/28加保，算 3天
  # 2/1~2/28 退保算 28天
  # 30、31 加保都算 1天
  
  drop table if exists tmp03;
  create temporary table tmp03 engine=myisam as
  Select a.Empguid,c.type_z21,rate,self_payRate,company_payrate
  from tperson a
  left join tperson_insurance b on b.empguid=a.empguid
  left join touset_insurance c on b.typea16_guid=c.typea16_guid
  Where a.empguid in (select empguid from tmp00)
    And c.type_Z21 in ('A','B','C','D');
  alter table tmp03 add index i01 (empguid);

 drop table if exists tmp04;
 create temporary table tmp04 engine=myisam as
 SELECT a.empguid,labor_lv
 ,cast(if(in_DateStart<=labor_valid_st,labor_valid_st,in_DateStart) as date) labor_st
 ,cast(if(in_DateEnd  >=labor_valid_end,labor_valid_end,in_DateEnd) as date) labor_end 
 ,Case When ifnull(labor_valid_end,'9999-12-31') > in_DateEnd then 1 
  else 0 end  isStay
 FROM csrhr.tperson_insurance a 
 Where a.empguid in (select empguid from tmp00);
 alter table tmp04 add index i01 (empguid);
 
 drop table if exists tmp05;
 create temporary table tmp05 engine=myisam as
 Select a.empguid,labor_lv
 ,labor_end,labor_st
 ,isstay
 ,Case
  When isStay=1 && month(labor_st)=2 
   then datediff(labor_end,labor_st)+1+(30-day(labor_end))
  When isStay in (0,1)
   then if(datediff(labor_end,labor_st)+1>30,30,datediff(labor_end,labor_st)+1)
  end labor_days
 from tmp04 a ;
 alter table tmp05 add index (empguid);

 drop table if exists tmp06;
 create temporary table tmp06 engine=myisam as
 Select a.empguid,b.type_z21 
 ,Round(labor_lv*rate/100*labor_days/30*self_payrate/100,0) labor_emp
 ,Round(labor_lv*rate/100*labor_days/30*company_payrate/100,0) labor_com
 from tmp05 a
 left join tmp03 b on a.empguid=b.empguid ;
 
 drop table if exists tmp07;
 create temporary table tmp07 engine=myisam as
  Select a.empguid
 ,Sum(labor_emp) labor_emp
 ,Sum(labor_com) labor_com
 from tmp06 a
 group by empguid;
 
  insert into tmp09A
  (empguid,payYYYYMM,payYYYYMM_seq,labor_emp,labor_com)
  Select empguid,in_payYYYYMM,in_payYYYYMM_seq,labor_emp,labor_com
  from tmp07 a 
  group by empguid
  on duplicate key update
  labor_emp=labor_emp,
  labor_com=labor_com; 

end if; # 55 勞保費

 
if err_code=0 && 1 then # 60 勞退
  drop table if exists tmp03;
  create temporary table tmp03 engine=myisam as
  Select a.Empguid,c.type_z21,rate,self_payRate,company_payrate
  from tperson a
  left join tperson_insurance b on b.empguid=a.empguid
  left join touset_insurance c on b.typea16_guid=c.typea16_guid
  Where a.empguid in (select empguid from tmp00);
  alter table tmp03 add index i01 (empguid);

 drop table if exists tmp04;
 create temporary table tmp04 engine=myisam as
 SELECT a.empguid,LP_lv
 ,cast(if(in_DateStart<=LP_valid_st,LP_valid_st,in_DateStart) as date) labor_st
 ,cast(if(in_DateEnd  >=LP_valid_end,LP_valid_end,in_DateEnd) as date) labor_end 
 ,Case When ifnull(LP_valid_end,'9999-12-31') > in_DateEnd then 1 
  else 0 end  isStay
 FROM csrhr.tperson_insurance a 
 Where a.empguid in (select empguid from tmp00);
 alter table tmp04 add index i01 (empguid);

 drop table if exists tmp05;
 create temporary table tmp05 engine=myisam as
 Select a.empguid,LP_lv
 ,labor_end,labor_st
 ,isstay
 ,Case
  When isStay=1 && month(labor_st)=2 
   then datediff(labor_end,labor_st)+1+(30-day(labor_end))
  When isStay in (0,1)
   then if(datediff(labor_end,labor_st)+1>30,30,datediff(labor_end,labor_st)+1)
  end labor_days
 from tmp04 a ;
 alter table tmp05 add index (empguid);

 drop table if exists tmp06;
 create temporary table tmp06 engine=myisam
 SELECT a.empguid,Round(lp_lv*lp_rate/100*labor_days/30,0) LP_Amt_com
 FROM tmp05 a 
 left join tOUset b on b.OUguid=in_OUguid;

  insert into tmp09A
  (empguid,payYYYYMM,payYYYYMM_seq,LP_com)
  Select empguid,in_payYYYYMM,in_payYYYYMM_seq,LP_Amt_com
  from tmp06 a 
  on duplicate key update
  LP_com=LP_Amt_com;

end if; # 60 勞退 

if err_code=0 && 1 then # 65 健保費
  drop table if exists tmp03;
  create temporary table tmp03 engine=myisam as
  Select a.Empguid,NHI_LV
  ,Case
   When IFNULL(NHI_Valid_End,'9999-12-31')>=in_DateEnd Then 1
   When NHI_Valid_End < in_DateEnd Then 0
   When NHI_Valid_End=NHI_Valid_St Then 0 
   Else 1
   End NHI_Need
  ,Round(NHI_LV*b.Rate/100*b.self_payRate/100,0)    NHI_Amt
  ,Round(NHI_LV*b.Rate/100*b.company_payRate/100,0) NHI_Amt_com 
  from tperson_insurance a
  left join tOUset_insurance b on b.OUguid=in_OUguid and a.typeA16_guid=b.typeA16_guid and b.type_z21='E'
  where a.empguid in (select empguid from tmp00);

  drop table if exists tmp04;
  create temporary table tmp04 engine=myisam as
  Select a.empguid,a.fam_id,(1-b.subsidy_rate/100)*NHI_Amt NHI_Amt_fam
  from tperson_family a
  left join touset_subsidy b on b.ouguid=in_ouguid and b.type_z19=a.type_z19
  left join tmp03 c on a.empguid=c.empguid and c.nhi_need=1
  where Valid_st  <= in_DateEnd
    And ifnull(Valid_End,'9999-12-31') >= in_DateStart;

  drop table if exists tmp05;
  create temporary table tmp05 engine=myisam as
  select a.*,@rownum:=@rownum+1 seq
  from (select * from tmp04 order by empguid,nhi_amt_fam asc,fam_id) a
  left join (select @rownum:=0) b on 1=1 ;

  drop table if exists tmp06;
  create temporary table tmp06
  select empguid,min(seq) seq_min from tmp05
  group by empguid
  ;

  drop table if exists tmp07;
  create temporary table tmp07 engine=myisam
  Select a.empguid,a.fam_id,seq_min,seq
  ,Case
   When seq-seq_min >=3 then 0 /*眷屬超過3人，不需要收費*/
   else nhi_amt_fam
   end nhi_amt_emp
  ,cast(0 as signed) nhi_amt_com
  from tmp05 a
  left join tmp06 b on a.empguid=b.empguid;

  drop table if exists tmp09c;
  create temporary table tmp09c engine=myisam
  Select empguid,payYYYYMM,payYYYYMM_seq,fam_id,NHI_amt_emp,NHI_amt_com from tcycle_pay_nhi limit 0;

  insert into tmp09c # 員工本身健保
  (empguid,payYYYYMM,payYYYYMM_seq,fam_id,nhi_amt_emp,nhi_amt_com)
  select empguid,in_payYYYYMM,in_payYYYYMM_seq,'emp' fam_id,nhi_amt,nhi_amt_com from tmp03;

  insert into tmp09c # 眷屬健保
  (empguid,payYYYYMM,payYYYYMM_seq,fam_id,nhi_amt_emp,nhi_amt_com)
  Select empguid,in_payYYYYMM,in_payYYYYMM_seq,fam_id,nhi_amt_emp,nhi_amt_com from tmp07;

  update tmp09a a,(select empguid,sum(nhi_amt_emp) emp,sum(nhi_amt_com) com
  from tmp09c
  group by empguid) b
  set a.nhi_emp=b.emp,a.nhi_com=b.com
  where a.empguid=b.empguid;

  end if; # 65 健保費

if err_code=0 then # 90 資料寫入
 
  Delete from tcycle_pay_nhi
  Where Empguid in (Select Empguid from tperson where OUguid=in_OUguid)
    And payYYYYMM=in_payYYYYMM
    And payYYYYMM_seq=in_payYYYYMM_seq;

  Insert into tcycle_pay_nhi
  (empguid,payYYYYMM,payYYYYMM_seq,fam_id,NHI_amt_emp,NHI_amt_com)
  Select empguid,payYYYYMM,payYYYYMM_seq,fam_id,NHI_amt_emp,NHI_amt_com
  from tmp09c b;

  Delete from tcycle_pay
  Where Empguid in (Select Empguid from tperson where OUguid=in_OUguid)
    And payYYYYMM=in_payYYYYMM
    And payYYYYMM_seq=in_payYYYYMM_seq;
  Insert into tcycle_pay
  (empguid,payYYYYMM,payYYYYMM_seq,Paytypeguid,pay_amt)
  Select empguid,payYYYYMM,payYYYYMM_seq,Paytypeguid,pay_amt
  from tmp09b b;

  Delete from tcycle_pay_head
  Where Empguid in (Select Empguid from tperson where OUguid=in_OUguid)
    And payYYYYMM=in_payYYYYMM
    And payYYYYMM_seq=in_payYYYYMM_seq;

 Insert into tcycle_pay_head
 (empguid,PayYYYYMM,PayYYYYMM_Seq,closeStatus_z07,overA,overB,overC,overPay_NoTax,overPay_Tax
 ,Off_Deduct,Welfare,labor_emp,labor_com,LP_com,NHI_emp,NHI_com)
 select empguid,PayYYYYMM,PayYYYYMM_Seq,closeStatus_z07,overA,overB,overC,overPay_NoTax,overPay_Tax
 ,Off_Deduct,Welfare,labor_emp,labor_com,LP_com,NHI_emp,NHI_com 
 from tmp09a; 

end if; # 90 


end # Begin