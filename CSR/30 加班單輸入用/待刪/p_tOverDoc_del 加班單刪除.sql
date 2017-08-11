drop procedure if exists p_tOverDoc_del; # 加班單刪除

delimiter $$

create procedure p_tOverDoc_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/ 
,in_Rwid int  /*要修改的假單rwid*/
,out outMessage text /*回傳訊息，直接給user看的*/
,out outDupRWID int  /*重疊的請假單*/
,out outErr_code int /*成功失敗代碼*/
)

begin
/*
執行範例 
call p_tOverDoc_del
(
 'microjet'
,'ltuser'
,'ltpid' 
,22693 # rwid 0為新增
,'note'
,@a # 執行訊息
,@b # duprwid
,@c #errcode
);

select * from vtoverdoc
order by rwid desc;
select @a,@b,@c;
*/

DECLARE err_code int default '0'; 

set @in_OUguid =in_OUguid;
set @in_ltUser =in_ltUser ;
set @in_ltpid  =in_ltpid; 
# set @in_Note =  in_Note  ;
set @in_Rwid =  in_Rwid  ;
set outMessage='';


if err_code=0 And ifnull(in_OUguid,'')='' Then set err_code=1; set outMessage="OUguid 為必要輸入條件"; end if;
if err_code=0 And ifnull(in_Rwid,0)=0 Then set err_code=1; set outMessage="Rwid 輸入錯誤"; end if;

if err_code=0 Then # B01 抓guid 
  set @isCnt=0;
  select rwid into @isCnt from toverdoc where rwid=@in_rwid and empguid in (select empguid from tperson where ouguid=@in_ouguid);
  if @isCnt=0 Then set err_code=1; set outMessage="此單，不屬於該OU"; end if;
end if; # B01

if err_code=0 Then # C01 判斷關帳沒
   set @isCnt=0;
   Select rwid into @isCnt From tOverDoc Where closeStatus_z07>'0' and rwid=@in_Rwid;
   if @isCnt > 0 Then set err_code=1; set outMessage="無法刪除，此單已關帳"; end if;
end if;

if err_code=0 then # 檢查該加班單是否已經使用補休
   set  @isCnt = 0;
   Select offdocguid,rwid into  @offdocguid,@isCnt from tOffQuota_used
   Where QuotaDocGuid in (select OverDocGuid from tOverDoc Where rwid=@in_Rwid) limit 1;

   if @isCnt > 0 Then 
    Select rwid into @isCnt from tOffdoc where offdocguid=@offdocguid;
    set err_code=1; set outMessage=concat("此單據已使用補休，不能修改 請假單據：",@isCnt); end if;
 
end if;
 
if err_code=0 And @in_rwid > 0 Then # 刪除
   delete from tOffQuota Where QuotaDocguid in (select OverdocGuid from tOverdoc Where rwid=@in_Rwid);
   delete from toverdoc 
   Where closeStatus_z07='0'  
    And empguid in (select empguid from tperson where ouguid=@in_OUguid) 
    And rwid=@in_rwid ;
   set outMessage="刪除成功";

 call p_tOffQuota_Overdoc(@in_OUguid,@in_LtUser,@in_Pid,@in_rwid,@in_Note,@a,@b,@c); 
end if; 

   set outErr_code= err_code;
   set outDupRWID=@isCnt;



end; # begin



