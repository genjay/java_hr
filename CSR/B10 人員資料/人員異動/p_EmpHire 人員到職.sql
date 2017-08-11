drop procedure if exists p_EmpHire; # 人員到職

delimiter $$

create procedure p_EmpHire
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/ 
,in_EmpID  varchar(36) #  工號
,in_DepID  varchar(36)  # 部門代號
,in_type_A12  varchar(36) # 到職屬性
,in_type_A13  varchar(36) # 預留
,in_Valid_St  varchar(36) # 到職日
,in_Valid_End varchar(36) # 失效日，預設''
,in_Note text 
,in_type_z09  varchar(36) # 報到類型 A1 到職、A2 復職
,in_JobAges   int         # 期初年資(天)
,in_Title_name  varchar(36) 
,out outMsg text /*回傳訊息，直接給user看的*/
,out outRwid int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin
declare tlog_note text;
declare in_old_date date;
declare in_old_z09  varchar(36);
declare in_A12_Guid varchar(36);
declare in_A13_Guid varchar(36);
declare in_A14_Guid varchar(36);
declare in_A15_Guid varchar(36);
declare isCnt int;
set err_code = 0;


call p_tlog(in_ltPid,tlog_note);
set outMsg='p_EmpHire,人員到職程式開始'; 
set outRwid='0';

# 除錯時用 
set outMsg=in_EmpID;
set outMsg=in_DepID;
set outMsg=in_type_A12;
set outMsg=in_type_A13;
set outMsg=in_Valid_St;
set outMsg=in_Valid_End;
set outMsg=in_Note;
set outMsg=(in_Valid_St);
# 除錯時用 以上
if 1 && 0 then # 除錯用
set outMsg=in_type_A12;
set err_code=1;

end if;

if err_code=0 Then # 05 判斷 type_z09 是否有選擇 (-1) 代表未選擇
  if in_type_z09='-1' Then set err_code=1; set outMsg='到職類型未選擇'; end if;
end if;
if err_code=0 && in_Valid_End>'' Then
  if (in_Valid_St>=in_Valid_End) Then set err_code=1; set outMsg='失效日需大於到職日或空白'; end if;
end if;

if err_code=0 Then # 10 抓該員工最後的生效日期
  set in_old_date=NULL; set in_old_z09=''; set in_A14_Guid=''; set in_A15_Guid='';
  Select Valid_Date,Type_z09 ,A12_Guid,A13_Guid,A14_Guid,A15_Guid
  into in_old_date,in_old_z09 ,in_A12_Guid,in_A13_Guid ,in_A14_Guid,in_A15_Guid 
  from temp_hirelog
  Where empguid = (select empguid from tperson where ouguid=in_OUguid And empid=in_EmpID) 
  order by Valid_Date desc,Type_z09 desc limit 1;
  if err_code=0 && substring(in_old_z09,1,1)='A' Then set err_code=1; set outMsg='該員工已在職中'; end if;
  if err_code=0 && in_old_date>in_Valid_St Then set err_code=1; set outMsg='日期小於最後一筆資料'; end if;
  if err_code=0 && in_type_z09='A2' && in_type_z09!='Q2' # Q2 留停
   Then set err_code=1; set outMsg='最後狀態為留停，才能做復職'; end if;
end if; # 10 

if err_code=0 && 1 Then # 90
  insert into tEmp_hirelog 
  (ltUser,ltPid,empGuid,Valid_Date,type_z09,job_age_offset,A12_Guid,A13_Guid,A07_Guid
  ,A14_Guid,A15_Guid,Title_name)
  Values
  (in_ltUser,in_ltPid,
  (Select Empguid from tperson where ouguid=in_OUguid And EmpID=in_EmpID),
  in_Valid_St,
  in_type_z09,
  in_JobAges,
  (Select CodeGuid from tCatCode Where Syscode='A12' And OUguid=in_OUguid And CodeID=in_type_A12), 
  (Select CodeGuid from tCatCode Where Syscode='A13' And OUguid=in_OUguid And CodeID=in_type_A13), 
  (Select CodeGuid from tCatCode Where Syscode='A07' And OUguid=in_OUguid And CodeID=   in_DepID),
  in_A14_Guid,in_A15_Guid,in_Title_name
  );
  
  update tperson 
  set ArriveDate = in_Valid_St,Leavedate= NULL
  ,depGuid=(Select codeGuid from tcatcode Where syscode='A07' And OUguid=in_OUguid And codeID=in_DepID)
  ,Title_name=in_Title_name
  Where OUguid=in_OUguid And EmpID=in_EmpID;
  set outMsg='到職作業完成';
end if; # 90
 
end # Begin