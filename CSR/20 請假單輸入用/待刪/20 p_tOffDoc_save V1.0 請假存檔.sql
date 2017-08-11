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
,out outError int  # err_code
)  

begin
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

DECLARE err_code int default '0'; 
DECLARE droptable int default '0'; # 0 代表測試中 1，正常使用

call p_SysSet(1);
set @in_OUguid = IFNULL(in_OUguid,'');
set @in_ltUser = IFNULL(in_ltUser,'');
set @in_ltpid  = IFNULL(in_ltpid,'');
set @in_Type   = IFNULL(in_Type,'');
set @in_EmpID  = IFNULL(in_EmpID,'');
set @in_OffMins  = ifnull(in_OffMins,'0');
set @in_Rwid   = IFNULL(in_Rwid,'0');
set @in_Note   = IFNULL(in_Note,'');
set @outRwid   = 0;
set @outMsg    =''; 

if err_code=0 Then # A 日期(起)判斷
  set @xx1 = f_DtimeCheck(f_removeX(in_DateStart));
  if @xx1 !='OK' Then set err_code=1; set @outMsg=concat("時間(起) ",@xx1); end if;
  if err_code=0 Then set @in_DateStart= str_to_date(concat(f_removeX(in_DateStart)),'%Y%m%d%H%i'); end if;
  if droptable=0 Then insert into t_log(ltpid,note) values ('p_tOffDoc_save','日期(起)判斷'); end if;
end if; # A 
 
if err_code=0 Then # B 日期(迄)判斷
   set @xx2 = f_DtimeCheck(f_removeX(in_DateEnd));
   if @xx2 !='OK' Then set err_code=1;  set @outMsg=concat("時間(迄) ",@xx2); end if;
   if err_code=0 Then set @in_DateEnd  = str_to_date(concat(f_removeX(  in_DateEnd)),'%Y%m%d%H%i'); end if;
   if droptable=0 Then insert into t_log(ltpid,note) values ('p_tOffDoc_save','日期(迄)判斷'); end if;
end if; # B 

if err_code=0 Then # B-1 判斷起迄
   if in_DateStart >= in_DateEnd Then set err_code=1; set @outMsg="時間起迄，錯誤"; end if; 
end if;

if err_code=0 And @in_Rwid > 0 Then # A10 in_Rwid 判斷，單據關帳、有無此單據
   Set @isCnt = 0;
   Select rwid,Empguid,CloseStatus_z07 into @isCnt,@in_EmpGuid,@CloseStatus_z07 from tOffdoc
      Where rwid=@in_Rwid And empguid in (select empguid from tperson where OUguid=@in_OUguid);
   if err_code=0 And @CloseStatus_z07 > 0 
      Then set err_code=1; set @outMsg=concat("此單據，已關帳，無法修改，單據號：",@in_Rwid); end if;
   if err_code=0 And @isCnt=0 
      Then set err_code=1; set @outMsg=concat("無此單據，單據號：",@in_Rwid); end if;
   if droptable=0 Then insert into t_log(ltpid,note) values ('p_tOffDoc_save','A10 in_Rwid 判斷'); end if;
end if;

if err_code=0 Then # A20 類別碼判斷
   set @in_TypeGuid='';
   Select CodeGuid,CodeDesc into @in_TypeGuid,@in_TypeDesc From tCatcode Where Syscode='A00' And OUguid in('default',@in_OUguid) And (CodeID=@in_Type or CodeGuid=@in_Type);
   if @in_TypeGuid='' Then set err_code=1; set @outMsg="類別輸入錯誤"; end if;
  if droptable=0 Then insert into t_log(ltpid,note) values ('p_tOffDoc_save','A20 類別碼判斷'); end if;
end if; # A20 

if err_code=0 And @in_Rwid = 0 Then # A30 人員判斷,in_Rwid>0 時，修改模式 不判斷 in_Empguid
   set @in_EmpGuid= '';
   Select EmpGuid into @in_EmpGuid From tperson Where OUguid=@in_OUguid And (EmpID=@in_EmpID or EmpGuid=@in_EmpID );
   if @in_EmpGuid='' Then set err_code=1; set @outMsg="人員輸入錯誤"; end if;
  if droptable=0 Then insert into t_log(ltpid,note) values ('p_tOffDoc_save','A30 人員判斷'); end if;
end if; # A30

if err_code=0 Then # A40 判斷資料是否在 tOUset 關帳日之後
   select close_date into @in_Close_date from touset where ouguid=@in_OUguid;
   if @in_Dutydate < @in_Close_date Then
      set err_code=1; set @outMsg=concat("無法新增, 關帳日：",cast(@in_Close_date as char)," 以前的資料");  end if;
  if droptable=0 Then insert into t_log(ltpid,note) values ('p_tOffDoc_save',' A40 判斷資料是否在 tOUset 關帳日之後'); end if;
