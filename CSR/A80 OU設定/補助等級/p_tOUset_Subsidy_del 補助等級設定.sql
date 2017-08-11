drop procedure if exists p_tOUset_Subsidy_del;

delimiter $$

create procedure p_tOUset_Subsidy_del
( 
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36),
in_Rwid     int,
out outMsg text,
out outRwid int,
out err_code int
)
begin

declare tlog_note text; 
declare isCnt int;  
set err_code=0;set outRwid=0; set outMsg='p_tOUset_Subsidy_del';

if err_code=0 then # 90
 delete from tOUset_subsidy 
 Where rwid=in_Rwid;

end if ; # 90
end # Begin