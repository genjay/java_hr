drop procedure if exists p_tduty_b_save;

delimiter $$

CREATE   PROCEDURE `p_tduty_b_save`(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_RWID int)
begin

DECLARE err_code int default '0';
set @in_OUguid=in_OUguid;
set @in_ltUser=in_ltUser;
set @in_ltpid=in_ltpid;
set @in_RWID=in_RWID;



end
