drop procedure if exists p_tOffDoc_save;

delimiter $$

create procedure p_tOffDoc_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/
,in_EmpID varchar(36)
,in_Type varchar(36)
,in_DateStart  datetime
,in_DateEnd    datetime
,in_OffMins    int /*請假分鐘數*/
,in_Note text /*備註*/
,in_Rwid int  /*要修改的假單rwid*/
,out outMsg text /*回傳訊息，直接給user看的*/
,out outDupRWID int  /*重疊的請假單*/
,out outErr_code int /*成功失敗代碼*/
)

begin
/*
執行範例
call p_toffdoc_save(
 'microjet' #*loginOU 
,(select empguid from tperson where ouguid='microjet' and empid='a00514') #loginUser 
,'jsp_fjksdlj' #程式代號 
,(select empguid from tperson where ouguid='microjet' and empid='a00024') # docUser 
,(select CODEGUID from tcatcode where syscode='a00' and ouguid='microjet' and codeiD='OFF01') # offtype 
,'2014-04-01 08:00'
,'2014-04-01 17:20'
,'480'
,'textNccccccccccote' # note 
,'0' # rwid 
,@a #message
,@b # duprwid
,@c # errcode
);

*/

DECLARE err_code int default '0';
DECLARE is_change int default '0'; /*是不是補休類假別*/
DECLARE QuotaCtrl varchar(1); /*是不是額度控管假別*/
DECLARE OffLeft_Mins int default '0'; /*剩餘請假時間(分)*/

set @in_OUguid = in_OUguid;
set @in_ltUser = in_ltUser;
set @in_ltpid = if(trim(in_ltpid)='','p_tOffDoc_save',in_ltpid);
set @in_Type=in_Type;
set @in_EmpID=in_EmpID;
set @in_DateStart  = in_DateStart;
set @in_DateEnd    = in_DateEnd;
set @in_OffMins = in_OffMins;
set @in_Note = in_Note;
set @in_Rwid = in_Rwid;  
set @in_EmpGuid='';
set @in_TypeGuid='';
set @outMsg='';
set @outDupRWID=0;
set @outErr_code=0;

if err_code=0 And ifnull(in_OUguid,'')='' Then set err_code=1; set @outMsg="OUguid 為必要輸入條件"; end if;
if err_code=0 And ifnull(in_EmpID,'')='' And ifnull(in_Rwid,0)=0 Then set err_code=1; set @outMsg="工號及rwid不可同時為空值或零"; end if;
if err_code=0 And ifnull(in_Type,'')='' Then set err_code=1; set @outMsg="type為必要輸入";end if;


if err_code=0 Then # 抓guid 

      Select empguid into @in_EmpGuid from tperson where OUguid=@in_OUguid and (EmpID=@in_EmpID or EmpGuid=@in_EmpID 
        or empguid =(select empguid from toffdoc where rwid=@in_rwid));
      Select codeguid into @in_TypeGuid from tcatcode Where syscode='A00' and OUguid=@in_OUguid and (codeID=@in_Type or codeGuid=@in_Type);
 
end if;

if err_code=0 And @in_TypeGuid='' Then set err_code=1; set @outMsg="請假類別錯誤"; end if;
if err_code=0 And @in_EmpGuid=''  Then set err_code=1; set @outMsg="人員輸入錯誤"; end if;

if err_code=0 And ifnull(in_Rwid,0) > 0 Then # 判斷rwid 是否存在該筆資料
 set @isCnt=0;
 select rwid into @isCnt from toffdoc where empguid in (select empguid from tperson where ouguid =@in_OUguid) 
   And rwid=@in_Rwid limit 1;
 if @isCnt =0 Then set err_code=1; set @outMsg="無此筆資料"; end if;
end if;

if err_code=0 Then # 判斷資料是否在 tOUset 關帳日之後
   select close_date into @in_Close_date from touset where ouguid=@in_OUguid;
   if date(@in_DateStart) < @in_Close_date Then
      set err_code=1; set @outMsg=concat("無法新增",cast(@in_Close_date as char),"以前的資料");
   end if;
end if; 


if err_code=0 Then  # 判斷關帳
   set @isCnt=0;
   select rwid into @isCnt from toffdoc where closeStatus_z07 > '0' and rwid=@in_Rwid;
   if @isCnt > 0 Then set err_code=1; set @outMsg="無法修改、資料已關帳"; end if;   

end if;

if err_code=0 Then # 多日假單，無法用於請半天
  select count(*),min(std_on),max(std_off) into @Cnt,@in_ST,@in_End
from vdutystd_emp
where empguid=@in_empguid
and std_On <   @in_DateEnd
and std_Off >  @in_DateStart  ;
  if @Cnt>1 And Not (@in_DateStart=@in_ST And  @in_DateEnd = @in_End) Then
	 set err_code=1;
     set @outMsg="請假多日，起迄需等於該日上下班時間";

  end if;
end if;