end if;  # A40

IF err_code = 0 Then # A50 判斷是否有足夠特休
  set @QuotaCtrl='0';
  select QuotaCtrl into @QuotaCtrl #特補休類假時，才計算 
  from tofftype 
  Where OffTypeGuid=@in_TypeGuid ;
 
  if droptable=0 Then insert into t_log (note) values (concat("A50 特休管控：",@QuotaCtrl)); end if;
  
  if @QuotaCtrl='1' Then # 特補休
       set @OffLeft_Mins=0;
       select ifnull(sum(Off_Mins_left),0) into @OffLeft_Mins # 計算請假當時，可用的特補休時數
       from voffquota_status
       Where 1=1
        And Off_Mins_left > 0
        And Empguid         = @in_EmpGuid
        And OffTypeGuid     = @in_TypeGuid
        And Quota_Valid_ST  < @in_DateStart 
        And Quota_Valid_End > @in_DateStart; 

      if @OffLeft_Mins < @in_OffMins 
         Then set err_code='1'; 
         set @outMsg=concat(@in_TypeDesc ,"剩餘：",round(@OffLeft_Mins/60,1),"hr","  不夠使用"); 
         if droptable=0 Then insert into t_log(ltpid,note) values ('p_tOffDoc_save',concat(@outMsg,'errorXX')); end if;
      end if; 
      if droptable=0 Then insert into t_log(ltpid,note) values ('p_tOffDoc_save',concat('特補休時數',@OffLeft_Mins,'請假分鐘數  ',@in_OffMins )); end if;
  end if;

end if ; # A50 判斷特休

if err_code=0 Then # A60 班別錯誤出現上班時間重疊
    set @isCnt=0;
    set @dutyList='';
    select count(*),group_concat(a.dutydate order by 1) into @isCnt,@dutyList
    from vdutystd_emp a
     left join vdutystd_emp b on a.empguid=b.empguid 
      and a.dutydate != b.dutydate
      and b.dutydate between (a.dutydate- interval 1 day) And (a.dutydate+interval 1 day)  
    Where a.empguid=@in_Empguid
      and a.std_On < b.std_Off
      and a.std_Off > b.std_On
      and a.std_on <   @in_DateEnd
      and a.std_Off >  @in_DateStart  ;
    if @isCnt > 0 Then # A60-1 代表班別錯誤
       set err_code='1'; set @outMsg=concat("班別錯誤，請先檢查班別,錯誤日期：",@dutyList);  end if; 

end if;# A60 

if err_code=0 Then # A70 多日假單，無法用於請半天
  select count(*),min(std_on),max(std_off) into @Cnt,@in_ST,@in_End
  from vdutystd_emp
  where empguid=@in_empguid
  and std_On <   @in_DateEnd
  and std_Off >  @in_DateStart  ;
  if @Cnt>1 And Not (@in_DateStart=@in_ST And  @in_DateEnd = @in_End) Then # A70-1
	 set err_code=1;
     set @outMsg="請假多日，起迄需等於該日上下班時間";   end if; # A70-1
end if;  # A70



if err_code=0 Then # End
  if @in_rwid=0 Then # End-01 新增時
  Insert into tOffDoc
  (offdocguid,empguid,offtypeguid,offdoc_start,offdoc_end,offdoc_mins,Note,ltuser,ltpid)
  select 
  uuid(),@in_EmpGuid,@in_TypeGuid,@in_DateStart,@in_DateEnd,@in_OffMins,@in_Note,@in_ltUser,@in_ltpid; end if;

  if @in_rwid>0 Then # End-02 修改時
   delete from tOffQuota_used Where OffDocGuid=(select offDocGuid from tOffdoc where  rwid = @in_Rwid);
   update toffdoc set
	 offtypeguid= @in_TypeGuid
    ,offdoc_start= @in_DateStart
    ,offdoc_end= @in_DateEnd
    ,offdoc_mins= @in_OffMins
    ,Note= @in_Note
    ,ltuser= @in_ltUser
    ,ltpid= @in_ltpid
   Where closeStatus_z07='0' and rwid = @in_Rwid;  
  end if; # End
   set outMsg  =if(@outMsg='','成功',@outMsg);
   set outRwid =if(@outRwid=0,LAST_INSERT_ID(),@outRwid);
   set outError=err_code;
Else # 錯誤時 err_code > 0
   set outMsg=@outMsg;
   set outRwid=@outRwid;
   set outError=err_code;
end if; # End 

IF err_code = 0 And 1 Then  # ZZ 存檔成功後，執行其他相關
  call  p_toffquota_used_save(@in_OUguid,@in_ltUser,@in_ltpid,@Change_RWID);
  call    p_toffdoc_duty_save(@in_OUguid,@in_ltUser,@in_ltpid,@Change_RWID);
   
end if; # ZZ

end;