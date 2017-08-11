drop procedure if exists p_tPid_Role_save ;

delimiter $$ 

create procedure p_tPid_Role_save 
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36) 
,in_Role_ID                   varchar(36)  
,in_data                      text # 傳入tPid_list_rwid (1,'+),(3,'-')...
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare in_Role_Guid varchar(36);
declare in_CntDel,in_CntAdd int;
/*
call p_tPid_Role_save 
(
'**common**' #in_OUguid                    varchar(36)
,'' #,in_LtUser                    varchar(36)
,'' #,in_ltPid                     varchar(36) 
,'A' #,in_Role_ID                   varchar(36)  
,"(1,'+'),(2,'+'),(3,'+')"  #,in_data                      text # 傳入tPid_list_rwid (1,'+),(3,'-')...
,@a,@b,@c
) ;

*/

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
('in_Role_ID',in_Role_ID),
('in_data',in_data);

set err_code=0; set outRwid=0; set outMsg='p_Pid_Role_save 執行中';

if err_code=0 then # 20 取得 Role_Guid
	set isCnt=0;
	Select Rwid,Role_Guid into isCnt,in_Role_guid
	from tRole 
	where OUguid=in_OUguid and Role_ID=in_Role_ID;
	if isCnt=0 then set err_code=1; set outMsg='角色錯誤'; end if;
end if; # 20 取得 Aid_Guid


if 1 && err_code=0 then # 21 將in_Data傳入tmpProc01
 
	drop table if exists tmpProc01;
	CREATE temporary TABLE tmpProc01 (
	rwid int(10) unsigned NOT NULL AUTO_INCREMENT,
	X_rwid    varchar(36),
	X_action  varchar(36),
	Pid_ID    varchar(36),
	note      varchar(36),
	PRIMARY KEY (rwid) 
	) ENGINE=Myisam DEFAULT CHARSET=utf8;
	set @sql=concat('Insert into tmpProc01 (X_rwid,X_action) values ',in_data,';');
	prepare s1 from @sql;
	execute s1;
	alter table tmpProc01 add index i01 (X_rwid,x_action);
 
end if; # 21 將in_Data傳入tmpProc01

if err_code=0 then # 22 補上pid_id
	update tmpProc01 a,tpid_list b
	set a.pid_ID=b.pid_ID,a.note='OK_Add'
	Where a.x_action='+' and a.x_rwid=b.rwid;
	update tmpProc01 a,tpid_role b
	set a.note='NG_exists'
	Where b.Role_guid=in_Role_guid and a.pid_ID=b.pid_ID;
end if; # 22 補上pid_id

if err_code=0 then # 23
	update tmpProc01 a,tpid_list b
	set a.note='OK_Del'
	Where a.x_action='-' and a.x_rwid=b.rwid;
end if; # 23

if err_code=0 then # 90 新增
	Insert into tpid_Role (Role_Guid,Pid_ID) 
	Select in_Role_Guid,Pid_ID from tmpProc01 x
	Where x.x_action='+' and x.note='OK_Add';

end if; # 90 新增

if err_code=0 then # 90 新增
	Delete tpid_Role 
	from tpid_Role,tmpProc01 b
	where tpid_Role.rwid=b.X_rwid and b.note='OK_Del';

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

if 1 && err_code=0 then # 99清tmp table
	drop table if exists tmpProc01;
end if; # 99清tmp table



end; # begin