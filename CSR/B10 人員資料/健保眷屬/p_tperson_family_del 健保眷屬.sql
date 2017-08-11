drop procedure if exists p_tperson_family_del;

delimiter $$

create procedure p_tperson_family_del
( 
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36)
,in_rwid int(11) unsigned 
,out outMsg text
,out outRwid int
,out err_code int 
)
begin

declare tlog_note text; 
declare in_fam_id text;
declare isCnt int;  
set err_code=0;set outRwid=0; set outMsg='p_tperson_family_del';

if err_code=0 then # 90 
  Select fam_id into in_fam_id from tperson_family where rwid=in_Rwid;
  delete from tperson_family where rwid=in_Rwid;
  set outMsg=concat(in_fam_id,'刪除');
end if; # 90 
 
end # Begin