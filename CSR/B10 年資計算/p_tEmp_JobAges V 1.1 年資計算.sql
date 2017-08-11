drop procedure if exists p_temp_JobAges;

delimiter $$

create procedure p_temp_JobAges(
in_OUguid    varchar(36),
in_LtUser    varchar(36),
in_ltPid     varchar(36),
in_Base_Date varchar(36),
in_note      text,
out outMsg   text,
out outRwid  int,
out err_code int
)

begin
/*

call p_temp_JobAges(
 'microjet',
 'ltUser',
 'ltPid',
 '20140513',
 '',
 @a,@b,@c);

SELECT * FROM vtemp_jobages 
where empid='a00514';
*/
declare tlog_note text;
declare isCnt int;
declare tmpXX1 text;
declare droptable int default 1; # 1 drop temptable /0 不drop 除錯用
set err_code = 0;
set tlog_note= concat("call p_temp_JobAges(\n'"
,in_OUguid  ,"',\n'"
,in_ltUser  ,"',\n'"
,in_ltpid   ,"',\n'"  
,in_Base_Date ,"',\n'"  
,in_note ,"',\n" 
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");");
call p_tlog(in_ltPid,tlog_note);
set outMsg='p_temp_JobAges,開始';

if err_code=0 Then # 10 判斷日期格式
set tmpXX1 = f_DtimeCheck(concat(left(f_removeX(in_Base_Date),8),'0000')); 
if  tmpXX1 !='OK' Then set err_code=1; set outMsg=concat(tmpXX1); end if;
end if; # 10

if err_code=0 Then # 20 轉換日期格式
 set in_Base_Date=str_to_date(f_removeX(in_Base_Date),'%Y%m%d'); 
 set outMsg=in_Base_Date;
end if; # 20

if err_code=0 Then # 25 抓基準日前的最新的到職資料，主要處理離職，又到職狀況
  drop table if exists tmp00;
  create temporary table tmp00 as 
  Select empguid,max(Valid_date) ArriveDate from temp_hirelog 
  where type_z09='A' and Valid_date <= in_Base_Date
  and empguid in (select empguid from tperson where ouguid=in_OUguid)
  group by empguid;
  alter table tmp00 add index i01(empguid);
end if;

if err_code=0 then # 30 計算及產生tmp table
  drop table if exists tmp01;
  create temporary table tmp01 as
  select 
  a.empguid,in_Base_Date BaseDate,a.Valid_date,Job_age_offset,
  Case 
   When Type_z09='A' Then '+1' #到職
   When Type_z09='B' Then '-1' #離職
   When Type_z09='C' Then '-1' #留停
   When Type_z09='D' Then '+1' #復職
   else '+0' 
  end  Cal_A   
  from temp_hirelog a
  inner join tmp00 b on a.empguid=b.empguid 
  Where 1=1
  And a.Valid_date >= b.ArriveDate # 抓到職日後 
  And a.Valid_date <= in_Base_Date # 基準日之前
  And a.empguid in (select empguid from tperson where ouguid=in_OUguid)
  ;
  alter table tmp01 add index i01 (empguid);

  drop table if exists tmp02;
  create temporary table tmp02 as 
  Select a.empguid 
  ,sum(datediff(BaseDate,Valid_date)*cal_A+Job_age_offset)+1 JobAges
  from tmp01 a
  Group by empguid;
  alter table tmp02 add index i01(empguid);

  insert into tEmp_JobAges
  (ltPid,ltUser,empguid,Base_date,Job_Ages_d) 
  select in_ltPid,in_ltUser,empguid,in_Base_Date,JobAges 
  from tmp02 a
  on duplicate key update 
   Base_date=in_Base_Date
  ,Job_Ages_d=a.JobAges;
  set outMsg='年資計算完成';set outRwid=0;

  if droptable='1' Then # 30-1 drop temp table 
   drop table if exists tmp01;
   drop table if exists tmp02;
  end if; # 30-1

end if; # 30

end; # Begin