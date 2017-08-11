drop procedure if exists p_tlog;

delimiter $$

create procedure p_tlog(
in_ltPid text,
in_Note  text
)
begin
 
# call p_tlog(in_ltPid,in_Note);

insert into t_log
(connection_id,session_user,schema_name,ltpid,note) values
(connection_id(),session_user(),schema(),in_ltPid,in_Note);

end 