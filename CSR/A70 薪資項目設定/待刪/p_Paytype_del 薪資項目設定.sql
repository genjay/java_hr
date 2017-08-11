drop procedure if exists p_tPaytype_del; # 分類碼刪除

delimiter $$

create procedure p_tPaytype_del
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
/* 
call p_tCatCode_del
(
 'microjet'
,'ltuser'
,'ltpid'
,33   # tcatcode.rwid
,@a
,@b
,@c
);

*/
 
declare tlog_note text;  
declare tmpA,tmpB,tmpC text;
declare isCnt int;  
set err_code=0; 
set outRwid=in_Rwid;
call p_sysset(1);

set outMsg='p_Paytype_del 執行中';

if err_code=0 then # 10
  set isCnt=0 ;
  Select rwid into isCnt from tperson_payset Where a06_guid=
   (select codeguid from tcatcode where codeguid = (select paytypeguid from tpaytype where rwid=in_Rwid)) limit 1;
  if isCnt>0 then set err_code=1; set outMsg='此設定已被tperson_payset 使用'; end if;
  
end if; # 10


if err_code=0 && 1 then # 90 刪除
  Select rwid into isCnt from tcatcode where codeguid = (select paytypeguid from tpaytype where rwid=in_Rwid);
  set outMsg=concat((Select concat('(',codeid,')') from tcatcode where rwid=isCnt),' 刪除成功');

  Delete from tPaytype Where rwid=in_rwid;  
  call p_tCatCode_del(in_OUguid,in_ltUser,in_ltPid,isCnt
        ,tmpA,tmpB,tmpC);  

  
end if; # 90 刪除

 
  
end # begin