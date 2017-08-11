drop procedure if exists p_log;

delimiter $$

create procedure  p_log(
 inPid varchar(50)
,inData text
,inSTR_2 text
)
begin
 
  set @inPid = inPid;
  set @inData = inData;
  set @inSTR_2 = inSTR_2;

  insert into t_log
  (session_user,schema_name,version,CONNECTION_ID
  ,str_type  ,pid,indata)
  SELECT  session_user(),SCHEMA(), VERSION(),CONNECTION_ID()
  ,@inSTR_2,@inPid,@inData ;



end ;