drop procedure if exists p_tOverDoc_del; # 加班單刪除

delimiter $$

create procedure p_tOverDoc_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/ 
,in_Rwid int  /*要修改的假單rwid*/
,out outMsg text /*回傳訊息，直接給user看的*/
,out outRwid int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin
declare isCnt int; 
declare in_offdocguid varchar(36);
DECLARE EXIT HANDLER FOR SQLEXCEPTION#, SQLWARNING
BEGIN
    ROLLBACK;
END;
set err_code=0;

if err_code=0   then # 10 判斷該單據是否存在
  set isCnt=0; set outMsg='10 判斷該單據是否存在';
  Select Rwid into isCnt from tOverDoc Where Rwid=in_Rwid;
  if isCnt=0 Then set err_code=1; set outMsg='單據不存在'; end if;
end if; # 10 判斷該單據是否存在

if err_code=0   Then # 20 判斷關帳沒
   set isCnt=0; set outMsg='20 判斷關帳沒';
   Select rwid into isCnt From tOverDoc Where closeStatus_z07>'0' and rwid=in_Rwid;
   if isCnt > 0 Then set err_code=1; set outMsg="無法刪除，此單已關帳"; end if;
end if; # 20 判斷關帳沒

if err_code=0 then # 30 檢查該加班單是否已經使用補休
   set isCnt = 0; set outMsg='30';
   Select offdocguid,rwid into  in_offdocguid,isCnt from tOffQuota_used
   Where QuotaDocGuid in (select OverDocGuid from tOverDoc Where rwid=in_Rwid) limit 1;

   if isCnt > 0 Then # 30-1 抓取請假單號   
    Select rwid into isCnt from tOffdoc where offdocguid=in_offdocguid;
    set err_code=1; set outMsg=concat("此單據已使用補休，不能修改 請假單據：",isCnt); end if;
end if; # 30-1 抓取請假單號

if err_code=0 then # 40 檢查該單據是否屬於該ou
  set isCnt=0; set outMsg='40';
  Select a.rwid into isCnt from tOverdoc a 
  Where a.Rwid=in_Rwid and a.Empguid in (select Empguid from tperson where OUguid=in_OUguid);
  if isCnt=0 Then set err_code=1; set outMsg='該單據不屬於該OU'; end if;

end if;

if err_code=0 And in_rwid > 0 Then # 90 刪除
   set outMsg='90 刪除中';
 start transaction;
   delete from tOffQuota Where QuotaDocguid in (select OverdocGuid from tOverdoc Where rwid=in_Rwid);
   delete from toverdoc 
   Where closeStatus_z07='0'  
    And empguid in (select empguid from tperson where ouguid=in_OUguid) 
    And rwid=in_rwid ;
   set outMsg=concat(in_Rwid," 刪除成功");
 commit;
 
end if; # 90 刪除

end; # begin



