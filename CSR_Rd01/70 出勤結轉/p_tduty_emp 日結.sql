drop procedure if exists p_tduty_emp;

delimiter $$ 

create procedure p_tduty_emp
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/ 
,in_Dutydate  date # 結轉日
,in_Data      text # 空白->全部， 初期只有全部結轉，後期適情況，加入處理範圍
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
/*
call p_tduty_emp
(
'**common**' #in_OUguid varchar(36)
,'' #,in_ltUser varchar(36)
,'' #,in_ltpid  varchar(36)  
,'20150201' #,in_Dutydate  date # 結轉日
,'' #,in_Data      text # 空白->全部， 初期只有全部結轉，後期適情況，加入處理範圍
,@a,@b,@c
)  ;
*/

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
  --  drop table if exists tmp01;
    set outMsg='sql error';
    set err_code=1;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tduty_emp 執行中';

if err_code=0 && in_Dutydate>sysdate() then set err_code=1; set outMsg='結轉日不可大於今天'; end if;

if err_code=0 then # 10 判斷是否關帳
 set isCnt=0;
 select Rwid into isCnt from tOUset Where OUguid=in_OUguid And Close_Date>=in_Dutydate;
 if isCnt>0 then set err_code=1; set outMsg='結轉日需大於關帳日'; end if;
end if;
 
if err_code=0 then # 20 取得在職人員相關資訊
drop table if exists tmp01;
CREATE TABLE tmp01 (
  emp_rwid bigint unsigned NOT NULL DEFAULT '0',
  cardno  varchar(36),
  CalDate date,
  holiday int(4) DEFAULT NULL,
  worktype_ID varchar(36),
  std_ON    datetime DEFAULT NULL,
  std_OFF   datetime DEFAULT NULL,
  range_ON  datetime DEFAULT NULL,
  range_OFF datetime DEFAULT NULL,
  realOn    datetime,
  realOff   datetime,
  work_A    int default 0,
  work_B    int default 0,
  work_C    int default 0,
  restA int default 0,restB int default 0,restC int default 0
  ,BeforeBuffer int default 0,DelayBuffer int default 0
  ,in_Early int default 0,in_Delay int default 0
) ENGINE=myisam DEFAULT CHARSET=utf8;

insert into tmp01
(emp_rwid,cardno,caldate,holiday,worktype_id,std_ON,std_OFF
,range_ON,range_Off)
Select a.rwid emp_rwid,a.cardno,b.caldate,b.holiday,b.worktype_id,b.std_ON,b.std_OFF
,b.range_ON,b.range_Off
from tperson A
left join vtsch_emp b on a.OUguid=b.OUguid and a.emp_id=b.emp_id
where a.OUguid=in_OUguid
 and /*已到職*/a.arrivedate <= in_dutydate 
 And /*未離職*/(ifnull(a.leavedate,'99991231') >= in_dutydate)
 and b.caldate=in_dutydate
 and /*排除已關帳的，加快執行時間*/
  not exists (select * from tduty_emp x where a.emp_guid=x.emp_guid
  and b.caldate=in_dutydate
  and x.CloseStatus>0 );
end if; # 

if err_code=0 then # 抓上下班時間，請忽略秒數
update tmp01 a,tworktype b # 抓班別的設定
set
 a.BeforeBuffer=b.BeforeBuffer
,a.DelayBuffer=b.DelayBuffer
Where b.OUguid=in_OUguid
  and a.worktype_id=b.worktype_id;

update tmp01 a # 抓上下班時間
set realOn=(select substring(min(dtcardtime),1,16) from tcardtime b
 where b.OUguid=in_OUguid
  and b.cardno=a.cardno
  and b.dtcardtime between range_on and Range_off)
,realOff=(select substring(max(dtcardtime),1,16) from tcardtime b
 where b.OUguid=in_OUguid
  and b.cardno=a.cardno
  and b.dtcardtime between range_on and Range_off)
,in_early=Case 
 When a.realOn is null then 0
 When a.realOn between a.std_on -interval beforebuffer minute and a.std_on  
 then floor(f_timediff(a.realon,a.std_on)/60) 
 else if(a.realOn>a.std_on,0,beforebuffer)
 end 
,in_Delay= 
 Case
 When a.realOn is null then 0
 When a.realOn between a.std_on and (a.std_on+interval DelayBuffer minute)
 then floor(f_timediff(a.realon,a.std_on)/60) 
 else if(a.realOn>(a.std_on+interval DelayBuffer minute),DelayBuffer,0)
 end 
where 1=1;
 
end if;

