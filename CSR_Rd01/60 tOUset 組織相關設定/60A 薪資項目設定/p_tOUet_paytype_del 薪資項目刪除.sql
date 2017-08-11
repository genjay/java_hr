drop procedure if exists p_tOUset_paytype_del;

delimiter $$ 

create procedure p_tOUset_paytype_del
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare is_paytype_id,is_paytype_Guid varchar(36);

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tOUset_paytype_del 執行中'; 

if err_code=0 then
 set isCnt=0; 
 Select rwid,paytype_iD,paytype_Guid 
 into isCnt,is_paytype_id,is_paytype_Guid
 from tOUset_paytype Where rwid=in_Rwid;
 if isCnt=0 then set err_code=1; set outMsg='資料不存在'; end if;
end if;

 
 if err_code=0 && in_Rwid>0 then # 90 
 Delete from tOUset_paytype Where rwid=in_Rwid;
 set outMsg=concat('「',in_Paytype_ID,'」','修改完成');
 set outRwid=in_Rwid;
end if; # 90

end; # begin