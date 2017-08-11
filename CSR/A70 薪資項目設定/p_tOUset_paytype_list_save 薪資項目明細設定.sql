drop procedure if exists p_tOUset_paytype_list_save;

delimiter $$

create procedure p_tOUset_paytype_list_save
( 
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36),
in_A06_ID   varchar(36),  
in_Z05_ID   varchar(36), 
in_Z05_value int,
in_Note    text,
out outMsg text,
out outRwid int,
out err_code int
)
begin

declare tlog_note text; 
declare in_A06_Guid varchar(36);
declare isCnt int;  
set err_code=0;set outRwid=0; set outMsg='p_tOUset_paytype_list_save';


if err_code=0 then # 05 in_Z05_value 只能 -1、0、1
  if not in_Z05_value regexp '-?[0-1]' 
    then set err_code=1; set outMsg='值，只能0、-1、1'; end if;
end if; 

if err_code=0 then # 10 抓 a06_guid
  set isCnt=0; set in_A06_Guid='';
  Select rwid,codeguid into isCnt,in_A06_Guid
  from tcatcode
  Where syscode='A06' and ouguid=in_OUguid and codeID=in_A06_ID;
  if isCnt=0 then set err_code=1; set outMsg='A06_ID 錯誤'; end if;
end if; # 10 

if err_code=0 then # 90 修改
  Insert into tOUset_paytype_list
  (A06_guid,type_z05,z05_value,note)
  values
  (in_A06_Guid,in_Z05_ID,in_Z05_value,in_Note)
  On duplicate key update
  z05_value=in_Z05_value,
  note=in_Note;
  set outMsg='明細修改完成'; 
end if; # 90 修改
 
end # Begin