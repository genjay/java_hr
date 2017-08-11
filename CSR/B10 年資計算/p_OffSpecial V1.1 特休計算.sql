drop procedure if exists p_OffSpecial;

delimiter $$

create procedure p_OffSpecial(
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36),
in_EmpX   text, # '' 代表該OU所有人,EmpID,EmpGuid 皆可
in_DepX   text, # '' 代表所有部門
in_year   year,        # 年度 2014
in_Base_Date date,     # 結算日 20131231
in_note text ,
out outMsg text,
out outRwid int,
out err_code int
)

begin
# 年資計算，只能計算在職人員，不考慮時間順序
/* 
call p_OffSpecial(
'microjet',
'ltUser',
'ltPid',
' ' , # '' 代表該OU所有人,EmpID,EmpGuid 皆可
2014,
20140531,
'' , #Note
@a,@b,@c
);

*/
declare tlog_note text;
declare isCnt int;
declare tmpXX1 text;
declare droptable int default 0; # 1 drop temptable /0 不drop 除錯用
declare in_OffTypeGuid varchar(36);
declare in_Hours_per_Day int;
declare in_seq int default 0;
declare in_Quota_Valid_ST date;
declare in_Quota_Valid_End date; 
declare in_S1 text; 
set err_code = 0;
set tlog_note= concat("call p_OffSpecial(\n'"
,in_OUguid  ,"',\n'"
,in_ltUser  ,"',\n'"
,in_ltpid   ,"',\n'"
,ifnull(in_EmpX,'')    ,"',\n'"
,in_DepX               ,"',\n'"
,ifnull(in_year,'')    ,"',\n'"
,ifnull(in_Base_Date,'') ,"',\n'" 
,ifnull(in_note,'') ,"',\n" 
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");");
call p_tlog(in_ltPid,tlog_note);
call p_SysSet(1);
set outMsg='p_OffSpecial,開始';

if err_code=0 then #drop temp table 
  
  drop table if exists tmp00A;
  drop table if exists tmp00B;
  drop table if exists tmp_Emp;
end if;

if err_code=0 Then # 產生tmp00A
  create temporary table tmp00A as select empguid from tperson limit 0; 
end if;

