drop procedure if exists p_tforgetdoc_save;

delimiter $$

create procedure p_tforgetdoc_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_EmpID  varchar(36)
,in_Type   varchar(36)
,in_Dutydate   varchar(36)
,in_DateStart  varchar(36)
,in_DateEnd    varchar(36)
,in_Note text /*備註*/
,in_Rwid int  /*要修改的單據rwid*/
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)

begin
declare isCnt int;
declare in_EmpGuid,in_CloseStatus_z07,in_TypeGuid varchar(36);
declare in_Close_date date;
declare DTime_St,DTime_End datetime;
DECLARE EXIT HANDLER FOR SQLEXCEPTION#, SQLWARNING
BEGIN
    ROLLBACK;
END;
set err_code=0;
/*
執行範例 
 call p_tforgetdoc_save(
'microjet' # ouguid
,'a00514'  # login user
,'ltpid'   # 程式代號
,'a00514'  # 人員id或guid
,'b' # 忘刷typeid或guid
,'20140601' # 出勤日
,'2014-06-01 18:00' # 刷卡起
,'2014-06-01 17:00' # 刷卡迄
,'text' # note
,'0' # 要修改單據的rwid
,@x
,@y
,@z);
select @x,@y,@z;

*/

if err_code=0 then # 10 日期轉換
  set in_Dutydate = str_to_date(concat(f_removeX(in_Dutydate)),'%Y%m%d');
  set in_DateStart= str_to_date(concat(f_removeX(in_DateStart)),'%Y%m%d%H%i');
  set in_DateEnd  = str_to_date(concat(f_removeX(  in_DateEnd)),'%Y%m%d%H%i');
set outMsg=concat(in_Dutydate,' ',in_DateStart,' ',in_DateEnd);
end if; # 10 日期轉換

if err_code=0 && in_DateStart>in_DateEnd then # 12 判斷起迄
  set err_code=1; set outMsg='時間起，不可大於迄';
end if; # 12
 
if err_code=0 then # 15 抓 in_EmpGuid
  set isCnt=0;
  Select rwid,Empguid into isCnt,in_EmpGuid from tperson 
  where ouguid=in_OUguid 
   and (empid=in_EmpID or empguid=in_EmpID 
      or empguid = (select empguid from tforgetdoc where rwid=in_Rwid));
  # 因前端修改時，in_EmpID傳空白，in_EmpID 傳 guid格式
  if isCnt=0 then set err_code=1; set outMsg='工號錯誤'; end if;
end if; # 15 

if err_code=0 then # 16 抓 in_TypeGuid
  set isCnt=0;
  Select rwid,codeguid into isCnt,in_TypeGuid from tcatcode
  where ouguid=in_OUguid and syscode='A04'
   And (codeid=in_Type or codeguid=in_Type);
  if isCnt=0 then set err_code=1; set outMsg='刷卡類別錯誤'; end if;
end if; 

if err_code=0 && in_Rwid > 0 Then # 20 in_Rwid 判斷，單據關帳、有無此單據
   Set isCnt = 0;
   Select rwid,CloseStatus_z07 
   into isCnt,in_CloseStatus_z07 from tforgetdoc 
    Where rwid=in_Rwid ;
   if err_code=0 And in_CloseStatus_z07 > '0'
      Then set err_code=1; set outMsg=concat("此單據，已關帳，無法修改，單據號：",in_Rwid); end if;
   if err_code=0 And isCnt=0 
      Then set err_code=1; set outMsg=concat("無此單據，單據號：",in_Rwid); end if; 
end if;

if err_code=0 Then # 30 判斷資料是否在 tOUset 關帳日之後
   select close_date into in_Close_date from touset where ouguid=in_OUguid;
   if in_Dutydate < in_Close_date Then # 30-1
      set err_code=1; set outMsg=concat("無法新增, 關帳日：",cast(in_Close_date as char)," 以前的資料"); 
   end if; # 30-1
end if;  # 30

if err_code=0 Then # 40 判斷是否存在其他相同出勤日單據
   set isCnt=0;
   Select rwid into isCnt From tforgetdoc 
   Where rwid!=in_Rwid And empguid=in_Empguid and dutydate=in_Dutydate limit 1;
   if isCnt > 0 Then set err_code=1; set outMsg=concat("已存在，其他單據，單據號：",isCnt); 
    set outRwid=isCnt; end if;
end if; # 40 

if err_code=0 Then # 50 判斷，時間是否重疊其它出勤日
  Select std_Off
  into DTime_St  # 前天下班 
  from vdutystd_emp
  where  empguid=in_Empguid  
   and dutydate = in_Dutydate - interval 1 day; 

  Select std_On
  into DTime_End  # 明天上班
  from vdutystd_emp
  where  empguid=in_Empguid  
   and dutydate = in_Dutydate + interval 1 day; 

  if err_code=0 && Not in_DateStart between DTime_St And DTime_End then
   set err_code=1; set outMsg='時間(起)，錯誤'; end if;
  if err_code=0 && Not   in_DateEnd between DTime_St And DTime_End then
   set err_code=1; set outMsg='時間(迄)，錯誤'; end if;
  
end if; # 50

if err_code=0 then # 90
  if in_Rwid=0 then # 90-1 新增
   insert into tforgetdoc
   (ltuser,ltpid,ForgetDocGuid,EmpGuid,Dutydate,ForgetOn,ForgetOff
    ,Note,ForgetTypeGuid)
   select 
   in_ltUser,in_ltpid,uuid(),in_EmpGuid,in_Dutydate,in_DateStart,in_DateEnd
    ,in_Note,in_TypeGuid;
  set outRwid=LAST_INSERT_ID();
  set outMsg=concat(outRwid,' 新增完成'); 
  end if; # 90-1 新增
 
  if in_Rwid>0 then # 90-2 修改
  update  tforgetdoc set
   ltuser=in_ltUser
  ,ltpid=in_ltPid
  ,dutydate=in_Dutydate
  ,forgetOn=in_DateStart
  ,forgetOff=in_DateEnd
  ,note=in_note
  ,forgetTypeguid=in_TypeGuid  
  Where rwid=in_Rwid ;
  set outRwid=in_Rwid;
  set outMsg=concat(in_Rwid,' 修改完成');
  end if; # 90-2 修改

end if; # 90


end;