if err_code=0 then # 20 用tmp01產生上班前中後，起迄時間
 drop table if exists tmp02;
 create table tmp02 (
  emp_rwid int,
  caldate date,
  holiday tinyint,
  worktype_ID varchar(36),
  wType varchar(36),
  dTimeFr datetime,
  dTimeTo datetime) engine=Myisam ;
 insert into tmp02 (emp_rwid,caldate,holiday,worktype_id,wType,dTimeFr,dTimeTo)
 select 
 a.emp_rwid,caldate,holiday,worktype_id,'workA' wType,
 if(realOn>std_On,std_On,realOn),
 if(realOff>std_On,std_On,realOff) 
 from tmp01 a;
 insert into tmp02 (emp_rwid,caldate,holiday,worktype_id,wType,dTimeFr,dTimeTo)
 select 
 a.emp_rwid,caldate,holiday,worktype_id,'workB' wType,
 if(realOn<std_On,std_On,if(realOn>std_off,std_off,realOn)),
 if(realOff>std_Off,std_Off,realOff) 
 from tmp01 a;
 insert into tmp02 (emp_rwid,caldate,holiday,worktype_id,wType,dTimeFr,dTimeTo)
 select 
 a.emp_rwid,caldate,holiday,worktype_id,'workC' wType,
 if(realOn<std_Off,std_Off,realOn),
 if(realOff<std_Off,std_Off,realOff) 
 from tmp01 a;

drop table if exists tmp02_xx;
create table tmp02_xx engine=myisam
select emp_rwid
,floor(sum(if(wtype='workA',f_timediff(dtimeto,dtimefr),0))/60) workA
,floor(sum(if(wtype='workB',f_timediff(dtimeto,dtimefr),0))/60) workB
,floor(sum(if(wtype='workC',f_timediff(dtimeto,dtimefr),0))/60) workC
from tmp02 
group by emp_rwid;

 update tmp01 a,tmp02_xx b set
  work_A=workA
, work_B=workB
, work_C=workC
 where a.emp_rwid=b.emp_rwid;

drop table if exists tmp02_xx;

end if; # 20

if err_code=0 then # 21 產生休息時刻表 
 drop table if exists tmpXX;
 create table tmpXX (a_date date) engine=myisam;
 insert into tmpXX (a_date) values 
 (in_Dutydate + interval -1 day),
 (in_Dutydate + interval +0 day),
 (in_Dutydate + interval +1 day),
 (in_Dutydate + interval +2 day); 

drop table if exists tmp03;
create table tmp03 
select 
str_to_date(concat(b.a_date,' ',a.rest_stHHMM),'%Y-%m-%d %H:%i:%s') rest_ST,
str_to_date(concat(b.a_date,' ',a.rest_stHHMM),'%Y-%m-%d %H:%i:%s')
+interval rest_time minute rest_To,
c.worktype_id,b.a_date,a.holiday,a.rest_stHHMM,a.rest_time,a.cuttime
,c.BeforeBuffer,c.DelayBuffer
from tworktype_rest a
left join tmpXX b on 1=1
left join tworktype c on a.Worktype_Guid=c.Worktype_Guid  
Where OUguid=in_OUguid;

-- drop table if exists tmpXX;
 
end if; # 21

if err_code=0 then # 22 tmp04 計算使用休息時間
drop table if exists tmp04_xx;
create table tmp04_xx engine=myisam
select a.emp_rwid,caldate,a.worktype_id,wType,a.holiday,
 if(dTimeFr<rest_ST,rest_ST,dTimeFr) use_Fr
,if(dTimeTo>rest_To,rest_To,dTimeTo) use_To
,floor(
f_timediff(
 if(dTimeFr<rest_ST,rest_ST,dTimeFr)
,if(dTimeTo>rest_To,rest_To,dTimeTo))/60) rest_Mins
from tmp02 a
left join tmp03 b on a.worktype_id=b.worktype_id and a.holiday=b.holiday
where dTimeFr < rest_To 
  and dTimeTo > rest_ST;

drop table if exists tmp04;
create table tmp04 engine=myisam
select emp_rwid 
,sum(if(wType='workA',abs(rest_Mins),0)) restA
,sum(if(wType='workB',abs(rest_Mins),0)) restB
,sum(if(wType='workC',abs(rest_Mins),0)) restC
from tmp04_xx
group by emp_rwid;

drop table if exists tmp04_xx;

 update tmp01 a,tmp04 b set
  a.restA=b.restA
, a.restB=b.restB
, a.restC=b.restC
 where a.emp_rwid=b.emp_rwid;

end if; # 22


if err_code=0 then # 30 加班結轉
 set @xfjkls=1;
end if; # 30 加班結轉 




end; # begin