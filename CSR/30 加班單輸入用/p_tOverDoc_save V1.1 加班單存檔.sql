drop procedure if exists p_tOverDoc_save; # 加班單存檔

delimiter $$

create procedure p_tOverDoc_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36)  
,in_EmpID  varchar(36)
,in_Type   varchar(36)
,in_Dutydate   varchar(36)
,in_DateStart  varchar(36)
,in_DateEnd    varchar(36)
,in_OverBefore  int
,in_OverHoliday int
,in_OverAfter   int 
,in_Note text /*備註*/
,in_Rwid int  /*要修改的假單rwid*/
-- ,in_NoApply int # 0 存檔/ 1 代表 不申請
,out outMsg text /*回傳訊息，直接給user看的*/
,out outRwid int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin
declare tlog_note text; 
declare isCnt int;  
declare in_Empguid varchar(36);
declare in_OvertypeGuid varchar(36);
declare in_Close_Date date;
declare in_offdocguid varchar(36);
declare in_LastID int;
declare tmpXX text;
declare in_CloseStatus int;
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
END;
set err_code=0;

set tlog_note= concat("call p_tOverDoc_save(\n'"
,in_OUguid         ,"',\n'"
,in_ltUser         ,"',\n'"
,in_ltpid          ,"',\n'"  
,in_EmpID          ,"',\n'"  
,in_Type           ,"',\n'"  
,in_Dutydate       ,"',\n'"  
,in_DateStart      ,"',\n'"  
,in_DateEnd        ,"',\n'"  
,in_OverBefore     ,"',\n'"  
,in_OverHoliday    ,"',\n'"  
,in_OverAfter      ,"',\n'"  
,in_Note           ,"',\n'"  
,in_Rwid           ,"',\n" 
,'@a'              ,","
,'@b'              ,","
,'@c' 
,");");

call p_tlog(in_rwid,tlog_note);
call p_SysSet(1);

if err_code=0 Then # 10 
  set outMsg='時間(起)，轉換及判斷';
  set tmpXX=f_DtimeCheck(f_removeX(in_DateStart));
  if tmpXX !='OK' Then set err_code=1; set outMsg=concat("時間(起) ",tmpXX); 
   Else set in_DateStart=str_to_date(concat(f_removeX(in_DateStart)),'%Y%m%d%H%i');
  end if;
end if; # 10  
if err_code=0 Then # 10-2  
  set outMsg='時間(迄)，轉換及判斷';
  set tmpXX = f_DtimeCheck(f_removeX(in_DateEnd));
  if tmpXX !='OK' Then set err_code=1;  set outMsg=concat("時間(迄) ",tmpXX);
   Else set in_DateEnd=str_to_date(concat(f_removeX(in_DateEnd)),'%Y%m%d%H%i');
 end if;
end if; # 10-2
if err_code=0 Then # 10-3
  set outMsg='出勤日，轉換及判斷';
  set tmpXX = f_DtimeCheck(f_removeX(concat(in_Dutydate,'0000'))); 
  if tmpXX !='OK' Then set err_code=1;  set outMsg=concat("出勤日  ",tmpXX); 
   Else set in_Dutydate=str_to_date(concat(f_removeX(in_Dutydate)),'%Y%m%d');
  end if; 
end if; # 10-3 
if err_code=0 Then # 10-4
  if in_DateStart>in_DateEnd Then set err_code=1; set outMsg='加班起迄錯誤'; end if;
end if; # 10-4
if err_code=0 Then # 11 
  set isCnt=0;
  Select rwid,empguid into isCnt,in_Empguid from tperson Where OUguid=in_OUguid And (Empguid=in_EmpID or EmpID=in_EmpID or Empguid =(Select Empguid from tOverdoc Where rwid=in_Rwid));
  if isCnt=0 Then set err_code=1; set outMsg='無此人'; end if;
end if; # 11

if err_code=0 Then # 12
  set in_OvertypeGuid=''; set outMsg='加班類別判斷';
  Select CodeGuid into in_OvertypeGuid from tCatcode Where Syscode='A02' And OUguid=in_OUguid And (CodeID=in_type or CodeGuid=in_type);
  if in_OvertypeGuid='' Then set err_code=1; set outMsg='加班類別錯誤'; end if;
end if; # 12

if err_code=0 Then # 20 判斷是否有其他加班單
  set isCnt=0; set outMsg='判斷是否有其他加班單';
   SELECT rwid into isCnt FROM toverdoc 
   Where empGuid = in_EmpGuid
    and overStart < in_DateEnd
    and overEnd   > in_DateStart and Rwid!=in_Rwid limit 1;
   if isCnt > 0 Then set err_code=1; set outMsg=concat("已存在其他加班單,單號",isCnt); set outRwid=isCnt; end if;
end if; # 20 判斷是否有其他加班單

if err_code=0 Then # 30 判斷 tOUset 關帳沒
  set outMsg='30 判斷 tOUset 關帳沒';
   select close_date into in_Close_Date from tOUset where ouguid=in_OUguid;
   if in_Dutydate < in_Close_Date Then 
     set err_code=1; 
     set outMsg=concat("無法新增，輸入資料在關帳日之前",cast(in_Close_date as char),"之前"); 
   end if;
end if; # 30 判斷 tOUset 關帳沒

if err_code=0 Then # 40 判斷單據關帳沒
   set isCnt=0; set outMsg='40 判斷單據關帳沒';
   select rwid into isCnt from tOverdoc where closeStatus_z07>0 and rwid=in_Rwid;
   IF isCnt>0 Then set err_code=1; set outMsg=concat("此單據已關帳，不能修改 單據：",in_Rwid);  end if;
