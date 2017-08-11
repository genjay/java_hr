drop procedure if exists p_tRole_member_save;

delimiter $$ 

create procedure p_tRole_member_save
(
 in_OUguid    varchar(36)
,in_ltUser    varchar(36)
,in_ltpid     varchar(36) /*程式代號*/ 
,in_Role_ID   varchar(36) 
,in_data      text # 用來增加角色的成員用,taccount_ou.rwid '(1,'+'),(2,'+'),(3,'-'),(4,'-')'
,in_note      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare in_Role_Guid varchar(36);
declare in_CntDel,in_CntAdd int;

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table 
    set outMsg='sql error';
    set err_code=1;
  end if;
END;   
/*
call p_tRole_member_save
(
'**common**' #in_OUguid varchar(36)
,'' #,in_ltUser varchar(36)
,'' #,in_ltpid  varchar(36) #程式代號 
,'A' #,in_Role_ID   varchar(36) 
,"(1,'+'),(2,'+'),(3,'-'),(4,'-')" #,in_data      text # 用來增加角色的成員用,rwid (122,+,123,-,144,-)
,'' #,in_note      text
,@a,@b,@c
)  ;
*/
 
set err_code=0; set outRwid=0; set outMsg='p_tRole_member_save 執行中';
insert into tlog_proc (ltpid,note) values
('in_Role_ID',in_Role_ID),
('in_data',in_data);

if err_code=0 then # 20 取得 Role_Guid
	set isCnt=0;
	Select Rwid,Role_Guid into isCnt,in_Role_Guid
	from tRole
	where OUguid=in_OUguid and Role_ID=in_Role_ID;
	if isCnt=0 then set err_code=1; set outMsg='角色ID錯誤'; end if;
end if; # 20 取得 Role_Guid
 
 
if 1 && err_code=0 then # 21 角色成員部份
 
	drop table if exists tmpProc01;
	CREATE temporary TABLE tmpProc01 (
	rwid int(10) unsigned NOT NULL AUTO_INCREMENT,
	X_rwid    varchar(36),
	X_action  varchar(36),
	Aid_Guid  varchar(36),
	note varchar(36),
	PRIMARY KEY (rwid) 
	) ENGINE=Myisam DEFAULT CHARSET=utf8;
	set @sql=concat('Insert into tmpProc01 (X_rwid,X_action) values ',in_data,';');
	prepare s1 from @sql;
	execute s1;
	alter table tmpProc01 add index i01 (X_rwid,x_action);
 
end if; # # 21 角色成員部份

if err_code=0 then # 22 取得Aid_guid
	# OUguid =in_OUguid 才做更新
	update tmpproc01 a,taccount_ou b set
	a.Aid_Guid=b.Aid_Guid,a.note='OK_Add'
	where b.OUguid=in_OUguid 
	  And a.X_rwid=b.rwid;
	update tmpProc01 a,tRole_member b
	set a.note='NG_exists'
	where a.x_action='+' and b.Role_Guid=in_Role_Guid and a.Aid_Guid=b.Aid_Guid;

end if; # 22 取得Aid_guid

if err_code=0 then # 23 判斷能否刪除
	update tmpProc01 a,tRole_member b,tRole c
	set a.note='OK_Del'
	where b.Role_Guid=c.Role_Guid and c.OUguid=in_OUguid
	and a.x_action='-' and a.x_rwid=b.rwid ;
end if; # 23 判斷能否刪除

if err_code=0 then # 90 將Aid_Guid 加入tRole_member
	insert into tRole_member (Role_Guid,Aid_Guid)
	select in_Role_Guid,a.Aid_Guid from tmpproc01 a
	Where  ifnull(a.Aid_Guid,'')!='' and a.x_action='+' and a.note='OK_Add';
	set outMsg='修改完成';
end if; # 90 將Aid_Guid 加入tRole_member

if err_code=0 then # 90 刪除 tRole_member
# sql 不優，改下列方式
#	Delete from tRole_member 
#	Where exists (select * from tmpproc01 x where x_action='-' and tRole_member.rwid=X_rwid);
	
	delete tRole_member
	from tRole_member ,tmpproc01 b
	where tRole_member.rwid=b.X_rwid and b.x_action='-' and b.note='OK_Del' ;
	set outMsg='修改完成';
end if; # 90 將Aid_Guid 加入tRole_member

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

if err_code=0 then # 99 清tmp table
	drop table if exists tmpProc01;
end if; # 99 清tmp table

end; # begin