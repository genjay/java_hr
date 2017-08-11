drop procedure if exists p_tovertype_del;

delimiter $$ 

create procedure p_tovertype_del
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
declare isCnt int;  
declare is_overtype_id varchar(36);
declare is_overtype_Guid varchar(36);
declare is_outMsg,is_outRwid text; # 用來執行proc，接回傳值用
declare is_err_code int;


DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
/*
call p_tovertype_del
(
'microjet','',''
,2 #in_Rwid      int  # 0 代表新增，大於 0 代表修改 
,'' #in_note      text
,@a,@b,@C);
*/
 
set err_code=0; set outRwid=0; set outMsg='p_tovertype_del 執行中';
 
if err_code=0 then # 10 
 set isCnt=0;
 Select rwid,overtype_id,overtype_guid into isCnt,is_overtype_id,is_overtype_guid
 from tovertype where  ouguid=in_ouguid And rwid = in_Rwid;
 if isCnt=0 then set err_code=1; set outMsg='資料不存在'; end if;
end if; # 10

if err_code=0 then # 判斷是否被其他table使用
 Call p_CheckGuid_Used('tovertype','overtype_guid',is_overtype_guid,is_outMsg,is_outRwid,is_err_code);
 if is_err_code=1 then set err_code=1; 
  set outMsg=concat('「',is_overtype_id,'」被',is_outMsg); end if;
end if; #


if err_code=0 then # 90
 Delete from tovertype where  ouguid=in_ouguid And rwid = in_Rwid;
 set outMsg=concat('「',is_overtype_id,'」','刪除成功');
 set outRwid=in_Rwid;
end if; # 90
 
end; # begin