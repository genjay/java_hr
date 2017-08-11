drop procedure if exists p_tCatCode_del; # 分類碼刪除

delimiter $$

create procedure p_tCatCode_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/ 
,in_Rwid      int  /*要修改的單據rwid*/
,out outMsg  text /*回傳訊息，直接給user看的*/
,out outRwid  int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin
declare is_Cnt int; 
declare is_CodeID   varchar(36);  
declare is_CodeGuid varchar(36);
declare is_outMsg,is_outRwid text; # 用來執行proc，接回傳值用
declare is_err_code int;

set err_code=0; set outRwid=0; set outMsg='p_tCatCode_del 執行中';

if err_code=0 then # 10 判斷有無資料及抓取codeID,codeGuid
  set is_Cnt=0; set is_CodeID = '';  
  Select Rwid,codeID,codeGuid into is_Cnt,is_CodeID,is_CodeGuid
  from tcatcode 
  where  ouguid=in_ouguid And rwid = in_Rwid;
  if is_Cnt=0 then set err_code=1; set outMsg='無此資料'; end if;
end if; # 10

if err_code=0 then # 判斷是否被其他table使用
 Call p_CheckGuid_Used('tCatCode','codeGuid',is_CodeGuid,is_outMsg,is_outRwid,is_err_code);
 if is_err_code=1 then set err_code=1; 
  set outMsg=concat('「',is_CodeID,'」被',is_outMsg); end if;
end if; #


if err_code=0 then # 90
  delete from tcatcode where  ouguid=in_ouguid And rwid =  in_Rwid;
  set outMsg=concat('「',is_CodeID,'」',' 刪除成功'); set outRwid = in_Rwid;
end if; # 90

  
end # begin