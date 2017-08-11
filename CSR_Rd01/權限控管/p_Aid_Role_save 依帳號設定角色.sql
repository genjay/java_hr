drop procedure if exists p_Aid_Role_save;

delimiter $$ 

create procedure p_Aid_Role_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36) 
,in_Aid                       varchar(36)  
,in_data                      text # 傳入trole_rwid (1,'+),(3,'-')...
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare in_Aid_guid varchar(36);
declare in_CntDel,in_CntAdd int;

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
    set outMsg='sql error';
    set err_code=1;
  end if;
END;  

if err_code=0 then
	insert into tlog_proc (ltpid,note) values
('in_OUguid',in_OUguid),
('in_Aid',in_Aid),
('in_data',in_data);
end if;
 
set err_code=0; set outRwid=0; set outMsg='p_tAccount_OU_save 執行中';


if err_code=0 then # 20 取得 Aid_Guid
	set isCnt=0;
	Select Rwid,Aid_Guid into isCnt,in_Aid_guid
	from tAccount 
	where Aid=in_Aid;
	if isCnt=0 then set err_code=1; set outMsg='帳號錯誤'; end if;
end if; # 20 取得 Aid_Guid
 
 
if 1 && err_code=0 then # 21 角色成員部份
 
	drop table if exists tmpProc01;
	CREATE temporary TABLE tmpProc01 (
	rwid int(10) unsigned NOT NULL AUTO_INCREMENT,
	X_rwid    varchar(36),
	X_action  varchar(36),
	Role_Guid  varchar(36),
	note varchar(36),
	PRIMARY KEY (rwid) 
	) ENGINE=Myisam DEFAULT CHARSET=utf8;
	set @sql=concat('Insert into tmpProc01 (X_rwid,X_action) values ',in_data,';');
	prepare s1 from @sql;
	execute s1;
	alter table tmpProc01 add index i01 (X_rwid,x_action);
 
end if; # # 21 角色成員部份
 
if err_code=0 then # 22 判斷能否新增
	update tmpProc01 a,tRole b
	set a.Role_Guid=b.Role_Guid,a.note='OK_Add'
	where a.x_action='+' and a.x_rwid=b.rwid and b.OUguid=in_OUguid;
	update tmpProc01 a,tRole_member b
	set a.note='NG_exists'
	where a.x_action='+' and a.Role_Guid=b.Role_Guid and b.Aid_Guid=in_Aid_Guid;
end if; # 22 判斷能否新增

if err_code=0 then # 23 判斷能否刪除
	update tmpProc01 a,tRole_member b
	set a.Role_Guid=b.Role_Guid,a.note='OK_Del'
	where a.x_action='-' and a.x_rwid=b.rwid ;
end if; # 23 判斷能否刪除


if err_code=0 then # 90 新增
	Insert into tRole_member (Role_Guid,Aid_Guid) 
	Select Role_Guid,in_Aid_Guid from tmpProc01 x
	Where x.x_action='+' and x.note='OK_Add';

end if; # 90 新增

if err_code=0 then # 90 新增
	Delete tRole_member 
	from tRole_member,tmpProc01 b
	where tRole_member.rwid=b.X_rwid and b.note='OK_Del';

end if; # 90 新增

if err_code=0 then # 95 顯示用訊息
	Select count(*) into in_CntDel from tmpProc01 
	Where note='OK_Del';
	Select count(*) into in_CntAdd from tmpProc01 
	Where note='OK_Add';
	Case
	When in_CntDel>0 Then set outMsg=concat('刪除',in_CntDel,'筆');
	When in_CntAdd>0 Then set outMsg=concat('新增 ',in_CntAdd,'筆');
	Else set outMsg='Error';
	End Case; 
end if;# 95 顯示用訊息

if err_code=0 then # 99清tmp table
	drop table if exists tmpProc01;
end if; # 99清tmp table

end; # begin