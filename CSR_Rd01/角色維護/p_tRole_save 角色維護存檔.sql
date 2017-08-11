drop procedure if exists p_tRole_save;

delimiter $$ 

create procedure p_tRole_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_Rwid      int  # 0 代表新增，大於 0 代表修改 
,in_Role_ID   varchar(36)
,in_Role_Desc varchar(36)
,in_data      text # 停用，給'',用來增加角色的成員用, (A00514,A02121,A02812)
,in_note      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare in_Role_Guid varchar(36);

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmpProc01;
    set outMsg='sql error';
    set err_code=1;
  end if;
END;   
 
set err_code=0; set outRwid=0; set outMsg='p_tRole_save 執行中';

insert into tlog_proc (ltpid,note) values
('in_Rwid',in_Rwid),
('in_Role_ID',in_Role_ID),
('in_Role_Desc',in_Role_Desc),
('in_note',in_note),
('in_data',in_data);

if err_code=0 && in_Role_ID='' then # 10
	set outMsg='角色代號不能空白';
	set err_code=1;
end if; # 10

if err_code=0 && in_Role_Desc='' then # 10
	set outMsg='角色名稱不能空白';
	set err_code=1;
end if; # 10

if err_code=0 then # 20 判斷是否存在其他相同資料
	set isCnt=0;
	Select rwid into isCnt 
	from tRole
	Where rwid!=in_Rwid
	  and OUguid =in_OUguid
	  and Role_id=in_Role_id limit 1;
	if isCnt>0 then set err_code=1; set outMsg='存在相同資料'; end if;
end if; # 20 判斷是否存在其他相同資料 

if err_code=0 && in_Rwid>0 then # 90
	update tRole set
	 role_id  =in_Role_ID
	,Role_Desc=in_Role_Desc
	,note     =in_note
	Where rwid=in_Rwid;
	set outMsg='修改完成';
end if; # 90 

if err_code=0 && in_Rwid=0 then # 90 新增
	set in_Role_Guid=uuid();
	insert into tRole 
	(ltUser,ltPid,Role_Guid,OUguid,Role_ID,Role_Desc,Note)
	values
	(in_ltUser,in_ltPid,in_Role_Guid,in_OUguid,in_Role_ID,in_Role_Desc,in_Note);
	set outMsg='新增完成';
end if;
 

end; # begin