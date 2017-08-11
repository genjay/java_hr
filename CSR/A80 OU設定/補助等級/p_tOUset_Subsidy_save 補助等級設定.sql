drop procedure if exists p_tOUset_Subsidy_save;

delimiter $$

create procedure p_tOUset_Subsidy_save
( 
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36),
in_Rwid     int,
in_typeZ19  varchar(36), 
-- in_typeZ19_Desc varchar(36),
in_Rate    decimal(10,5), 
in_note    text,
out outMsg text,
out outRwid int,
out err_code int
)
begin

declare tlog_note text; 
declare isCnt int;  
set err_code=0;set outRwid=0; set outMsg='p_tOUset_Subsidy_save';

if err_code=0 then # 90
 Insert into tOUset_subsidy
 (OUguid,type_z19,subsidy_rate,Note)
 values
 (in_OUguid,in_typeZ19,in_Rate,in_note)
 on duplicate key update
 subsidy_rate=in_Rate,
 note=in_note;

end if ; # 90
end # Begin