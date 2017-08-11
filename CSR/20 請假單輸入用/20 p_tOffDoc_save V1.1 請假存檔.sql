drop procedure if exists p_tOffDoc_save;

delimiter $$

create procedure p_tOffDoc_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_EmpID  varchar(36)
,in_Type   varchar(36) 
,in_DateStart  varchar(36)  
,in_DateEnd    varchar(36)
,in_OffMins    int  
,in_Note text /*備註*/
,in_Rwid int  /*要修改的單據rwid*/
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt,in_QuotaCtrl,in_OffLeft_Mins int;
declare in_EmpGuid,in_CloseStatus_z07,in_offtype,in_offtypeguid varchar(36);
declare in_Close_date date;
declare in_DupList text;
DECLARE EXIT HANDLER FOR SQLEXCEPTION#, SQLWARNING
BEGIN
    ROLLBACK;
END;
/*
執行範例 
 call p_tOffDoc_save(
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
set err_code=0; set outRwid=0; set outMsg='p_tOffDoc_save 執行中';

if err_code=0 then # 10 轉換日期格式
 set in_DateStart= str_to_date(concat(f_removeX(in_DateStart)),'%Y%m%d%H%i');
 set in_DateEnd  = str_to_date(concat(f_removeX(  in_DateEnd)),'%Y%m%d%H%i');
 
end if; # 10 轉換日期格式

if err_code=0 Then # 15 判斷起迄
   if in_DateStart >= in_DateEnd Then set err_code=1; set outMsg="時間起迄，錯誤"; end if; 
end if; # 15 判斷起迄

if err_code=0 && in_Rwid>0 then # 20 
 set isCnt=0;
 Select rwid,Empguid,CloseStatus_z07 
   into isCnt,in_EmpGuid,in_CloseStatus_z07 from tOffdoc
 Where rwid=in_Rwid 
  And empguid in (select empguid from tperson where OUguid=in_OUguid);
 if isCnt=0 && err_code=0 then set err_code=1; set outMsg='無此資料'; end if;
 if in_CloseStatus_z07>0 then set err_code=1; set outMsg='此筆資料已關帳'; end if;
end if; # 20


if err_code=0 then # 30 判斷工號
  set isCnt=0; 
  Select rwid,empid,empguid 
  into isCnt ,in_EmpID,in_EmpGuid
  from tperson where ouguid=in_OUguid 
  and (Empid=in_EmpID or Empguid=in_EmpID 
       or Empguid=in_EmpGuid)  ; 
  set outMsg=concat(in_EmpID,' ',in_EmpGuid); 
  if isCnt=0 && err_code=0 then set err_code=1; set outMsg=concat('無此工號'); end if;
end if; # 30
 

if err_code=0 then # 40 判斷假別
  set isCnt=0;
  Select rwid ,codeid,codeguid
  into isCnt ,in_offtype,in_offtypeguid
  from tcatcode where ouguid=in_OUguid
  and syscode='A00'
  and (codeid=in_Type or codeguid=in_Type); 
  if isCnt=0 then set err_code=1; set outMsg='假別錯誤'; end if;
end if;

if err_code=0 Then # 50 判斷資料是否在 tOUset 關帳日之後
   select close_date into in_Close_date from touset where ouguid=in_OUguid;
   if date(in_DateStart) <= in_Close_date Then
      set err_code=1; set outMsg=concat("無法新增, 關帳日：",cast(in_Close_date as char)," 以前的資料");  end if; 
end if;  # 50

if err_code=0 && 1 then # 60 判斷假別是不是特補休類
 Select QuotaCtrl into in_QuotaCtrl from tofftype a
 Where a.offtypeguid=in_offtypeguid; 

if err_code=0 && in_QuotaCtrl=1 then # 60-1 計算剩餘時數
       set in_OffLeft_Mins=0;
       select ifnull(sum(Off_Mins_left),0) 
  into in_OffLeft_Mins # 計算請假當時，可用的特補休時數
       from voffquota_status
       Where 1=1
        And Off_Mins_left > 0 
        And OUguid  = in_OUguid
        And Empid   = in_EmpID
        And Offtype = in_offtype  
        And Quota_Valid_ST  < in_DateStart 
        And Quota_Valid_End > in_DateStart; 
 
  select in_OffLeft_Mins+ifnull(sum(OffDoc_Mins),0) # 修改時，要加回自身的請假時數，否則會一直出現不足
  into in_OffLeft_Mins from tOffquota_used
  where OffDocGuid=(select offdocguid from toffdoc where rwid=in_Rwid); 

  if err_code=0 && in_OffMins > in_OffLeft_Mins then # 60-2
   set err_code=1; set outMsg=concat('剩餘時數不足，剩餘：',round(in_OffLeft_Mins/60,2),' hr');
  end if; # 60-2
end if; # 60-1 計算剩餘時數

end if; # 60

if err_code=0 Then # 70 班別錯誤出現上班時間重疊
    set isCnt=0;
    set in_DupList='';
    select count(*),group_concat(a.dutydate order by 1) 
    into isCnt,in_DupList
    from vdutystd_emp a
     left join vdutystd_emp b on a.empguid=b.empguid 
      and a.dutydate != b.dutydate
      and b.dutydate between (a.dutydate- interval 1 day) And (a.dutydate+interval 1 day)  
    Where a.empguid = in_Empguid
      and a.std_On  < b.std_Off
      and a.std_Off > b.std_On
      and a.std_on  < in_DateEnd
      and a.std_Off > in_DateStart  ;
    if isCnt > 0 Then # A60-1 代表班別錯誤
       set err_code='1'; set outMsg=concat("班別錯誤，上班時間重疊，日期：",in_DupList);  end if; 

end if;# 70


if err_code=0 Then # 80 新增toffdoc 
 
 start transaction;
  if in_rwid=0 Then # 80-1 新增時
  Insert into tOffDoc
  (offdocguid,empguid,offtypeguid,offdoc_start,offdoc_end,offdoc_mins,Note,ltuser,ltpid)
  select 
  uuid(),in_EmpGuid,in_offtypeguid,in_DateStart,in_DateEnd,in_OffMins,in_Note,in_ltUser,in_ltpid; 
  set outRwid=LAST_INSERT_ID();
  end if; # 80-1 新增時

  if 1 && in_rwid>0 Then # 80-2 修改
     delete from tOffQuota_used 
     Where OffDocGuid=(select offDocGuid from tOffdoc where  rwid = in_Rwid);
    update toffdoc set
	 offtypeguid = in_offtypeguid
    ,offdoc_start= in_DateStart
    ,offdoc_end  = in_DateEnd
    ,offdoc_mins = in_OffMins
    ,Note        = in_Note
    ,ltuser      = in_ltUser
    ,ltpid       = in_ltpid
   Where closeStatus_z07='0' and rwid = in_Rwid;  
  set  outRwid=in_Rwid;
  end if; #  80-2 修改

 commit; # procedure 無法百分百有用
 
  call    p_toffdoc_duty_save(in_OUguid,in_ltUser,in_ltpid,outRwid); 
  call  p_toffquota_used_save(in_OUguid,in_ltUser,in_ltpid,outRwid);
 
 end if; # # 80 新增toffdoc  

 
end; # begin