if in_EmpX != '' Then 
  set in_S1=concat('\'',replace(in_EmpX,',','\',\''));
  set in_S1=substring(in_S1,1,length(in_S1)-2);   
  set @sql_f02d7659a=concat("Insert into tmp00A (empguid) 
  select empguid from tperson 
  where OUguid='",in_OUguid,"'"
  ," And ifnull(leavedate,'')='' 
  And empid in (",in_S1,");");
  prepare s1 from @sql_f02d7659a;
  execute s1;
  deallocate prepare s1;
END IF; # 10 

if in_DepX != '' Then 
  set in_S1=concat('\'',replace(in_DepX,',','\',\''));
  set in_S1=substring(in_S1,1,length(in_S1)-2);   
  set @sql_f02d7659=concat("Insert into tmp00A (empguid)
  select codeguid from tCatcode 
  where Syscode='A07' And OUguid='",in_OUguid,"'"
  ," And codeid in (",in_S1,");");
  prepare s1 from @sql_f02d7659;
  execute s1;
  deallocate prepare s1;
END IF; # 10  

IF in_EmpX = '' && in_DepX='' Then # 10 執行在職所有人員
   drop table if exists tmp_Emp;
   Create temporary table tmp_Emp As
   Select Empguid from tPerson Where OUguid=in_OUguid
    And ifnull(leavedate,'')='';
   alter table tmp_Emp add index i01 (empguid);
Else 
  drop table if exists tmp_Emp;
  Create temporary table tmp_Emp As
   Select Empguid from tPerson Where OUguid=in_OUguid
    And ifnull(leavedate,'')='' 
    And (
	     empguid in (select empguid from tmp00a)
	  or depguid in (select empguid from tmp00a));
   alter table tmp_Emp add index i01 (empguid);
end if;

if err_code=0 Then # 25 抓基準日前的最新的到職資料，主要處理離職，又到職狀況
  drop table if exists tmp00;
  create temporary table tmp00 as 
  Select empguid,max(Valid_date) ArriveDate from temp_hirelog 
  where type_z09='A1' and Valid_date <= in_Base_Date
  and empguid in (select empguid from tmp_Emp)
  group by empguid;
  alter table tmp00 add index i01(empguid);
end if;

if err_code=0 then # 30 計算及產生tmp table
  drop table if exists tmp01;
  create temporary table tmp01 as
  select 
  a.empguid,in_Base_Date BaseDate,a.Valid_date,Job_age_offset,
  Case 
   When substring(Type_z09,1,1)='A' Then '+1' # 到職類
   When substring(Type_z09,1,1)='Q' Then '-1' # 離職類
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

end if; # 30

if err_code=0 Then # 35 取得相關資料
  Select OffSpecial_Guid,Hours_per_Day Into in_OffTypeGuid,in_Hours_per_Day # 取得該OU，特休的guid
  from tOUset
  Where OUguid=in_OUguid;
 
end if; # 35

if err_code=0 Then # 40 計算特休天數
  drop table if exists tmp02X;
  create temporary table tmp02X As 
  select a.empguid,max(offdays) OffDays
  from tmp02 a
  left join toff_special b on b.OUguid=in_OUguid
  Where 1=1     
  And JobAges > b.JobAges_m*30 
  group by a.empguid;
  alter table tmp02X add unique index u01(empguid);
  drop table if exists tmp03;
  create temporary table tmp03 as
  Select a.empguid,a.OffDays
  ,in_year Quota_Year,0 Quota_seq
  ,in_OffTypeGuid in_OffTypeGuid
  ,concat(in_year,'0101') Year_St
  ,concat(in_year,'1231') Year_End
  ,arrivedate +interval floor(c.JobAges/365) year Arrive_St # 到職日計算
  From tmp02X a 
  left join tperson b on a.empguid=b.empguid
  left join tmp02 c on a.empguid=c.empguid;
  alter table tmp03 add index i01 (empguid);

end if; # 40

  if droptable='1' Then # 30-1 drop temp table 
   drop table if exists tmp01;
   drop table if exists tmp02;
   drop table if exists tmp02X;
  end if; # 30-1
 

if err_code=0  Then # 90 新增修改 
   insert into tOffQuota(
     ltUser,ltpid,QuotaDocGuid
    ,EmpGuid,Quota_Year,OffTypeGuid,Quota_seq,Quota_OffMins,Quota_Valid_ST,Quota_Valid_End,Note) 
   select 
    in_ltUser,in_ltpid,uuid()
   ,a.empguid,in_year,in_OffTypeGuid,in_Seq,OffDays*in_Hours_per_Day*60
   ,Year_St
   ,Year_End,in_note
   from tmp03 a 
   where Not exists (select * from tOffQuota b Where a.empguid=b.empguid 
    And b.Quota_Year= a.Quota_Year
    And b.Quota_seq = a.Quota_seq
    And b.offtypeguid=in_OfftypeGuid); 

  update tOffQuota a,tmp03 b set
       ltUser = in_ltUser
	  ,ltpid  = in_ltpid
      ,Quota_OffMins=OffDays*in_Hours_per_Day*60
      ,Quota_Valid_ST=Year_St
      ,Quota_Valid_End=Year_End 
      ,Note=in_note
  where a.empguid=b.empguid 
  and a.Quota_Year= b.Quota_Year
  and a.offtypeguid=in_offtypeguid
  and a.quota_seq=b.quota_seq; 
end if;
 
if err_code=0 && droptable='1' Then # 99 清除temp table
   drop table if exists tmp00a;
   drop table if exists tmp_emp;
   drop table if exists tmp00;  
   drop table if exists tmp01;
   drop table if exists tmp02;
   drop table if exists tmp02X;
   drop table if exists tmp03; 
end if; # 99

end; # Begin