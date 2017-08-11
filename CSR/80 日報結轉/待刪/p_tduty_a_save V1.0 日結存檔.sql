drop procedure if exists p_Duty_DaySum;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_Duty_DaySum`(
 in_OUguid   varchar(36)
,in_ltUser   varchar(36)
,in_ltpid    varchar(36)  
,in_Dutydate varchar(36)
,in_EmpX      text # 預設'',字串時，未來指定單筆empguid、多筆empguid、單筆depguid、多筆depguid
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out outError int  # err_code
)
begin
/*
call p_Duty_DaySum(
'microjet','ltuser','ltpid'
,'20140624'
,'' #,in_EmpX      text # 預設'',字串時，未來指定單筆empguid、多筆empguid、單筆depguid、多筆depguid
,@a,@b,@c
);

select @a,@b,@c;

*/
DECLARE err_code int default '0'; 
DECLARE droptable int default '0'; # 0 代表測試中 1，正常使用

set @in_OUguid = IFNULL(in_OUguid,'');
set @in_ltUser = IFNULL(in_ltUser,'');
set @in_ltpid  = IFNULL(in_ltpid,'');  
set @in_EmpX   = IFNULL(in_EmpX,'');
call p_Sysset(1);
if 1 Then  # 測試時用
   drop table if exists tmp00;
   drop table if exists tmp01;
   drop table if exists tmp02;
   drop table if exists tmp03;
   drop table if exists tmp04;
   drop table if exists tmp04_sum;
   drop table if exists tmp05;
   drop table if exists tmp06;
   drop table if exists tmp06_sum;
   drop table if exists tmp99;
   drop table if exists tmp_00;
   drop table if exists tmp_tdutya;
end if; 


if err_code=0 Then  # A 出勤日判斷
   set @xx3 = f_DtimeCheck(f_removeX(concat(in_Dutydate,'0000'))); 
   if @xx3 !='OK' Then set err_code=1;  set @outMsg=concat("出勤日  ",@xx3); end if; 
   if err_code=0 Then set @in_Dutydate = str_to_date(concat(f_removeX(  in_Dutydate)),'%Y%m%d'); end if;
   if droptable!=1 Then insert into t_log(ltpid,note) values ('p_Duty_DaySum','出勤日判斷'); end if;
end if; # A

if err_code=0 Then # 10 in_EmpX 不是空值時
# in_EmpX 可能為'' 代表該OU所有人
# in_EmpX 可能為 EmpGuid、DepGuid
   drop table if exists tmp00; 
   set @in_EmpX2= @in_EmpX;
   if @in_EmpX='' Then set @in_EmpX2="''"; end if;
   set @sql=concat("create temporary table tmp00 ENGINE=myisam as Select empguid from tperson Where "
    ,"OUguid='",@in_OUguid,"'"
    ," And ("
    ,"    empguid in (",@in_EmpX2,")"
    ," OR depguid in (",@in_EmpX2,")"
    ," OR @in_EmpX='' "
    ,")"
    ,";");
   prepare s1 from @sql;
   execute s1; 
   alter table tmp00 add index (empguid);
end if; # 10

if err_code=0 Then # 20 產生該出勤日，應出勤人員相關資訊
   drop table if exists tmp01;
   create temporary table tmp01  ENGINE=myisam as 
   select 
     c.rwid Emp_Rwid
    ,b.Dutydate
    ,b.holiday
    ,b.workguid
    ,b.Std_on
    ,b.Std_off
    ,b.Range_on
    ,b.Range_off
    ,b.delaybuffer
    ,b.cardno  
    from tmp00 a
    left join vdutystd_emp b on a.empguid=b.empguid
    left join tperson c on a.empguid=c.empguid
    Where b.dutydate=@in_Dutydate;
    alter table tmp01 add index (Emp_Rwid,dutydate);
    if droptable=1 Then drop table if exists tmp00; end if; # drop tmp01 已用不到
end if; # 20

if err_code=0 Then # 30 抓相關的tcardtime 資料
   set @NextDay = @in_Dutydate + interval 2 day;
   set @YesDay  = @in_Dutydate - interval 1 day; 
   drop table if exists tmp02;
   create temporary table tmp02 ENGINE=myisam 
   Select cardno,dtcardtime from tcardtime
    Where ouguid=@in_OUguid and dtcardtime between @YesDay and @NextDay;
   alter table tmp02 add index i01 (cardno);
end if; # 30

if err_code=0 Then # 40 計算上下班時間
   drop table if exists tmp03;
   create temporary table tmp03  ENGINE=myisam as 
   Select a.Emp_Rwid,min(dtcardtime) realOn,max(dtcardtime) realOff from tmp01 a
   left join tmp02 b on a.cardno=b.cardno
   Where dtcardtime between a.Range_on And Range_Off
   Group by a.Emp_Rwid ;
end if; # 40

if err_code=0  Then # 50
   drop table if exists tmp04;
/* 產生
 上班前 時間起迄
 上班中 時間起迄
 下班後 時間起迄
*/
   CREATE temporary TABLE `tmp04` (
     `emp_rwid` int(10) unsigned NOT NULL DEFAULT '0',
     `wType` varchar(5) NOT NULL DEFAULT '',
     `dTimeFr` datetime DEFAULT NULL,
     `dTimeTo` datetime DEFAULT NULL,
     UNIQUE KEY `u01` (`emp_rwid`,`wType`)) ENGINE=myisam DEFAULT CHARSET=utf8;

   insert into tmp04 # WorkA 上班前部份
   (emp_rwid,wType,dTimeFr,dTimeTo)
   select a.emp_rwid,'WorkA' wType
   ,IF(realOn>Std_on,Std_On,realOn)   # realOn 需放在後面(false處)，否則要在處理realOn=Null
   ,IF(realOff>Std_On,Std_On,realOff) # realOff 需放在後面(false處),否則要在處理realOff=Null
   from tmp01 a
   left join tmp03 b on a.emp_rwid=b.emp_rwid;

   insert into tmp04 # WorkB 上班中部份
   (emp_rwid,wType,dTimeFr,dTimeTo)
   select a.emp_rwid,'WorkB' wType
   ,IF(realOn <Std_On ,Std_On,realOn)   # realOn 需放在後面(false處)，否則要在處理realOn=Null
   ,IF(realOff>Std_Off,Std_Off,realOff) # realOff 需放在後面(false處),否則要在處理realOff=Null
   from tmp01 a
   left join tmp03 b on a.emp_rwid=b.emp_rwid;

   insert into tmp04 # WorkC 下班後部份
   (emp_rwid,wType,dTimeFr,dTimeTo)
   select a.emp_rwid,'WorkC' wType
   ,IF(realOn <Std_Off,Std_Off,realOn)     # realOn 需放在後面(false處)，否則要在處理realOn=Null
   ,IF(realOff < Std_Off,Std_Off,realOff)  # realOff 需放在後面(false處),否則要在處理realOff=Null
   from tmp01 a
   left join tmp03 b on a.emp_rwid=b.emp_rwid;

   drop table if exists tmp04_sum;
   create temporary table tmp04_sum as
   select emp_rwid,wType,f_minute(timediff(dTimeFr,dTimeTo)) WorkMins
   from tmp04;
   alter table tmp04_sum add index i01(emp_rwid);
 
end if; # 50


if err_code=0 Then # 60 tmp05 休息時刻表，tmp05_A 只用來join 昨天、今天、明二天
   drop table if exists tmp05_a;
   create  temporary table tmp05_a (a_date date)  ENGINE=myisam ;
   insert into tmp05_a values 
    (@in_Dutydate+interval -1 day)
   ,(@in_Dutydate+interval +0 day)
   ,(@in_Dutydate+interval +1 day)
   ,(@in_Dutydate+interval +2 day);

   drop table if exists tmp05;
   create temporary table tmp05  ENGINE=myisam as 
    select a.workguid,a.holiday,a.cuttime,a.sthhmm,a.enhhmm
    ,str_to_date(concat(A_date,a.sthhmm),'%Y-%m-%d%H:%i:%s') + interval stNext_z04 day restST
    ,str_to_date(concat(A_date,a.enhhmm),'%Y-%m-%d%H:%i:%s') + interval enNext_z04 day restEnd
    from tworkrest a
    inner join tcatcode b on a.workguid=b.codeguid 
    left join (select * from tmp05_a) c on 1=1 
    where b.ouguid=@in_OUguid;
 
    alter table tmp05 add index (workguid,holiday);
    drop table if exists tmp05_a; # tmp05 產生後，就無用了

    drop table if exists tmp06;
    create temporary table tmp06  ENGINE=myisam as #tmp06 每一時段經過的休息時間明細
    select a.emp_rwid,wType,cuttime
     ,IF(dTimeFr>restST,dTimeFr,restST)   UseRestST
     ,IF(dTimeTo<restEnd,dTimeTo,restEnd) UseRestEnd 
     ,restST,restEnd
    from tmp01 a
     left join tmp04 b on a.emp_rwid=b.emp_rwid
     inner join tmp05 c on a.workguid=c.workguid and a.holiday=c.holiday 
       and b.dTimefr<restEnd and b.dTimeTo>restST;

    if droptable=1 Then drop table if exists tmp05; end if; # tmp06 產生後，就無用了

    drop table if exists tmp06_sum;
    create table tmp06_sum  ENGINE=myisam as # tmp06_sum 每人上班前，中後，總休息時間
    select emp_rwid,wType,Sum(f_minute(timediff(UseRestST,UseRestEnd))) RestMins
    from tmp06 A
    group by  emp_rwid,wType; 
ALTER TABLE tmp06_sum ADD INDEX I01(emp_rwid,wType);

end if; # 60

if err_code=0 Then # 70 建立 tmp_tdutyA
drop table if exists tmp_tdutyA;
CREATE temporary TABLE tmp_tdutyA (
  `Emp_Rwid` int(10) ,
  `empguid` varchar(36) ,
  `dutydate` date NOT NULL ,
  `holiday` tinyint(4) DEFAULT NULL,
  `workguid` varchar(36) DEFAULT NULL,
  `Std_on` datetime DEFAULT NULL,
  `Std_off` datetime DEFAULT NULL,
  `Range_on` datetime DEFAULT NULL,
  `Range_off` datetime DEFAULT NULL,
  `cardno` varchar(50) DEFAULT NULL ,
  `realOn` datetime DEFAULT NULL,
  `realOff` datetime DEFAULT NULL,
  `WorkA` int(11) DEFAULT '0',
  `WorkB` int(11) DEFAULT '0',
  `WorkC` int(11) DEFAULT '0',
  `RestA` int(11) DEFAULT '0',
  `RestB` int(11) DEFAULT '0',
  `RestC` int(11) DEFAULT '0',
  `CloseStatus_z07` varchar(1) NOT NULL DEFAULT '0',
  `delayBuffer` int(11) DEFAULT '0',
  `delayBuffer_Use` int(11) DEFAULT '0' ,
  `delayBuffer_Repay` int(11) DEFAULT '0' ,
  `WorkMins` int(11) DEFAULT '0' ,
  `error_code` varchar(1) NOT NULL DEFAULT '9' 
) ENGINE=myisam ;
end if;

if err_code=0 Then # 80
   insert into tmp_tdutya # 80-10
   (dutydate,emp_rwid ,holiday,workguid,Std_on,Std_off,Range_on,Range_off,delaybuffer,cardno,realOn,realOff,empguid)
   SELECT 
   @in_Dutydate,a.emp_rwid ,a.holiday,a.workguid,a.Std_on,a.Std_off,a.Range_on,a.Range_off,a.delaybuffer
   ,a.cardno,c.realOn,c.realOff,b.empguid
   FROM TMP01 A
    LEFT JOIN TPERSON B ON A.emp_rwid=B.rwid
    LEFT JOIN TMP03 C ON A.emp_rwid=C.emp_rwid;
   if droptable=1 Then # 80-10A
     drop table if exists tmp01; 
     drop table if exists tmp03; end if; #  80-10A 新增tmp_tdutya 後，無用

    update tmp_tdutya a,tmp04_sum b # 80-20 補上 工作時間分鐘
    set WorkA=IFNULL(b.WorkMins,0)
    where a.emp_rwid=b.emp_rwid and b.wType='WorkA';
    update tmp_tdutya a,tmp04_sum b
    set WorkB=IFNULL(b.WorkMins,0)
    where a.emp_rwid=b.emp_rwid and b.wType='WorkB';
    update tmp_tdutya a,tmp04_sum b
    set WorkC=IFNULL(b.WorkMins,0)
    where a.emp_rwid=b.emp_rwid and b.wType='WorkC';
    if droptable=1 Then drop table if exists tmp04_sum; end if; # 80-20A


   update tmp_tdutya a,tmp06_sum b # 80-30 補上休息時間
   set restA=IFNULL(b.RestMins,0)
   where a.emp_rwid=b.emp_rwid and b.wType='WorkA';
   update tmp_tdutya a,tmp06_sum b 
   set restB=IFNULL(b.RestMins,0)
   where a.emp_rwid=b.emp_rwid and b.wType='WorkB';
   update tmp_tdutya a,tmp06_sum b 
   set restC=IFNULL(b.RestMins,0)
   where a.emp_rwid=b.emp_rwid and b.wType='WorkC';
   if droptable=1 Then drop table if exists tmp06_sum; end if; # 80-30A

   update tmp_tdutya  # 80-40 計算使用彈性分鐘數
   set 
   delayBuffer_Use=
   (Case When realOn between Std_on And Std_on + interval delayBuffer minute 
    Then f_minute(timediff(std_on,realon))
	else 0 end )
   ,delayBuffer_Repay=
   (Case When WorkC > delayBuffer_Use Then delayBuffer_Use else WorkC end );

   update tmp_tdutya a # 80-50 計算err_code 
    set error_code=
   Case 
   When (a.realOn <= a.Std_On And a.realOff >= a.Std_Off) Then '0' /*正常*/
   When (a.WorkB  + delayBuffer_repay - RestB) >= @DayWorkMins Then '0' /*使用彈性，已還清*/
   Else '1'
   End ; # 80-50 

end if;  # 80 

if err_code=0 Then # 90
 
    delete from tduty_a # 刪除未關帳，且已不需出勤的資料
    Where dutydate=@in_Dutydate
     and Empguid in (select Empguid from tperson where OUguid=@in_Ouguid)  
     and CloseStatus_Z07='0' 
     and Not Empguid in (Select Empguid from vdutystd_emp B Where ouguid=@in_OUguid And dutydate=@in_Dutydate);
 
   insert into tduty_a # 新增/修改 必需有 unique index (empguid,dutydate)
   (ltUser,ltpid
    ,empguid,dutydate,holiday,workguid,Std_on,Std_off,Range_on,Range_off,cardno,realOn,realOff,WorkA,WorkB,WorkC,RestA,RestB,RestC,CloseStatus_z07,delayBuffer,delayBuffer_Use,delayBuffer_Repay,WorkMins,error_code)
   select @in_ltUser,@in_ltpid
   ,empguid,dutydate,holiday,workguid,Std_on,Std_off,Range_on,Range_off,cardno,realOn,realOff,WorkA,WorkB,WorkC,RestA,RestB,RestC,CloseStatus_z07,delayBuffer,delayBuffer_Use,delayBuffer_Repay,WorkMins,error_code
   from tmp_tdutya a Where CloseStatus_Z07='0'
   On duplicate key Update  
    ltUser= @in_ltUser
   ,ltpid=  @in_ltPid
   ,empguid= a.empguid
   ,dutydate= a.dutydate
   ,holiday= a.holiday
   ,workguid= a.workguid
   ,Std_on= a.Std_on
   ,Std_off= a.Std_off
   ,Range_on= a.Range_on
   ,Range_off= a.Range_off
   ,cardno= a.cardno
   ,realOn= a.realOn
   ,realOff= a.realOff
   ,WorkA= a.WorkA
   ,WorkB= a.WorkB
   ,WorkC= a.WorkC
   ,RestA= a.RestA
   ,RestB= a.RestB
   ,RestC= a.RestC
   ,CloseStatus_z07= a.CloseStatus_z07
   ,delayBuffer= a.delayBuffer
   ,delayBuffer_Use= a.delayBuffer_Use
   ,delayBuffer_Repay= a.delayBuffer_Repay
   ,WorkMins= a.WorkMins
   ,error_code= a.error_code
   ;

   if droptable=1 Then drop table if exists tmp_tdutya; end if;
   set @outMsg="tduty_a 執行成功";
   

end if; # 90
 
   if 1=1 Then # End 回傳用，不分對錯
      set outMsg=@outMsg;
      
   end if;

end # end Begin