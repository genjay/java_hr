drop procedure if exists p_tforgetdoc_save;

delimiter $$

create procedure p_tforgetdoc_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/
,in_EmpID varchar(36)
,in_Type varchar(36)
,in_Dutydate date
,in_DateStart  datetime
,in_DateEnd    datetime
,in_Note text /*備註*/
,in_Rwid int  /*要修改的單據rwid*/
,out outMsg text /*回傳訊息，直接給user看的*/
,out outDupRWID int  /*重疊的請假單*/
,out outErr_code int /*成功失敗代碼*/
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

set @in_OUguid = IFNULL(in_OUguid,'');
set @in_ltUser = IFNULL(in_ltUser,'');
set @in_ltpid  = IFNULL(in_ltpid,'');
set @in_EmpID  = IFNULL(in_EmpID,'');
set @in_Type   = IFNULL(in_Type,'');
set @in_Dutydate = IFNULL(in_Dutydate,'2000-01-01');
set @in_DateStart  = IFNULL(in_DateStart,'2000-01-01 00:00:00');
set @in_DateEnd    = IFNULL(  in_DateEnd,'2000-01-01 00:00:00');
set @in_Note = IFNULL(in_Note,'');
set @in_Rwid = IFNULL(in_Rwid,'0'); 
set @in_Empguid='';
set @in_TypeGuid=''; 
set @Range_On  ='2000-01-01 00:00';
set @Range_Off ='2000-01-01 00:00';
set @in_Close_date=date(now());

set @outDupRWID=0;
set @outMsg='';
set @outErr_code=0;

 insert into t_log (ltpid,note) values ('p_tforgetdoc_save',
concat( "call p_tforgetdoc_save(\n'"
,@in_OUguid  ,"',\n'"
,@in_ltUser  ,"',\n'"
,@in_ltpid   ,"',\n'"
,@in_EmpID   ,"',\n'"
,@in_Type    ,"',\n'"
,@in_Dutydate    ,"',\n'"
,@in_DateStart   ,"',\n'"
,@in_DateEnd     ,"',\n'" 
,@in_Note   ,"',\n'"
,@in_Rwid  ,"',\n"
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");" )); 

if err_code=0 And ifnull(in_OUguid,'')='' Then set err_code=1; set @outMsg="OUguid 為必要輸入條件"; end if;
if err_code=0 And ifnull(in_EmpID,'') ='' And ifnull(in_Rwid,0)=0 Then set err_code=1; set @outMsg="工號及rwid不可同時為空值或零"; end if;
if err_code=0 And ifnull(in_Type,'')  ='' Then set err_code=1; set @outMsg="type為必要輸入";end if;

if ifnull(in_dutydate,'')='' then set err_code=1; set @outMsg='dutydate 沒輸入'; end if;


if err_code=0 Then # A01 抓guid 
      Select empguid into @in_EmpGuid from tperson where OUguid=@in_OUguid 
       and (EmpID=@in_EmpID or EmpGuid=@in_EmpID 
        or empguid =(select empguid from tforgetdoc where rwid=@in_rwid)); 
      Select codeguid into @in_TypeGuid from tcatcode Where syscode='A04' and OUguid=@in_OUguid and (codeID=@in_Type or codeGuid=@in_Type); 
   if err_code=0 And ifnull(@in_TypeGuid,'')='' Then set err_code=1; set @outMsg="忘刷類別，不在可使用範圍內"; end if;
   if err_code=0 And ifnull(@in_Rwid,0)=0 And ifnull(@in_EmpGuid,'')='' Then set err_code=1; set @outMsg="新增模式，工號不存在";end if; 

end if; # A01

if err_code=0 And ifnull(@is_rwid,0)>0 Then # 判斷有無此rwid 資料
   set @isCnt=0;
   select rwid into @isCnt from tforgetdoc where rwid=@in_rwid and empguid in (select empguid from tperson where ouguid=@in_Ouguid);
   if @isCnt=0 Then set err_code=1; set @outMsg="無此筆資料";end if;
end if;

 
if err_code=0 Then # 判斷資料是否在 tOUset 關帳日之後
   select close_date into @in_Close_date from touset where ouguid=@in_OUguid;
   if @in_Dutydate < @in_Close_date Then
      set err_code=1; set @outMsg=concat("無法新增",cast(@in_Close_date as char),"以前的資料");
   end if;
end if; 
 
if err_code=0 And @in_rwid>0 Then
   select rwid into @isCnt from tforgetdoc where rwid=@in_rwid;
   if @isCnt=0 Then
      set err_code=1; #set @outMsg="無法修改，此筆資料已關帳";
   end if;
end if; 

if err_code=0 Then # 已存在其他筆，相同單據
   set @outDupRWID=0;
   select rwid into @outDupRWID from tforgetdoc 
   where Empguid = @in_Empguid and Dutydate=@in_dutydate AND rwid!=@in_Rwid limit 1;
   if @outDupRWID > 0 Then set err_code=1; set @outMsg=concat("已存在其他筆，相同資料單據,單號： ",@outDupRWID); end if;

end if;



if err_code=0 Then # 判斷，時間是否在該出勤日，Range_on , Range_Off 內
   select Range_on,Range_Off into @Range_On,@Range_off
   from vdutystd_emp
   where  empguid=@in_Empguid
   and dutydate=@in_dutydate ; 
   IF err_code=0 And @in_DateStart  Not Between @Range_On And @Range_off 
	Then set err_code=1; set @outMsg="刷卡時間(起)，不在當日應出勤時間內";   end if; 
   IF err_code=0 And @in_DateEnd    Not Between @Range_On And @Range_off 
	Then set err_code=1; set @outMsg="刷卡時間(迄)，不在當日應出勤時間內";  end if;

   end if;
 

##################### 以下正確，開始新增及修改資料

IF err_code = 0 and in_Rwid =0 Then # Z99 完全無誤時，存檔
    
   insert into tforgetdoc
   (ltuser,ltpid,ForgetDocGuid,EmpGuid,Dutydate,ForgetOn,ForgetOff,Note,ForgetTypeGuid)
   select 
   @in_ltUser,@in_ltpid,uuid(),@in_EmpGuid,@in_Dutydate,@in_DateStart,@in_DateEnd,@in_Note,@in_TypeGuid
   ;

  set @Change_RWID = LAST_INSERT_ID(); /*新增時，尚無rwid，所以新增後需取得*/

  set @outMsg = concat("新增成功 單號：",@Change_RWID);
end if;

IF err_code = 0 And @in_Rwid > 0 Then # 修改資料 
   
  update tforgetdoc set
   ltuser=@in_ltUser
  ,ltpid=@in_ltPid
  ,dutydate=@in_Dutydate
  ,forgetOn=@in_DateStart
  ,forgetOff=@in_DateEnd
  ,note=@in_note
  ,forgetTypeguid=@in_TypeGuid
  Where CloseStatus_z07='0' And rwid=@in_Rwid;
  set @outMsg = concat("單號：",@in_Rwid," 修改成功"); 
  
set @a=0;
end if; # IF err_code = 0 And in_Rwid > 0 Then # 修改資料至 toffdoc

set outDupRWID=@outDupRWID;
set outErr_code = err_code;
set outMsg=@outMsg; 
 
end;