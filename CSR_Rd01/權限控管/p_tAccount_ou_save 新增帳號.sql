drop procedure if exists p_tAccount_OU_save;

delimiter $$ 

create procedure p_tAccount_OU_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(11) unsigned
,in_Aid                       varchar(36)
,in_Aid_Desc                  varchar(36)
,in_Valid_St                  datetime
,in_Valid_End                 datetime
,in_PassWD					  varchar(255) # 密碼
,in_Change_PWD				  int
,in_Emp_ID					  varchar(36) # 員工工號可有可無
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare in_Aid_Guid varchar(36);
declare in_Emp_Guid varchar(36);
declare old_Aid_Guid varchar(36);
 
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
    set outMsg='sql error';
    set err_code=1;
  end if;
END;   

insert into tlog_proc (ltpid,note) values
('in_rwid',in_rwid)
,('in_ouguid',in_OUguid)
,('in_Aid',in_Aid); 

set err_code=0; set outRwid=0; set outMsg='p_tAccount_OU_save 執行中';

if err_code=0 && in_Aid='' then set err_code=1; set outMsg='帳號不可空白'; end if;

if err_code=0 && in_Aid_Desc='' then set err_code=1; set outMsg='帳號說明不可空白'; end if;

if err_code=0 && in_Rwid=0 then # 21 新增時，要uuid()
	set in_Aid_Guid=uuid();
end if;  # 21 新增時，要uuid()

if err_code=0 && in_Rwid>0 then # 21 用in_Rwid抓Aid_Guid
	set isCnt=0;
	Select count(*),Aid_Guid,Aid into isCnt,in_Aid_Guid,old_Aid_Guid
	from vtAccount_ou Where taccount_ou_rwid=in_Rwid;
	if isCnt=0 then set err_code=1; set outMsg='無此rwid資料'; end if;
	if in_Aid!=old_Aid_Guid then set err_code=1; set outMsg='暫無提供修改帳號功能'; end if;
end if; #21 用in_Rwid抓Aid_Guid

if err_code=0 then # 22 判斷Aid是否他人使用
	set isCnt=0;
	Select rwid into isCnt from tAccount 
	Where Aid = in_Aid
	and Aid_Guid != in_Aid_Guid;
	if isCnt>0 then set err_code=1; set outMsg='該帳號有人使用中'; end if;
end if;# 22 判斷Aid是否他人使用

if 1 && err_code=0 && in_Emp_ID!='' then # 23 取得in_EmpGuid
	set in_Emp_Guid='';
	Select rwid,Emp_Guid into isCnt,in_Emp_Guid
	from tperson 
	where OUguid=in_OUguid and Emp_ID=in_Emp_ID;
	if isCnt=0 then set err_code=1; set outMsg='無此工號'; end if;
end if;# 23 取得in_EmpGuid
 
if 1 && err_code=0 && in_Rwid>0 then # 90 修改
	update tAccount set
	ltUser=in_ltUser,
	ltPid=in_ltPid,
#	Aid=in_Aid, 帳號不要給修改功能
	Aid_Desc=in_Aid_Desc,
	PassWD=Sha(in_PassWD),
	Change_PWD=in_Change_PWD
	Where Aid_guid=in_Aid_Guid;

	update tAccount_OU set 
	ltUser=in_ltUser,
	ltPid=in_ltPid,
	Valid_St=in_Valid_St,
	Valid_End=in_Valid_End,
	Emp_Guid=in_Emp_Guid,
	note=in_note
	Where rwid=in_Rwid;
	set outMsg='修改完成';
end if; #90 修改

if err_code=0 && in_Rwid=0 then # 90 新增
	Insert into tAccount 
	(ltUser,ltPid,Aid_Guid,Aid,Aid_Desc,PassWD,Change_PWD) values
	(in_ltUser,in_ltPid,in_Aid_Guid,in_Aid,in_Aid_Desc,Sha(in_PassWD),in_Change_PWD);

	Insert into tAccount_OU 
	(ltUser,ltPid,Aid_Guid,OUguid,Valid_St,Valid_End,Emp_Guid,note) values
	(in_ltUser,in_ltPid,in_Aid_Guid,in_OUguid,in_Valid_St,in_Valid_End,in_Emp_Guid,in_note);
	set outMsg='新增完成';
end if; # 90 新增

end; # begin