end if; # 40 判斷單據關帳沒

if err_code=0 then # 50 檢查該加班單是否已經使用補休
   set  isCnt = 0; set outMsg='50 檢查該加班單是否已經使用補休';
   Select offdocguid,rwid into  in_offdocguid,isCnt from tOffQuota_used
   Where QuotaDocGuid in (select OverDocGuid from tOverDoc Where rwid=in_Rwid) limit 1;

   if isCnt > 0 Then 
    Select rwid into isCnt from tOffdoc where offdocguid=in_offdocguid;
    set err_code=1; set outMsg=concat("此單據已使用補休，不能修改 請假單據：",isCnt); end if;
 
end if;

if err_code=0 then # 60 檢查同一日，不能使用二種以上加班類型
  set isCnt=0;
  Select rwid into isCnt from tOverdoc 
  where Empguid=in_Empguid And dutydate = in_Dutydate
   And Overtypeguid <> in_Overtypeguid limit 1;
  if isCnt>0 then set err_code=1; set outMsg=concat('同一日不能使用二種加班類型,單號：',isCnt); end if;
end if; # 60

 if err_code=0 And in_rwid = 0 then # 90 新增模式

start transaction; # 新增的 commit
  set outMsg='新增中';
  insert into toverdoc
  (ltUser,ltpid,overdocguid,empguid,dutydate,overtypeguid
   ,overStart,overEnd,overMins_before,overMins_after,overMins_holiday,note)
  values
  (in_ltUser,in_ltpid,uuid(),in_empguid,in_dutydate,in_OvertypeGuid
   ,in_DateStart,in_DateEnd,in_OverBefore,in_OverAfter,in_OverHoliday,in_Note);
  
  set in_LastID = LAST_INSERT_ID();
  set outMsg= concat("新增完成 單號：",in_LastID);

  update tOverDoc A,tOvertype B
  set 
  a.Offtypeguid=b.offtypeguid
  ,a.Valid_time=b.Valid_time
  ,a.Valid_Type_Z08=b.Valid_Type_Z08
  ,a.OverToOff_Rate=b.OverToOff_Rate
  Where a.overtypeguid=b.overtypeguid and a.rwid= in_LastID; 

  insert into tOffQuota
  (QuotaDocGuid,EmpGuid,Quota_Year,OffTypeGuid,Quota_seq,Quota_OffMins,Quota_Valid_ST,Quota_Valid_End,isOverDoc)
  Select OverDocGuid,EmpGuid,year(overStart),offtypeguid,0,(OverMins_Before+OverMins_After+OverMins_Holiday)*OverToOff_Rate quota_offmins
  ,OverEnd
  ,Case 
   When Valid_type_z08='m' Then OverEnd + interval ifnull(Valid_time,0) month
   When Valid_type_z08='d' Then OverEnd + interval ifnull(Valid_time,0) day
   When Valid_type_z08='y' Then OverEnd + interval ifnull(Valid_time,0) year
   end Valid_End
  ,b'1' isOverdoc 
  from tOverdoc a
  where IFNULL(a.offtypeguid,'')!='' And rwid=in_LastID;
 end if; # 90 新增模式

commit;  # 新增的 commit

if err_code=0 And in_rwid > 0 Then # 90 修改模式

start transaction; # 修改的 commit
  delete from tOffQuota Where QuotaDocguid in (select OverdocGuid from tOverdoc Where rwid=in_Rwid);
  
  update toverdoc set
   ltUser=in_ltUser
  ,ltPid=in_ltPid
  ,dutydate=in_Dutydate
  ,overTypeGuid=in_OvertypeGuid
  ,overStart=in_DateStart
  ,overEnd=in_DateEnd
  ,overMins_before=in_OverBefore
  ,overMins_After=in_OverAfter
  ,overMins_holiday=in_OverHoliday
  ,note=in_note
  Where closestatus_z07='0' And rwid=in_rwid;
 
  update tOverDoc A,tOvertype B
  set 
   a.Offtypeguid=b.offtypeguid
  ,a.Valid_time=b.Valid_time
  ,a.Valid_Type_Z08=b.Valid_Type_Z08
  ,a.OverToOff_Rate=b.OverToOff_Rate
  Where a.overtypeguid=b.overtypeguid and a.rwid= in_rwid;

  set in_LastID = in_rwid;
  set outMsg= concat("修改完成 單號：",in_rwid);
  insert into tOffQuota
  (QuotaDocGuid,EmpGuid,Quota_Year,OffTypeGuid,Quota_seq,Quota_OffMins,Quota_Valid_ST,Quota_Valid_End,isOverDoc)
  Select OverDocGuid,EmpGuid,year(overStart),offtypeguid,0,(OverMins_Before+OverMins_After+OverMins_Holiday)*OverToOff_Rate quota_offmins
  ,OverEnd
  ,Case 
   When Valid_type_z08='m' Then OverEnd + interval ifnull(Valid_time,0) month
   When Valid_type_z08='d' Then OverEnd + interval ifnull(Valid_time,0) day
   When Valid_type_z08='y' Then OverEnd + interval ifnull(Valid_time,0) year
   end Valid_End
  ,b'1' isOverdoc 
  from tOverdoc a
  where IFNULL(a.offtypeguid,'')!='' And rwid=in_LastID; 

commit; # 修改的 commit
end if;  # 90 修改模式

/* 改由前端處理
if err_code=0 && in_NoApply=1 then # 100 使用者不申請
  Update tOverDoc Set  
   overMins_before=0
  ,overMins_After=0
  ,overMins_holiday=0
  ,note=concat(in_note,'(不申報)')
  Where rwid=in_rwid;
end if; # 100
*/
 
end; # begin



