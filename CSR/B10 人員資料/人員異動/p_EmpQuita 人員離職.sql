drop procedure if exists p_EmpQuit; # 人員離職

delimiter $$

create procedure p_EmpQuit
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/ 
,in_EmpID  varchar(36) #  
,in_QuitDate Varchar(36)
,in_type_A14 varchar(36) # 
,in_type_A15 varchar(36) # codedesc
,in_Reason text # 原因
,in_Black  int  # 黑名單、永不錄用
,in_BlackNote text /*永不錄用原因*/ 
,in_type_z09   varchar(36)   # 離職類別 離職或留停
,out outMsg text /*回傳訊息，直接給user看的*/
,out outRwid int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin
declare tlog_note text;
declare isCnt int;
declare in_old_date date;
declare in_old_z09 varchar(36);
declare in_A12_Guid varchar(36);
declare in_A13_Guid varchar(36);
declare in_A14_Guid varchar(36);
declare in_A15_Guid varchar(36);
declare in_A07_Guid varchar(36);
set err_code = 0;
/*
set tlog_note= concat("call p_EmpQuit(\n'"
,in_OUguid  ,"',\n'"
,in_ltUser  ,"',\n'"
,in_ltpid   ,"',\n'"
,in_EmpID   ,"',\n'"
,in_Quittype  ,"',\n'"
,in_date     ,"',\n'"
,in_Reason  ,"',\n'"
,in_Black   ,"',\n'"
,in_BlackNote ,"',\n" 
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");");
call p_tlog(in_ltPid,tlog_note);
*/
set outMsg='p_EmpQuit,人員離職程式開始';  

if err_code=0 Then # 10 抓該員工最後的生效日期
  set in_old_date=NULL; set in_old_z09='';
  Select Valid_Date,Type_z09 ,A12_Guid,A13_Guid,A14_Guid,A15_Guid,A07_Guid
  into in_old_date,in_old_z09 ,in_A12_Guid,in_A13_Guid ,in_A14_Guid,in_A15_Guid,in_A07_Guid
 # Select Valid_Date,Type_z09 into in_old_date,in_old_z09 
  from temp_hirelog
  Where empguid = (select empguid from tperson where ouguid=in_OUguid And empid=in_EmpID) 
  order by Valid_Date desc limit 1;
  if err_code=0 && substring(in_old_z09,1,1)='Q' Then set err_code=1; set outMsg='該員工離職狀態'; end if;
  if err_code=0 && in_old_date>in_QuitDate Then set err_code=1; set outMsg='日期小於最後一筆資料'; end if;
 
end if; # 10

if err_code=0 && 0 Then # 10 判斷該人員最後一筆人事異動，決定能不能做離職
  Select Rwid into isCnt from tEmp_hirelog 
  Where substring(Type_Z09,1,1)='Q' # Q開頭代表已經離職中
  And empguid = (select empguid from tperson where ouguid=in_OUguid And empid=in_EmpID)
  order by rwid desc limit 1;
  if isCnt>0 Then set err_code=1; set outMsg='(離職中)無法再做離職'; end if;
end if; # 10

if err_code=0 && 1 Then # 90
  insert into tEmp_hirelog 
  (ltUser,ltPid,empGuid,Valid_Date,type_z09,Note,A14_Guid,A15_Guid
  ,A12_Guid,A13_Guid,A07_Guid)
  Values
  (in_ltUser,in_ltPid,
  (Select Empguid from tperson where ouguid=in_OUguid And EmpID=in_EmpID),
  in_QuitDate,
  in_type_z09,
  in_Reason ,
  (Select CodeGuid from tCatCode Where Syscode='A14' And OUguid=in_OUguid And CodeID=in_type_A14), 
  (Select CodeGuid from tCatCode Where Syscode='A15' And OUguid=in_OUguid And CodeID=in_type_A15),
  in_A12_Guid,in_A13_Guid,in_A07_Guid
  );

  update tperson 
  set LeaveDate = in_QuitDate
  Where OUguid=in_OUguid And EmpID=in_EmpID;
  set outMsg='離職作業完成';
end if; # 90
 
end # Begin