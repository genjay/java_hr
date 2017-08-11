drop procedure if exists p_tforgetdoc_del;

delimiter $$

create procedure p_tforgetdoc_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36)  
,in_Rwid int  /*要修改的單據rwid*/
,out outMsg text /*回傳訊息，直接給user看的*/
,out outDupRWID int  /*重疊的請假單*/
,out outErr_code int /*成功失敗代碼*/
)

begin
/*
執行範例 
call p_tforgetdoc_del
(
 'microjet'
,'ltuser'
,'ltpid'
,10   #rwid
,@a
,@b
,@c
);


*/

DECLARE err_code int default '0';

set @in_OUguid = in_OUguid;
set @in_ltUser = in_ltUser;
set @in_ltpid = if(trim(in_ltpid)='','p_tforgetdoc_del',in_ltpid);
set @in_Rwid = in_Rwid;

set @outDupRWID=0;
set @outMsg='';
set @outErr_code=0;

 insert into t_log (ltpid,note) values ('p_tforgetdoc_del',
concat( "call p_tforgetdoc_del(\n'"
,@in_OUguid  ,"',\n'"
,@in_ltUser  ,"',\n'"
,@in_ltpid   ,"',\n'"  
,@in_Rwid  ,"',\n"
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");" )); 

Case # 錯誤判斷
When ifnull(@in_OUguid,'') = '' Then set @outMsg = "ouguid輸入錯誤"; set err_code=1;
When ifnull(@in_rwid,0)=0 Then set @outMsg="rwid 輸入錯誤"; set err_code=1;

Else # 錯誤判斷內，需連資料庫部份

  IF err_code = 0 and @in_rwid>0 Then # A01
     set @isCnt = 0; # 因slect rwid into @isCnt 無資料時，不會修改@isCnt，所以需要reset
     select rwid into @isCnt from tforgetdoc
     where rwid=@in_rwid
      and empguid in (select empguid from tperson where ouguid=@in_OUguid) limit 1;

     if @isCnt = 0 Then # 代表無資料
      set err_code=1;
      set @outMsg=concat("單號：",@in_Rwid," 此筆資料已不存在");     
     end if;

  end if; # a01

  if err_code=0 Then # B01
     set @isCnt=0;
     select rwid into @isCnt from tforgetdoc where CloseStatus_z07='0' And rwid=@in_rwid;
     if @isCnt = 0 Then 
       set err_code=1; set @outMsg="此筆資料已關帳，不能刪除";
      end if;
  end if;

end Case; # Case # 錯誤判斷
##################### 以下正確，開始新增及修改資料

IF err_code = 0 And in_Rwid > 0 Then # 修改資料 
  
     delete from tforgetdoc
     where CloseStatus_z07='0' And rwid=@in_rwid ;
  
  set @Change_RWID = @in_Rwid ; /*修改時，rwid等於 in_Rwid*/
  set @outMsg = "刪除成功-pro";

end if; # IF err_code = 0 And in_Rwid > 0 Then # 修改資料至 toffdoc


set outErr_code = err_code;
set outMsg=@outMsg;



end;