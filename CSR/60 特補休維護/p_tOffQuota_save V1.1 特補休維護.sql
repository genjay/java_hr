drop procedure if exists p_tOffQuota_save;

delimiter $$

create procedure p_tOffQuota_save(
 in_OUguid varchar(36)
,in_LtUser varchar(36)
,in_ltPid  varchar(36)
,in_rwid   int(10) unsigned
,in_Empid  varchar(10) 
,in_offtype varchar(36) 
,in_Quota_Year smallint(6)
,in_Quota_seq tinyint(4)
,in_Quota_OffMins int(11)
,in_Quota_Valid_St  datetime
,in_Quota_Valid_End datetime
,in_Note text
,out outMsg text
,out outRwid int
,out err_code int 
)

begin
/*
call p_tOffQuota_save(
'microjet'
,'ltUser'
,'ltPid'
,5  # rwid
,'' #Empid 
,'off12' # offtype
,2014    # year
,0       # seq
,320     # offmins
,'2014-01-01'  # in_Quota_Valid_St  datetime
,'2014-12-31'  # in_Quota_Valid_End datetime
,''    # in_Note text
,@a # out outMsg text
,@b # out outRwid int
,@c # out err_code int 
)
*/
declare tlog_note text;
declare isCnt int;
declare tmpXX1 text;
declare droptable int default 0; # 1 drop temptable /0 不drop 除錯用

set err_code = 0;
set tlog_note= concat("call p_tOffQuota_save(\n'"
,in_OUguid  ,"',\n'" 
,in_LtUser  ,"',\n'" 
,in_ltPid   ,"',\n'" 
,in_rwid    ,"',\n'" 
,in_Empid   ,"',\n'"  
,in_offtype   ,"',\n'"  
,in_Quota_Year      ,"',\n'" 
,in_Quota_seq       ,"',\n'" 
,in_Quota_OffMins   ,"',\n'" 
,in_Quota_Valid_St  ,"',\n'" 
,in_Quota_Valid_End ,"',\n'"  
,in_note            ,"',\n" 
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");");
call p_tlog(in_ltPid,tlog_note);
call p_SysSet(1);
set outMsg='p_tOffQuota_save,開始';


end # Begin