drop procedure if exists p_tOUset_save;

delimiter $$

create procedure p_tOUset_save
( 
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36),
in_rwid   int(10)  , 
in_typeZ06 varchar(36),
in_typeA06  varchar(36),
out outMsg text,
out outRwid int,
out err_code int
)
begin

declare tlog_note text; 
declare isCnt int;  
set err_code=0;set outRwid=0; set outMsg='p_tOUset_save';

 

end # Begin