drop procedure if exists p_tAccount_OU_del;

delimiter $$ 

create procedure p_tAccount_OU_del
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36) 
,in_data                      text # 傳入欲刪除的rwid,ex：(2,4,9,55,88)
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare isStopCnt,isDelCnt int;

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
    set outMsg='sql error';
    set err_code=1;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tAccount_OU_del 執行中';

insert into tlog_proc (note) values (in_data);
 
if err_code=0 then # 20 將要刪除清單置入tmpProc01
	set in_data=replace(in_data,',','),(');
	drop table if exists tmpProc01;
	CREATE temporary TABLE tmpProc01 (
	rwid int(10) unsigned NOT NULL AUTO_INCREMENT,
	doc_rwid int, 
	Aid  varchar(36),
	Aid_Guid varchar(36),
	X_action varchar(36),
	note varchar(200) default '',
	PRIMARY KEY (rwid) 
	) ENGINE=Myisam DEFAULT CHARSET=utf8;
	set @sql=concat(
	'Insert into tmpProc01 (doc_rwid) values ',
	in_data,';');
    prepare s1 from @sql;
    execute s1; 
end if;# 20 將要刪除清單置入tmpProc01

if err_code=0 then # 21 將屬於該ou的補上Aid及OK_del
	update tmpProc01 a,taccount b ,taccount_ou c
	set a.aid=b.aid,a.X_action='OK_Del',a.aid_guid=b.aid_guid
	Where a.doc_rwid=c.rwid and b.Aid_Guid=c.Aid_guid and c.OUguid=in_OUguid;
end if;# 21 將屬於該ou的補上Aid及OK_del


if err_code=0 then # 22 將自己的帳號，補上不可刪除
	update tmpProc01 a,taccount b  
	set a.note='不能刪除自己',a.X_action='NG'
	Where a.Aid=b.Aid and b.Aid_guid=in_LtUser;
end if;# 22 將自己的帳號，補上不可刪除


if err_code=0 then #23 trole_member
	update tmpProc01 a,trole_member b  
	set a.note='trole_member已使用',a.X_action='OK_stop'
	Where a.Aid_guid=b.Aid_guid;
end if;  #23 trole_member

if 1 && err_code=0 then # isStopCnt,isDelCnt
	Select count(*) into isDelCnt from tmpProc01 a
	where a.X_action='OK_Del';
	Select count(*) into isStopCnt from tmpProc01 a
	where a.X_action='OK_stop';
	set outMsg=concat('停用 ',isStopCnt,'筆',',刪除 ',isDelCnt,'筆');
end if;

if 1 && err_code=0 then # 90 刪除帳號
	Delete tAccount 
	from tAccount,tmpProc01 b
	Where b.X_action='OK_Del' and tAccount.Aid_Guid=b.Aid_Guid;

	Delete tAccount_ou
	from tAccount_ou ,tmpProc01 b
	Where b.X_action='OK_Del' and tAccount_ou.rwid=b.doc_rwid;

	update tAccount_ou a,tmpProc01 b set # 除了自己以外停用
	a.stop_used=b'1'
	where  b.X_action='OK_stop' 
	and a.rwid=b.doc_rwid and a.Aid_Guid!=in_ltUser;

end if;# 90 刪除帳號

if err_code=0 then # 99 清tmp table
	drop table if exists tmpProc01;
end if;# 99 清tmp table



end; # begin