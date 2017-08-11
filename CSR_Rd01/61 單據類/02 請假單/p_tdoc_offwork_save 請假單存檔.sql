drop procedure if exists p_tdoc_offwork_save;

delimiter $$ 

create procedure p_tdoc_offwork_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_Emp_ID                    varchar(36)
,in_offType_ID                varchar(36)
,in_OffDoc_Start              datetime
,in_OffDoc_End                datetime
,in_OffDoc_Mins               int(11)
,in_note                      text 
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code                    text
)  

begin
declare isCnt int;  
declare in_Emp_Guid     varchar(36);
declare in_offDocGuid   varchar(36);
declare in_offtype_Guid varchar(36); 
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
	Select rwid,offtype_Guid into isCnt,in_offtype_Guid 
	from tofftype 
	where OUguid=in_OUguid and offtype_id = in_Offtype_id;
	if isCnt=0 then set err_code=1; set outMsg='假別有誤'; end if;
end if;

if err_code=0 && in_Rwid=0 then # 90 新增
	set in_OffDocGuid=uuid();

	Insert into tdoc_offwork
	(ltUser,ltPid,OffDocGuid,Emp_Guid,offType_Guid,OffDoc_Start,OffDoc_End,OffDoc_Mins,note)
	values 
	(in_ltUser,in_ltPid,in_OffDocGuid,in_Emp_Guid,in_offType_Guid,in_OffDoc_Start,in_OffDoc_End,in_OffDoc_Mins,in_note);
	set outMsg=concat('「',in_Rwid,'」','新增完成');
	set outRwid=last_insert_id();
 end if; # 90 

 if err_code=0 && in_Rwid>0 then # 90 修改 
	Update tdoc_offwork Set
	 ltUser                        = in_ltUser
	,ltpid                         = in_ltpid
	,Emp_Guid                      = in_Emp_Guid
	,offType_Guid                  = in_offType_Guid
	,OffDoc_Start                  = in_OffDoc_Start
	,OffDoc_End                    = in_OffDoc_End
	,OffDoc_Mins                   = in_OffDoc_Mins
	,note                          = in_note
	,CloseStatus                   = in_CloseStatus
	Where rwid=in_Rwid;
	set outMsg=concat('「',in_Rwid,'」','修改成功');
	set outRwid=in_Rwid;
 end if; # 90 修改
 

end; # begin