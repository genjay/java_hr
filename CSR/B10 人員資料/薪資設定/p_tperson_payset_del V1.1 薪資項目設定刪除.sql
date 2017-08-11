drop procedure if exists p_tperson_payset_del; # 薪資項目設定刪除

delimiter $$

create procedure p_tperson_payset_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36)  
,in_Rwid int  /*要修改的單據rwid*/
,out outMsg text /*回傳訊息，直接給user看的*/
,out outRwid int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin
set err_code=0;
set outMsg='p_tperson_payset_del 執行中';

if err_code=0 then # 90 刪除
  delete from tperson_payset where rwid = in_Rwid;
end if; # 90

 

end;