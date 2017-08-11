drop procedure if exists p_tOffDoc_del;

delimiter $$

create procedure p_tOffDoc_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/
,in_Rwid int  /*要修改的假單rwid*/
,out outMsg text /*回傳訊息，直接給user看的*/
,out outDupRWID int  /*重疊的請假單*/
,out outErr_code int /*成功失敗代碼*/
)

begin
/*
執行範例

call p_toffdoc_del('microjet','user','pid',16501,@a,@b,@c);

*/

DECLARE err_code int default '0';
DECLARE is_change int default '0'; /*是不是補休類假別*/
DECLARE QuotaCtrl varchar(1); /*是不是額度控管假別*/
DECLARE OffLeft_Mins int default '0'; /*剩餘請假時間(分)*/

 call p_SysSet(1); # 設定預設參數

set @in_OUguid = in_OUguid;
set @in_ltUser = in_ltUser;
set @in_ltpid = if(trim(in_ltpid)='','p_tOffDoc_save',in_ltpid); 
set @in_Rwid = in_Rwid; 
set @outDupRWID=0;
set @outMsg='';
set @outErr_code=0;

Case 
/*不需連資料庫的錯誤類型*/
When IFNULL(in_Rwid,'')=''  
 Then set @outMsg="請輸入rwid"; set err_code=1;

Else /*需要連資料庫判斷的錯誤類型*/

if err_code=0 Then 
 set @isCnt=0;
 select rwid into @isCnt 
 from toffdoc
 where rwid=@in_rwid
 and empguid in (select empguid from tperson where ouguid=@in_OUguid) limit 1;
 if @isCnt = 0 Then set err_code=1; set @outMsg="資料不存在"; end if;

end if;

if err_code=0 Then # 判斷資料是否關帳
   set @isCnt=0;
    Select rwid into @isCnt from toffdoc where rwid=@in_rwid and closeStatus_z07 > '0';
   if @isCnt > 0 Then 
   set err_code=1; 
   set @outMsg="無法修改、此筆資料已關帳"; 
   end if;  
   
end if;

end  case ;

###### 以下為判斷正確性後，進入新增、修改階段


IF err_code = 0 And in_Rwid > 0 Then # 修改資料至 toffdoc 

   delete from tOffQuota_used Where OffDocGuid=(select offDocGuid from tOffdoc where  rwid = @in_Rwid);
 
   delete from toffdoc 
   where CloseStatus_z07='0' #未關帳
   And empguid in (select empguid from tperson where ouguid=@in_OUguid) # 該 OU的人員
   and  rwid=@in_Rwid;
   set @outMsg = concat("請假單刪除成功  單號：",@in_Rwid); 
   set @Change_RWID=in_Rwid;
  

end if; # IF err_code = 0 And in_Rwid > 0 Then # 修改資料至 toffdoc

set outMsg=@outMsg;
set outErr_code = err_code;
set outDupRWID=@outDupRWID;

IF err_code = 0 && 1  Then
  
  call  p_toffquota_used_save(@in_OUguid,@in_ltUser,@in_ltpid,@Change_RWID);
  call    p_toffdoc_duty_save(@in_OUguid,@in_ltUser,@in_ltpid,@Change_RWID);
end if;
 
  call p_SysSet(0); # 還原預設參數
end;