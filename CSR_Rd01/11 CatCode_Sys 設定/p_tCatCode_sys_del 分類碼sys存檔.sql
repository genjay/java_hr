drop procedure if exists p_tCatCode_sys_del; # 分類碼刪除

delimiter $$

create procedure p_tCatCode_sys_del
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
declare isCnt int;
declare is_CodeID varchar(36);
set err_code=0;
set outMsg='p_tCatCode_sys_del 執行中';

if err_code=0 then # 10 判斷有無此資料
  set isCnt=0; set is_CodeID='';
  Select rwid,codeID into isCnt,is_CodeID from tCatcode_sys Where  ouguid=in_ouguid And Rwid =  in_Rwid;
  if isCnt=0 then set err_code=1; set outMsg='資料已不存在'; end if;
end if; # 10  

if err_code=0 then # 90 
  delete from tcatcode_sys where  ouguid=in_ouguid And rwid=in_Rwid;
  set outRwid=in_Rwid;
  set outMsg=concat('「',is_CodeID,'」','刪除成功');
end if; # 90 
  
end # begin