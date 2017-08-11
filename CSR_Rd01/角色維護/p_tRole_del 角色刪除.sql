drop procedure if exists p_tRole_del;

delimiter $$ 

create procedure p_tRole_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_data      text # 傳入欲刪除的rwid,ex：(2,4,9,55,88)
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmpProc01;
    set outMsg='sql error';
    set err_code=1;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_demo 執行中';

insert into tlog_proc (note) values (in_data);
 
if err_code=0 then # 20 將要刪除清單置入tmpProc01
	set in_data=replace(in_data,',','),(');
	drop table if exists tmpProc01;
	CREATE temporary TABLE tmpProc01 (
	rwid int(10) unsigned NOT NULL AUTO_INCREMENT,
	doc_rwid int, 
	Role_id  varchar(36),
	note varchar(4000) default '',
	PRIMARY KEY (rwid) 
	) ENGINE=Myisam DEFAULT CHARSET=utf8;
	set @sql=concat(
	'Insert into tmpProc01 (doc_rwid) values ',
	in_data,';');
    prepare s1 from @sql;
    execute s1;
end if;# 20 將要刪除清單置入tmpProc01

if err_code=0 then # 21 判斷能不能刪除
	update tmpProc01 a,
	( Select X1.rwid,X1.OUguid,X1.Role_id
	,(select count(*) from trole_member x2 where x1.Role_guid=x2.Role_guid) Cnt
	from tRole x1 where x1.OUguid=in_OUguid) b
	set a.note=Case 
	When b.cnt>0 then '請先刪除角色成員'
	When OUguid!=in_OUguid then '不屬於該OU'
	Else 'OK_Del'
	end 
	,a.Role_id=b.Role_id
	where a.doc_rwid=b.rwid;
end if; # 21 判斷能不能刪除

if err_code=0 then # 30 判斷是否有無能刪除資料
	Select count(*),group_concat(concat('「',Role_ID,'」',Note))
	into isCnt,outMsg from tmpProc01 Where note='OK_Del';
	if isCnt=0 then 
		set err_code=1;
		Select group_concat(concat('「',Role_ID,'」',Note))
		into outMsg from tmpProc01 Where note!='OK_Del';
	end if;
end if;# 30 判斷是否有無能刪除資料

if err_code=0 then # 90 
	Select concat('「',group_concat(Role_ID),'」','刪除完成')
	into outMsg from tmpProc01 Where note='OK_Del';

	Delete from tRole 
	Where rwid in (select doc_rwid from tmpProc01 Where note='OK_Del');

end if; # 90

if err_code=0 then # 99
	drop table if exists tmpProc01;
end if; # 99

end