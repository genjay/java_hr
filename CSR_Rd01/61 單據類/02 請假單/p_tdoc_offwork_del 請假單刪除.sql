drop procedure if exists p_tdoc_offwork_del;

delimiter $$ 

create procedure p_tdoc_offwork_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_data      text # (rwid,...)  (1,5,14,20)
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare input_Cnt int;
declare in_Close_Date date;
declare in_strMsg text;
declare isCnt_NG int;
/*
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmpproc01;
    set outMsg='sql error';
    set err_code=1;
  end if;
END;  
*/
 /*
call p_tdoc_forget_del
(
'a715bb64-6a24-11e4-8bc2-000c29364755' #in_OUguid varchar(36)
,'' #,in_ltUser varchar(36)
,'' #,in_ltpid  varchar(36)  
,'(1,2,4,5,6,19,22,23,24)' #,in_data      text # (rwid,...)  (1,5,14,20)
,@a #,out outMsg   text # 回傳訊息
,@b #,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,@c #,out err_code int  # err_code
)  ;

select * from tmpProc01
*/
set err_code=0; set outRwid=0; set outMsg='p_tdoc_offwork_delxx 執行中';

insert into tlog_proc (ltpid,note) values 
('in_ouguid',in_ouguid)
,('in_data',in_data); 

if err_code=0 then # 20 將要刪除清單置入tmpProc01
	set in_data=replace(in_data,',','),(');
	drop table if exists tmpProc01;
	CREATE temporary TABLE tmpProc01 (
	rwid int(10) unsigned NOT NULL AUTO_INCREMENT,
	doc_rwid int,
#	OUguid   varchar(36),
    Emp_Guid varchar(36),
	dutydate date,
#	isCanDel int default 0,
    note text,
	PRIMARY KEY (rwid) 
	) ENGINE=Myisam DEFAULT CHARSET=utf8;
	set @sql=concat(
	'Insert into tmpProc01 (doc_rwid) values ',
	in_data,';');
    prepare s1 from @sql;
    execute s1;
end if;# 20 將要刪除清單置入tmpProc01


if err_code=0 && 1 then # 90

	delete From tdoc_offwork  
	Where exists (Select * from tmpProc01 x where tdoc_offwork.rwid=x.doc_rwid
	 and ifnull(x.note,'')='');

	set isCnt=0; 
    set isCnt_NG=0; 
	Select sum(if(note='',1,0)),sum(if(note='',0,1)) 
	into isCnt,isCnt_NG from tmpProc01;
	if isCnt>0 && isCnt_NG=0 then
	set outMsg=concat('刪除成功：',isCnt,'筆');
	else
	set outMsg=concat('刪除成功：',isCnt,',失敗：',isCnt_NG);
	end if;
end if; # 90

if 1 && err_code=0 then # 99 清除 tmp table 
	drop table if exists tmpproc01;
end if; # 99 清除 tmp table 

end; # begin