drop procedure if exists p_tOffQuota_del;

delimiter $$

create procedure p_tOffQuota_del(
 in_OUguid varchar(36)
,in_LtUser varchar(36)
,in_ltPid  varchar(36)
,in_rwid   int(10)  
,in_Note text
,out outMsg text
,out outRwid int
,out err_code int 
)

begin
/*
call p_tOffQuota_del(
 'microjet',
 'ltUser',
 'ltPid',
 '5',
 '',
 @a,@b,@c);
*/
declare tlog_note text;
declare isCnt int;
declare tmpXX1 text;
declare droptable int default 0; # 1 drop temptable /0 不drop 除錯用

set err_code = 0;
set tlog_note= concat("call p_tOffQuota_del(\n'"
,in_OUguid  ,"',\n'" 
,in_LtUser  ,"',\n'" 
,in_ltPid   ,"',\n'" 
,in_rwid    ,"',\n'"  
,in_note    ,"',\n" 
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");");
call p_tlog(in_ltPid,tlog_note);
call p_SysSet(1);
set outMsg='p_tOffQuota_del,開始';


end # Begin