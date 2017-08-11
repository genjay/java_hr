drop procedure if exists p_tperson_del; # 人員資料刪除

delimiter $$

create procedure p_tperson_del
(
 in_OUguid varchar(36)
,in_LtUser varchar(36)
,in_ltPid  varchar(36)
,in_rwid   int(10)    
,out outMsg   text
,out outRwid  int
,out err_code int
)

begin
declare tlog_note text;
declare isCnt int;
set err_code = 0;
 
 
end # Begin