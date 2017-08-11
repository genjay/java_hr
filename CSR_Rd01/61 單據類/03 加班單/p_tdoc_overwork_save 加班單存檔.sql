drop procedure if exists p_tdoc_overwork_save;

delimiter $$ 

create procedure p_tdoc_overwork_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_emp_ID                    varchar(36)
,in_dutydate                  date
,in_overType_ID               varchar(36)
,in_overStart                 datetime
,in_overEnd                   datetime
,in_OverMins                  int(11)
,in_note                      text 
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code                    text
)  

begin
declare isCnt int;  
declare in_Emp_Guid     varchar(36);
declare in_overDocGuid   varchar(36);
declare in_overtype_Guid varchar(36); 
declare in_CloseStatus int default 0;

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
    set outMsg='sql error';
    set err_code=1;
  end if;
END;  

set err_code=0; set outRwid=0; set outMsg='p_tdoc_forget_save 執行中';

if err_code=0 then
	set isCnt=0;
	Select rwid,emp_Guid into isCnt,in_Emp_Guid 
	from tperson where OUguid=in_OUguid
	and Emp_id=in_Emp_id;
	if isCnt=0 then set err_code=1; set outMsg='工號有誤'; end if;
end if;

if err_code=0 then
	set isCnt=0;
	Select rwid,overtype_Guid into isCnt,in_overtype_Guid 
	from tovertype 
	where OUguid=in_OUguid and overtype_id = in_overtype_id;
	if isCnt=0 then set err_code=1; set outMsg='加班別有誤'; end if;
end if;
if err_code=0 && in_Rwid=0 then # 90 新增
	set in_OverDocGuid=uuid();
	Insert into tdoc_overwork
	(ltUser,ltPid,OverDocGuid,emp_Guid,dutydate,overType_Guid,overStart,overEnd,OverMins,note)
	values 
	(in_ltUser,in_ltPid,in_OverDocGuid,in_emp_Guid,in_dutydate,in_overType_Guid,in_overStart,in_overEnd,in_OverMins,in_note);
	set outMsg=concat('「',in_Rwid,'」','新增完成');
	set outRwid=last_insert_id();
 end if; # 90 

 if err_code=0 && in_Rwid>0 then # 90 修改 
 Update tdoc_overwork Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid
 ,emp_Guid                      = in_emp_Guid
 ,dutydate                      = in_dutydate
 ,overType_Guid                 = in_overType_Guid
 ,overStart                     = in_overStart
 ,overEnd                       = in_overEnd
 ,OverMins                      = in_OverMins
 ,note                          = in_note
 ,closeStatus                   = in_closeStatus
  Where rwid=in_Rwid;
 set outMsg=concat('「',in_Rwid,'」','修改成功');
 set outRwid=in_Rwid;
 end if; # 90 修改
 
end; # begin