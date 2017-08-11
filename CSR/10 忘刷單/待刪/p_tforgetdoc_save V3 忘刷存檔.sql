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
,out outError int  # err_code
)

begin
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

DECLARE err_code int default '0'; 
DECLARE droptable int default '0'; # 0 代表測試中 1，正常使用

set @in_OUguid = IFNULL(in_OUguid,'');
set @in_ltUser = IFNULL(in_ltUser,'');
set @in_ltpid  = IFNULL(in_ltpid,'');
set @in_Type   = IFNULL(in_Type,'');
set @in_EmpID  = IFNULL(in_EmpID,'');
set @in_Rwid   = IFNULL(in_Rwid,'0');
set @in_Note   = IFNULL(in_Note,'');
set @outRwid   = 0;
set @outMsg    =''; 

if err_code=0 Then # A 日期(起)判斷
  set @xx1 = f_DtimeCheck(f_removeX(in_DateStart));
  if @xx1 !='OK' Then set err_code=1; set @outMsg=concat("時間(起) ",@xx1); end if;
  if err_code=0 Then set @in_DateStart= str_to_date(concat(f_removeX(in_DateStart)),'%Y%m%d%H%i'); end if;
  if droptable=0 Then insert into t_log(ltpid,note) values ('p_tforgetdoc_save','日期(起)判斷'); end if;
end if; # A 
 
if err_code=0 Then # B 日期(迄)判斷
   set @xx2 = f_DtimeCheck(f_removeX(in_DateEnd));
   if @xx2 !='OK' Then set err_code=1;  set @outMsg=concat("時間(迄) ",@xx2); end if;
   if err_code=0 Then set @in_DateEnd  = str_to_date(concat(f_removeX(  in_DateEnd)),'%Y%m%d%H%i'); end if;
   if droptable=0 Then insert into t_log(ltpid,note) values ('p_tforgetdoc_save','日期(迄)判斷'); end if;
end if; # B 

if err_code=0 Then # B-1 判斷起迄
   if in_DateStart > in_DateEnd Then set err_code=1; set @outMsg="時間起迄，錯誤"; end if;
end if;

if err_code=0 Then  # C 出勤日判斷
   set @xx3 = f_DtimeCheck(f_removeX(concat(in_Dutydate,'0000'))); 
   if @xx3 !='OK' Then set err_code=1;  set @outMsg=concat("出勤日  ",@xx3); end if; 
   if err_code=0 Then set @in_Dutydate = str_to_date(concat(f_removeX(  in_Dutydate)),'%Y%m%d'); end if;
   if droptable=0 Then insert into t_log(ltpid,note) values ('p_tforgetdoc_save','出勤日判斷'); end if;
end if; # C

if err_code=0 And @in_Rwid > 0 Then # A10 in_Rwid 判斷，單據關帳、有無此單據
   Set @isCnt = 0;
   Select rwid,Empguid,CloseStatus_z07 into @isCnt,@in_EmpGuid,@CloseStatus_z07 from tforgetdoc 
      Where rwid=@in_Rwid And empguid in (select empguid from tperson where OUguid=@in_OUguid);
   if err_code=0 And @CloseStatus_z07 > 0 
      Then set err_code=1; set @outMsg=concat("此單據，已關帳，無法修改，單據號：",@in_Rwid); end if;
   if err_code=0 And @isCnt=0 
      Then set err_code=1; set @outMsg=concat("無此單據，單據號：",@in_Rwid); end if;
   if droptable=0 Then insert into t_log(ltpid,note) values ('p_tforgetdoc_save','A10 in_Rwid 判斷'); end if;
end if;

if err_code=0 Then # A20 類別碼判斷
   set @in_TypeGuid='';
   Select CodeGuid into @in_TypeGuid From tCatcode Where Syscode='A04' And OUguid in('default',@in_OUguid) And (CodeID=@in_Type or CodeGuid=@in_Type);
   if @in_TypeGuid='' Then set err_code=1; set @outMsg="類別輸入錯誤"; end if;
  if droptable=0 Then insert into t_log(ltpid,note) values ('p_tforgetdoc_save','A20 類別碼判斷'); end if;
end if; # A20 

if err_code=0 And @in_Rwid = 0 Then # A30 人員判斷
   set @in_EmpGuid= '';
   Select EmpGuid into @in_EmpGuid From tperson Where OUguid=@in_OUguid And (EmpID=@in_EmpID or EmpGuid=@in_EmpID );
   if @in_EmpGuid='' Then set err_code=1; set @outMsg="人員輸入錯誤"; end if;
  if droptable=0 Then insert into t_log(ltpid,note) values ('p_tforgetdoc_save','A30 人員判斷'); end if;
end if; # A30

if err_code=0 Then # A40 判斷資料是否在 tOUset 關帳日之後
   select close_date into @in_Close_date from touset where ouguid=@in_OUguid;
   if @in_Dutydate < @in_Close_date Then
      set err_code=1; set @outMsg=concat("無法新增, 關帳日：",cast(@in_Close_date as char)," 以前的資料");  end if;
  if droptable=0 Then insert into t_log(ltpid,note) values ('p_tforgetdoc_save',' A40 判斷資料是否在 tOUset 關帳日之後'); end if;
end if;  # A40

if err_code=0 Then # A50 判斷是否存在其他相同出勤日單據
   set @isCnt=0;
   Select rwid into @isCnt From tforgetdoc Where rwid!=@in_Rwid And empguid=@in_Empguid and dutydate=@in_Dutydate limit 1;
   if @isCnt > 0 Then set err_code=1; set @outMsg=concat("已存在，其他單據，單據號：",@isCnt); set @outRwid=@isCnt; end if;
 if droptable=0 Then insert into t_log(ltpid,note) values ('p_tforgetdoc_save','A50 判斷是否存在其他相同出勤日單據'); end if;
end if; # A50

if err_code=0 Then # A60 判斷，時間是否重疊其它出勤日
   set @dateA = '';
   Select cast(dutydate as char(12)) into @dateA
   from vdutystd_emp
   where empguid=@in_EmpGuid
   and @in_DateStart < Std_Off
   and @in_DateEnd   > Std_On
   and dutydate != @in_Dutydate limit 1;
   if @dateA!='' Then set err_code=1; set @outMsg=concat("時間起迄，重疊其他出勤日：",@dateA); end if;
   if droptable=0 Then insert into t_log(ltpid,note) values ('p_tforgetdoc_save','A60 判斷，時間是否重疊其它出勤日'); end if;
end if; # A60


if err_code=0 Then # End

   insert into tforgetdoc
   (ltuser,ltpid,ForgetDocGuid,EmpGuid,Dutydate,ForgetOn,ForgetOff,Note,ForgetTypeGuid)
   select 
   @in_ltUser,@in_ltpid,uuid(),@in_EmpGuid,@in_Dutydate,@in_DateStart,@in_DateEnd,@in_Note,@in_TypeGuid
   on duplicate key update # 必需存在 unique index (empguid,dutydate) 否則會有錯誤
   ltuser=@in_ltUser
  ,ltpid=@in_ltPid
  ,dutydate=@in_Dutydate
  ,forgetOn=@in_DateStart
  ,forgetOff=@in_DateEnd
  ,note=@in_note
  ,forgetTypeguid=@in_TypeGuid   ;
   set outMsg  =if(@outMsg='','成功',@outMsg);
   set outRwid =if(@outRwid=0,LAST_INSERT_ID(),@outRwid);
   set outError=err_code;
Else # 錯誤時 err_code > 0
   set outMsg=@outMsg;
   set outRwid=@outRwid;
   set outError=err_code;
end if; # End 

end;