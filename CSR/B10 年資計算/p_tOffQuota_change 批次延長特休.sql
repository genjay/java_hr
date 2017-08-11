drop procedure if exists p_tOffQuota_change;

delimiter $$

create procedure p_tOffQuota_change(
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36),
in_EmpX   text, # '' 代表該OU所有人,EmpID,EmpGuid 皆可
in_DepX   text, # '' 代表所有部門
in_type_A02 varchar(36), # 假別
in_year   varchar(36),   # 年度 2014，只能接 '',四位數字
in_Date1  varchar(36), # 日期起 (失效日用)
in_Date2  varchar(36), # 日期迄
in_DayMonth int,     # 日期(月)
in_Days  int ,       # 日期(天)
in_note  text ,
in_tmpTable varchar(36),    # temp table 名稱
out outMsg text,
out outRwid int,
out err_code int
)

begin
declare in_S1 text; 
declare in_WhereDate text;
set err_code=0;
set in_WhereDate="1=1 ";
set outMsg='p_tOffQuota_change 執行中';
 
if err_code=0 && in_year='' && in_date1='' && in_date2='' then
  set err_code=1; set outMsg='年度或日期範圍未輸入';
end if;

if err_code=0 && (in_year!='' && in_date1!='' && in_date2!='') then # 00-A 三個欄位都有輸入時
 set in_WhereDate=concat(' And Quota_year=',in_year ,' And date(Quota_Valid_End) Between ',in_date1,' And ',in_date2);
end if; # 00-A

if err_code=0 && (in_year!='' && in_date1='') then # 00-B只輸入year , 只輸入in_date2, 乎略他
 set in_WhereDate=concat(' And Quota_year=',in_year );
end if; # 00-B

if err_code=0 && (in_year='' && in_date1!='' && in_date2!='') then # 00-C 只輸入 year
 set in_WhereDate=concat(' And date(Quota_Valid_End) Between ',in_date1,' And ',in_date2);
end if; # 00-C

 if err_code=0 then #drop temp table 
  
  drop table if exists tmp00A;
  drop table if exists tmp00B;
  drop table if exists tmp_Emp;
end if;

if err_code=0 Then # 產生tmp00A
  create temporary table tmp00A as select empguid from tperson limit 0; 
end if;

if err_code=0 && in_EmpX != '' Then 
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

if err_code=0 && in_DepX != '' Then 
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

IF err_code=0 && in_EmpX = '' && in_DepX='' Then # 10 執行在職所有人員
   drop table if exists tmp_Emp;
   Create temporary table tmp_Emp As
   Select Empguid from tPerson Where OUguid=in_OUguid
    And ifnull(leavedate,'')='' ;
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

if err_code=0 && 1 Then

  drop table if exists tmp01;

  set @sql_f02d7659=concat( " create temporary table tmp01 as
  select a.empid,a.empname,a.Quota_year,a.offtype,a.offdesc,a.quota_offmins,a.off_mins_left,a.quota_valid_st,a.Quota_valid_end 
  ,a.Quota_valid_end changed
  ,c.codeid depid,c.codedesc depDesc
  ,a.quotadocguid
  from voffquota_status a 
  left join tperson b on b.empguid=a.empguid
  left join tcatcode c on b.depguid=c.codeguid
  Where 1=1 
  And a.offtype='",in_type_A02,"'
  And a.empguid in (select empguid from tmp_emp)",in_WhereDate);
  prepare s1 from @sql_f02d7659;
  execute s1;
  deallocate prepare s1; 
  insert into tmp_tOffQuota_change
  (docguid,Empid,Empname,depDesc,offtype,Quota_Offmins,left_Offmins,Valid_ST,Valid_End,final_End)
  select quotadocguid,Empid,Empname,concat(depid,depDesc) depdesc,offtype,quota_Offmins,Off_Mins_left,Quota_Valid_st,Quota_valid_End
  ,if(quota_valid_st>Quota_valid_End + interval in_DayMonth month + interval in_Days day
	 ,quota_valid_st,Quota_valid_End + interval in_DayMonth month + interval in_Days day)
  # 因為前端可以輸入負天(月)數，所以要防止調整後，小於起始日
  from tmp01;
end if;


end # begin 