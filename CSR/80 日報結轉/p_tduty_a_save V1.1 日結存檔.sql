drop procedure if exists p_tduty_A_save;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_tduty_A_save`(
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
call p_tduty_A_save(
'microjet','ltuser','ltpid'
,'20140624'
,'' #,in_EmpX      text # 預設'',字串時，未來指定單筆empguid、多筆empguid、單筆depguid、多筆depguid
,@a,@b,@c
);
select @a,@b,@c;
*/
declare tmpVar_A text; 
declare droptable bit default b'0';

set err_code=0;
set sql_safe_updates=0;

if err_code=0 Then  # A 出勤日判斷
   set tmpVar_A = f_DtimeCheck(f_removeX(concat(in_Dutydate,'0000'))); 
   if  tmpVar_A !='OK' Then set err_code=1;  set outMsg=concat("出勤日  ",tmpVar_A); end if; 
   if err_code=0 Then set in_Dutydate = str_to_date(concat(f_removeX(  in_Dutydate)),'%Y%m%d'); end if;
   call p_tlog(in_ltPid,'出勤日判斷結束');
   set outMsg="A 出勤日判斷";
end if; # A

if err_code=0 then # 出勤日不能超過今天
   if in_Dutydate > date(now()) Then set err_code=1; set outMsg="結轉日期不可超過今天"; end if;
end if;

if err_code=0 Then # 10 in_EmpX 不是空值時
# in_EmpX 可能為'' 代表該OU所有人
# in_EmpX 可能為 EmpGuid、DepGuid
   drop table if exists tmp00;   
   Create temporary table tmp00 Engine=Myisam
   Select empguid from tperson 
   Where OUguid = in_OUguid 
   And ArriveDate <= in_Dutydate
   And ifnull(LeaveDate,'9999-12-31') >= in_Dutydate 
;

   call p_tlog(in_ltPid,'10 in_EmpX 結束'); 
   alter table tmp00 add index (empguid);
   set outMsg="10 in_EmpX 不是空值時";
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
    ,b.workminutes std_WorkMins
    from tmp00 a
    left join vdutystd_emp b on a.empguid=b.empguid
    left join tperson c on a.empguid=c.empguid
    Where b.dutydate= in_Dutydate;
    alter table tmp01 add index (Emp_Rwid,dutydate);
    call p_tlog(in_ltPid,'20 產生該出勤日，應出勤人員相關資訊');
   set outMsg="20 產生該出勤日";
end if; # 20

if err_code=0 Then # 30 抓相關的tcardtime 資料 
   drop table if exists tmp02;
   create temporary table tmp02 ENGINE=myisam 
   Select cardno
   ,substring(dtcardtime,1,16) dtcardtime # 不要處理秒數，否則會有因秒造成的分鐘差異
   from tcardtime
    Where ouguid=in_OUguid and dtcardtime between(in_Dutydate - interval 1 day) and (in_Dutydate + interval 2 day);
   alter table tmp02 add index i01 (cardno);
   call p_tlog(in_ltPid,'30 抓相關的tcardtime 資料');
   set outMsg="30 抓tcardtime";
end if; # 30

if err_code=0 Then # 40 計算上下班時間
   drop table if exists tmp03;
   create temporary table tmp03  ENGINE=myisam as 
   Select a.Emp_Rwid,min(dtcardtime) realOn,max(dtcardtime) realOff from tmp01 a
   left join tmp02 b on a.cardno=b.cardno
   Where dtcardtime between a.Range_on And Range_Off
   Group by a.Emp_Rwid ;
   call p_tlog(in_ltPid,'40 計算上下班時間');   
   set outMsg="40 計算上下班時間";
end if; # 40

if err_code=0  Then # 50 上班前、中、後，時間起迄
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
   ,IF(realOn <Std_On ,Std_On,if(realOn>Std_Off,Std_Off,realOn))   # realOn 需放在後面(false處)，否則要在處理realOn=Null
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

   call p_tlog(in_ltPid,'50 上班前、中、後，時間起迄');
   set outMsg="50 上班前、中、後，時間起迄";
 
end if; # 50

if err_code=0 Then # 60 tmp05 休息時刻表，tmp05_A 只用來join 昨天、今天、明二天
   drop table if exists tmp05_a;
   create  temporary table tmp05_a (a_date date)  ENGINE=myisam ;
   insert into tmp05_a values 
    (in_Dutydate+interval -1 day)
   ,(in_Dutydate+interval +0 day)
   ,(in_Dutydate+interval +1 day)
   ,(in_Dutydate+interval +2 day);

   drop table if exists tmp05;
   create temporary table tmp05  ENGINE=myisam as 
    select a.workguid,a.holiday,a.cuttime,a.sthhmm,a.enhhmm
    ,str_to_date(concat(A_date,a.sthhmm),'%Y-%m-%d%H:%i:%s') + interval stNext_z04 day restST
    ,str_to_date(concat(A_date,a.enhhmm),'%Y-%m-%d%H:%i:%s') + interval enNext_z04 day restEnd
    from tworkrest a
    inner join tcatcode b on a.workguid=b.codeguid 
    left join (select * from tmp05_a) c on 1=1 
    where b.ouguid=in_OUguid;
 
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
    create temporary table tmp06_sum  ENGINE=myisam as # tmp06_sum 每人上班前，中後，總休息時間
    select emp_rwid,wType,Sum(f_minute(timediff(UseRestST,UseRestEnd))) RestMins
    from tmp06 A
    group by  emp_rwid,wType; 
    ALTER TABLE tmp06_sum ADD INDEX I01(emp_rwid,wType);
    call p_tlog(in_ltPid,'60 tmp05 休息時刻表，tmp05_A 只用來join 昨天、今天、明二天');
    set outMsg="60 tmp05 休息時刻表";

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
   Std_WorkMins int default '0', 
  `error_code` varchar(1) NOT NULL DEFAULT '9' ,
  `overA` int(11) DEFAULT NULL COMMENT '加班 A',
  `overB` int(11) DEFAULT NULL COMMENT '加班 B',
  `overC` int(11) DEFAULT NULL COMMENT '加班 C',
  `overH` int(11) DEFAULT NULL COMMENT '假日加班',
  `overCH` int(11) DEFAULT NULL COMMENT '換休加班',
  `OffMins` int(11) DEFAULT NULL COMMENT '請假時間(分)',
   OffDesc text
) ENGINE=myisam ;
  alter table tmp_tdutyA add index i01 (empguid,dutydate);
  call p_tlog(in_ltPid,'70 建立tmp_dutya');
  set outMsg="70 建立tmp_dutya";
end if; # 70

if err_code=0 Then # 80
   insert into tmp_tdutya # 80-10
   (dutydate,emp_rwid ,holiday,workguid,Std_on,Std_off,Range_on,Range_off,delaybuffer
   ,cardno,realOn,realOff,empguid,Std_WorkMins)
   SELECT 
   in_Dutydate,a.emp_rwid ,a.holiday,a.workguid,a.Std_on,a.Std_off,a.Range_on,a.Range_off,a.delaybuffer
   ,a.cardno,c.realOn,c.realOff,b.empguid,a.Std_WorkMins
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
   (Case When WorkC > delayBuffer_Use Then delayBuffer_Use 
         When RealOff < Std_Off Then delayBuffer_Use else WorkC end );

   update tmp_tdutya
   Set
   WorkMins=Case
    When realON<=std_on And realOff>=Std_off Then Std_WorkMins
    Else WorkB-RestB+delayBuffer_Repay
    end ;

## 加班單結轉
  drop table if exists tmp08;
  create temporary table tmp08 as
  Select a.empguid,a.dutydate
  ,sum(overA) overA,sum(overB) overB,sum(overC) overC
  ,sum(overH) overH,sum(overCH) overCH
  from tOverdoc_duty a 
  Where  a.empguid in (select empguid from tmp00)
   And a.empguid in (select empguid from tperson where ouguid=in_OUguid)
   And a.dutydate=in_Dutydate
  Group by empguid,dutydate;
 
  update tmp_tdutya a,tmp08  b
  set a.OverA=b.OverA
  ,a.OverB=b.OverB
  ,a.OverC=b.OverC
  ,a.OverH=b.OverH
  ,a.OverCH=b.OverCh
  Where a.empguid=b.empguid and a.dutydate=b.dutydate;  
  if droptable=1 then drop table if exists tmp08; end if;

#############################
  drop table if exists tmp09;
  create temporary table tmp09 as
  select b.Empguid,a.Dutydate,Sum(a.OffMins) OffMins 
  ,group_concat(concat(c.codeDesc,' ',a.offmins,'分')) OffDesc
  from toffdoc_duty a
  left join tOffdoc b on a.OffDocGuid=b.OffDocGuid
  left join tCatcode c on a.offtypeguid=c.codeguid
  Where b.empguid in (select empguid from tmp00 ) 
   And  a.Dutydate=in_Dutydate
  Group by b.Empguid,a.Dutydate; 
 
  update tmp_tdutya a,tmp09 b
  set a.OffMins=b.OffMins
	 ,a.OffDesc=b.OffDesc
  Where a.empguid=b.empguid and a.dutydate=b.dutydate;

  if droptable=1 then drop table if exists tmp09; end if;

   update tmp_tdutya a,tperson b  # 80-50 計算err_code 
    set error_code=
   Case 
   When b.IsCheckIn_Z03=0 Then '0' # 0 不需檢查
   When (a.realOn <= a.Std_On And a.realOff >= a.Std_Off) Then '0' /*正常*/
   When (a.WorkB  + delayBuffer_repay - RestB) >= std_WorkMins Then '0' /*使用彈性，已還清*/
   When  (a.WorkB  + delayBuffer_repay - RestB+ a.OffMins) >= std_WorkMins Then '0' # 需請假，也請足時數
   Else '1'
   End 
   where a.empguid=b.empguid; # 80-50 

   set outMsg="80";
  call p_tlog(in_ltPid,'80');
end if;  # 80 

if err_code=0 Then # 90 
 
  Delete from tduty_A # 刪除, 未關帳、已不需要出勤的資料
   Where 1=1
   And CloseStatus_Z07=0
   And dutydate=in_Dutydate 
   And Not Empguid in (Select Empguid from tperson Where OUguid=in_OUguid 
         And ArriveDate <= in_Dutydate 
         And ifnull(LeaveDate,'9999-12-31') >= in_Dutydate);
 
  call p_tlog(in_ltPid,'delete from tduty_A');
 
  insert into tduty_a # 新增/修改 必需有 unique index (empguid,dutydate)
   (ltUser,ltpid
    ,empguid,dutydate,holiday,workguid,Std_on,Std_off,Range_on,Range_off,cardno,realOn,realOff,WorkA,WorkB,WorkC,RestA,RestB,RestC,CloseStatus_z07,delayBuffer,delayBuffer_Use,delayBuffer_Repay,WorkMins,error_code
    ,OverA,OverB,OverC,OverH,OverCh,OffMins,OffDesc)
   select in_ltUser,in_ltpid
   ,empguid,dutydate,holiday,workguid,Std_on,Std_off,Range_on,Range_off,cardno,realOn,realOff,WorkA,WorkB,WorkC,RestA,RestB,RestC,CloseStatus_z07,delayBuffer,delayBuffer_Use,delayBuffer_Repay,WorkMins,error_code
   ,OverA,OverB,OverC,OverH,OverCh,OffMins,OffDesc
   from tmp_tdutya a Where CloseStatus_Z07='0'
   On duplicate key Update  
    ltUser= in_ltUser
   ,ltpid=  in_ltpid
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
   ,OverA=a.OverA
   ,OverB=a.OverB
   ,OverC=a.OverC
   ,OverH=a.OverH
   ,OverCH=a.OverCH
   ,OffMins=a.OffMins
   ,OffDesc=a.OffDesc
   ;
 
  call p_tlog(in_ltPid,'insert tduty_A');

end if; # 90

if err_code=0 Then # 99 結束後執行
  set err_code=0;
  set outMsg=concat(in_Dutydate," p_tduty_A_save 結轉完成");
  set outRwid=0;
  call p_tlog(in_ltPid,'end');
end if; # 99

end # end Begin