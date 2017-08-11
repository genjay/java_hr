drop procedure if exists p_tcard_type_del;

delimiter $$
# 刷卡機格式存檔
create procedure p_tcard_type_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_Rwid      int  # 0 代表新增，大於 0 代表修改 
,in_note      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt,in_stop_used int; 
declare in_cardtype_id varchar(36);

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tcard_type_del 執行中';

if err_code=0 then # 10
  set isCnt=0; set in_cardtype_id=''; set in_stop_used=0; set outMsg='取得 in_cardtype_id ing...';
  Select rwid,cardtype_id,stop_used into isCnt,in_cardtype_id,in_stop_used from tcard_type
  Where rwid = in_Rwid;
  if isCnt=0 then set err_code=1; set outMsg='資料不存在'; end if;
  if in_stop_used=0 then set err_code=1; set outMsg='資料需停用才能刪除'; end if;
end if; # 10 
 

if err_code=0 && in_Rwid>0 then # 90 
  set outMsg='delete ing...';
  delete from tcard_type  where rwid =  in_Rwid;
  set outRwid = in_Rwid;
  set outMsg = concat(in_cardtype_id,' 修改完成');
end if; # 90 
 
end; # begin