IF err_code = 0 Then  # 判斷是否有重疊的假單

  set @outDupRWID = 0; # select rwid into @outDupRWid , 無資料時，@outDuprwid不會被更新，所以要先清成 0
  select 
  a.rwid  into @outDupRWID
  from toffdoc a
  inner join tofftype b on a.offtypeguid=b.offtypeguid and b.Can_Duplicate='0'
  where 
    a.empguid = @in_EmpGuid
  and a.offDoc_end   > @in_DateStart /*請假起*/
  and a.offDoc_start < @in_DateEnd /*請假迄*/
  and a.rwid != @in_Rwid /*請假單rwid*/
  limit 1 /*只能抓一筆*/;

 IF @outDupRWID > 0 Then
 set @outMsg=concat("已有請假單時間重疊"," 單號：",@outDupRWID); 
 set outDupRWID=ifnull(@outDupRWID,0);
 set err_code = 1;
 end if; #  IF @outDupRWID > 0 Then
end if; # IF err_code = 0 Then  # 判斷是否有重疊的假單

###################################################################

IF err_code = 0 Then # 判斷是否有足夠補休
 select count(*) into @Is_Change /*若是補休的假別*/
 from tovertype 
 Where OfftypeGuid=@in_TypeGuid ;  
 set @err=err_code;
  

IF err_code = '0' And Is_Change > '0' /*請假為補休的假別*/ THEN 

   
  select /*補休可用時數*/
   sum(off_mins_left) into @OffLeft_Mins 
  from `vovertooff_status` a
  Where 
      a.Off_Mins_Left > 0
  and a.empGuid     = @in_EmpGuid
  and a.offtypeguid = @in_TypeGuid 
  and a.OverEnd     < @in_DateStart /*請假起*/
  and a.Valid_end   > @in_DateStart /*請假起，不是迄*/;

  set OffLeft_Mins=ifnull(@OffLeft_Mins,0); /*可休假時間(分)*/
  IF in_OffMins > OffLeft_Mins /*請假分鐘數大於可用分鐘數*/ Then
    set err_code = 1;
    set @outMsg = concat("請假時間大於可用時間，剩餘時間：",Round(OffLeft_Mins/60,1),"小時");

  END IF;# IF in_OffMins > OffLeft_Mins /*請假分鐘數大於可用分鐘數*/ Then

END IF; ### IF Is_Change > 0 /*請假為補休的假別*/ THEN 

end if; #### IF err_code = 0 Then # 判斷是否有足夠補休

IF err_code = 0 Then # 判斷是否有足夠特休
  select QuotaCtrl into @QuotaCtrl /*若是特休類假別*/
  from tofftype 
  Where OffTypeGuid=@in_TypeGuid ; 
 
IF @QuotaCtrl=b'1' And  @Is_Change=0 Then /*特休類*/

  select sum(Off_Mins_left) into @OffLeft_Mins 
  from voffquota_status
  Where 
      Off_Mins_left > 0
  And Empguid         = @in_EmpGuid
  And OffTypeGuid     = @in_TypeGuid
  And Quota_Valid_ST  < @in_DateStart 
  And Quota_Valid_End > @in_DateStart;

  set OffLeft_Mins=ifnull(@OffLeft_Mins,0); 

    IF in_OffMins > OffLeft_Mins /*請假分鐘數大於可用分鐘數*/ Then
    set err_code = 1;
    set @outMsg = concat("請假時間大於可用時間，剩餘時間：",Round(OffLeft_Mins/60,1),"小時");

    END IF;# IF in_OffMins > OffLeft_Mins /*請假分鐘數大於可用分鐘數*/ Then
end if; # IF @QuotaCtrl=b'1' And  @Is_Change=0 Then /*特休類*/
END IF; # IF err_code = 0 Then # 判斷是否有足夠特休
 

###### 以下為判斷正確性後，進入新增、修改階段
IF err_code = 0 And in_Rwid = 0 Then # 新增資料至 toffdoc

  Insert into tOffDoc
  (offdocguid,empguid,offtypeguid,offdoc_start,offdoc_end,offdoc_mins,Note,ltuser,ltpid)
  select 
  uuid(),@in_EmpGuid,@in_TypeGuid,@in_DateStart,@in_DateEnd,@in_OffMins,@in_Note,@in_ltUser,@in_ltpid;

  set @Change_RWID = LAST_INSERT_ID(); /*新增時，尚無rwid，所以新增後需取得*/

  set @outMsg = "請假單新增成功";
  
end if; # IF err_code = 0 Then # 新增資料至 toffdoc

IF err_code = 0 And in_Rwid > 0 Then # 修改資料至 toffdoc
   
   update toffdoc set
	 offtypeguid= @in_TypeGuid
    ,offdoc_start= @in_DateStart
    ,offdoc_end= @in_DateEnd
    ,offdoc_mins= @in_OffMins
    ,Note= @in_Note
    ,ltuser= @in_ltUser
    ,ltpid= @in_ltpid
   Where closeStatus_z07='0' and rwid = @in_Rwid;  
   set @Change_RWID = @in_Rwid ; /*修改時，rwid等於 in_Rwid*/
   set @outMsg = "請假單修改成功";   

end if; # IF err_code = 0 And in_Rwid > 0 Then # 修改資料至 toffdoc

set outMsg = @outMsg;
set outErr_code = err_code;

IF err_code = 0 && 1 Then
  call p_tovertooff_used_save(@in_OUguid,@in_ltUser,@in_ltpid,@Change_RWID);
  call  p_toffquota_used_save(@in_OUguid,@in_ltUser,@in_ltpid,@Change_RWID);
  call    p_toffdoc_duty_save(@in_OUguid,@in_ltUser,@in_ltpid,@Change_RWID);
end if;
 

end;