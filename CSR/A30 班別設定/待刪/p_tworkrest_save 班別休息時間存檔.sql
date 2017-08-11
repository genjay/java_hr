drop procedure if exists p_tworkrest_save;

delimiter $$

create procedure p_tworkrest_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) 
,in_WorkID varchar(36)
,in_holiday int
,in_stHHMM time
,in_stNext int
,in_enHHMM time
,in_enNext int
,in_CutTime int
,inNote text /*備註*/
,in_Rwid int  /*要修改的單據rwid*/
,out outMessage text /*回傳訊息，直接給user看的*/
,out outDupRWID int  /*重疊的請假單*/
,out outErr_code int /*成功失敗代碼*/
)

begin
/*
執行範例 
call p_tworkrest_save
(
 'microjet' #ouguid
,'in_ltUser' # ltUser
,'in_ltpid' # ltpid 
,'A' # workID
,'0' # holiday
,'07:00:00' # in_stHHMM time
,'0' # in_stNext int -1/0/1
,'07:10:00' # in_enHHMM time
,'0' #in_enNext int -1/0/1
,'0' # cuttime 0/1
,'Note ' # 備註
,'0' # inRwid int  要修改的單據，放 0，就可以
,@outMessage #回傳訊息，直接給user看的
,@outDupRWID #重疊的請假單
,@outErr_code #成功失敗代碼
);

*/

DECLARE err_code int default '0';

set @in_OUguid = in_OUguid;
set @in_ltUser = in_ltUser;
set @in_ltpid = if(trim(in_ltpid)='','p_tworkrest_save',in_ltpid);
set @in_WorkID =in_WorkID;
set @in_holiday=in_holiday;
set @in_stHHMM =in_stHHMM;
set @in_stNext_z04 = in_stNext;
set @in_enHHMM =in_enHHMM;
set @in_enNext_z04 =in_enNext;
set @in_CutTime=in_CutTime;
set @in_Rwid=in_Rwid;
 

Case # 錯誤判斷
When @in_OUguid = '' Then set outMessage = "OUguid 輸入錯誤"; 

Else # 錯誤判斷內，需連資料庫部份

  IF err_code = 0 Then # A01 判斷人員及抓出empguid
   Select count(*) into @isCnt From tcatcode Where syscode='A01' and ouguid=in_OUguid and codeGuid=in_WorkID; # 輸入 WorkGuid
   if @isCnt > 0 Then # A02 輸入格式為人員guid
    set @in_WorkGuiD = in_WorkID;
   else # a02
    Select codeguid,count(*) into @in_WorkGuiD,@isCnt From tcatcode Where syscode='A01' and ouguid=in_OUguid and codeID=in_WorkID; # 輸入 WorkID
     if @isCnt = 0 Then # A03 無此workid
      set outMessage = "班別錯誤";
      set err_code = 1;
     end if; # A03
    end if; # A02
  end if; # A01       


end Case; # Case # 錯誤判斷
##################### 以下正確，開始新增及修改資料

IF err_code = 0 and in_Rwid =0 Then # B01
  insert into tworkrest
   (ltUser,ltpid,
    Workguid,holiday,stNext_Z04,stHHMM,enNext_z04,enHHMM,cuttime)
   select 
   @in_ltUser,@in_ltpid
  ,@in_Workguid,@in_Holiday,@in_stNext_z04,@in_stHHMM,@in_EnNext_z04,@in_enHHMM,@in_Cuttime
  From tworkrest a
  Where 
   Not exists (select * from tworkrest b where b.workguid=@in_Workguid and b.holiday=@in_holiday
   and b.stNext_z04=@in_stNext_z04 and b.stHHMM=@in_stHHMM
   and b.enNext_z04=@in_enNext_z04 and b.enHHMM=@in_enHHMM) limit 1;

  set @Change_RWID = LAST_INSERT_ID(); /*新增時，尚無rwid，所以新增後需取得*/
  set outMessage = "新增成功";
end if; # B01

 IF err_code = 0 and in_Rwid > 0 Then # C01 修改模式
   set @isCnt=0;
   select rwid into @isCnt
    from tworkrest
    where  1=1
     and rwid!=@in_rwid
     and holiday = @in_holiday
     and stNext_z04 = @in_stNext_z04
     and stHHMM = @in_stHHMM
     and enNext_z04 = @in_enNext_z04
     and enHHMM = @in_enHHMM
    limit 1;
    
   
  if @isCnt > 0 Then # C02代表修改後，與其他資料相同
    set err_code =1;
    set outMessage=concat(in_stHHMM,'已存在其他組相同的設定資料');
  else # C02 正常，可以修改
   update tworkrest set
     ltUser = @in_User
    ,ltpid = @in_ltpid
    ,holiday = @in_holiday
    ,stNext_z04 = @in_stNext_z04
    ,stHHMM = @in_stHHMM
    ,enNext_z04 = @in_enNext
    ,enHHMM = @in_enHHMM
    ,cuttime = @in_cuttime
    where rwid=@in_rwid;
  set outMessage = "新增成功";
  end if; # C02
end if; # C01
 

set outErr_code = err_code;


end;