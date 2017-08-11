drop procedure if exists p_create_OU;

delimiter $$
# 刷卡機格式存檔
create procedure p_create_OU
( 
 in_OUguid   varchar(36)
,in_ltUser   varchar(36)
,in_ltpid    varchar(36) # 程式代號
,in_ouID     varchar(36)
,in_ouName   varchar(36)
,in_Aid      varchar(36) # 預設帳號
,in_Aid_Desc varchar(36) 
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
 
set err_code=0; set outRwid=0; set outMsg='p_create_OU 執行中'; 
 
end; # begin