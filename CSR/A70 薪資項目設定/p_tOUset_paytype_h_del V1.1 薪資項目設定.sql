drop procedure if exists p_tOUset_paytype_h_del;

delimiter $$

create procedure p_tOUset_paytype_h_del
( 
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36),
in_A06_ID   varchar(36),
out outMsg text,
out outRwid int,
out err_code int
)
begin

declare tlog_note text; 
declare in_A06_Guid varchar(36);
declare isCnt int;  
set sql_safe_updates=0;
set err_code=0;set outRwid=0; set outMsg='p_tOUset_paytype_h_del';


if err_code=0 then # 10
 set isCnt=0;
 select Rwid,codeGuid into isCnt,in_A06_Guid from tcatcode 
 where syscode='a06' and ouguid=in_OUguid and codeid=in_A06_ID;
 if isCnt=0 then set err_code=1; set outMsg=concat(in_A06_ID,'資料不存在'); end if;
end if; # 10

IF err_code=0 then # 90 資料刪除
  delete from touset_paytype_list
  where a06_guid=in_A06_Guid;
  
  delete from touset_paytype_h
  where a06_guid=in_A06_Guid;
  set outMsg=concat(in_A06_ID,'設定資料刪除,若要刪除選項，請至分類碼(A06)刪除');
end if; # 90 

 
end # Begin