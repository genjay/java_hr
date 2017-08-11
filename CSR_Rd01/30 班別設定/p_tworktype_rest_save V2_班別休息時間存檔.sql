drop procedure if exists p_tworktype_rest_save;

delimiter $$ 

create procedure p_tworktype_rest_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36) 
,in_worktype_ID               varchar(36)
,in_Holiday                   tinyint(4)
,in_Data                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
,out errMsg   text # 錯誤回傳用 (行號，錯誤原因),(行號，錯誤原因)...
)  

begin
declare isCnt int;  
declare in_worktype_Guid varchar(36); 

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    -- drop table if exists tmp01;
    set @xx=0;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tworktype_rest_save 執行中';

insert into tlog_proc (note) values 
 (concat('in_worktype_ID: ',in_worktype_ID))
,(concat('in_Holiday: ',in_Holiday))
,(concat('in_Data: ',in_Data));

if err_code=0 then # 10
 set isCnt=0;
 Select rwid,worktype_guid into isCnt,in_worktype_guid
 from tworktype
 Where OUguid=in_OUguid And worktype_ID=in_worktype_ID;
 if isCnt=0 then set err_code=1; set outMsg='班別有誤'; end if;
end if; # 10

if err_code=0 then # 20
 drop table if exists tmp01;
create temporary table tmp01 
 (
  lnid int(11) NOT NULL AUTO_INCREMENT,
  rwid int,rest_stHHMM varchar(36),rest_time varchar(36)
 ,cuttime varchar(36),note text
,  PRIMARY KEY (`lnid`));

  set @sql=concat('Insert into tmp01 
   (rwid,rest_stHHMM,rest_time,cuttime,note) '
   ,' values '
   ,in_Data,';');
  insert into tlog_proc (note) values (@sql);
  prepare s1 from @sql;
  execute s1;
 update tmp01 # 
 set rest_stHHMM=if(rest_stHHMM='','',str_to_date(replace(rest_stHHMM,':',''),'%H%i'))
 # rest_stHHMM 若等於null，代表時間格式有誤
 Where 1=1;
end if;

if err_code=0 then # 30 判斷時間是否重疊 
drop table if exists tmp02_a;
drop table if exists tmp02_b;

create temporary table tmp02_a
select lnid,rwid,rest_stHHMM,
str_to_date(concat(date(sysdate()),' ',rest_stHHMM),'%Y-%m-%d %T') rest_St
,str_to_date(concat(date(sysdate()),' ',rest_stHHMM),'%Y-%m-%d %T')
+interval rest_time minute rest_To
from tmp01 a
where rest_stHHMM!='';

create temporary table tmp02_b select * from tmp02_a;

drop table if exists tmp03; 

create temporary table tmp03   
select a.*
,(select b.lnid from tmp02_b b where a.rwid!=b.rwid
  and a.rest_St <=b.rest_To and a.rest_to > b.rest_st) dup_lnid
from tmp02_a a ;

set isCnt=0; 

select count(*)
,group_concat(concat(lnid,',與 ',dup_lnid,' 重疊') order by lnid,dup_lnid)
,group_concat(concat('(',lnid,',與 ',dup_lnid,' 重疊',')') order by lnid,dup_lnid)
into isCnt,errMsg,outMsg
from tmp03 
where dup_lnid>0
order by lnid
;
-- set outMsg=errMsg;
if isCnt>0 then set err_code=1; end if;
end if; # 30

if err_code=0 then # 90 修改資料 tworktype_rest

 delete from tworktype_rest  
 where rwid in (select rwid from tmp01 where rest_stHHMM='');
update tworktype_rest a,tmp01 b
 set
 a.rest_stHHMM=b.rest_stHHMM,
 a.rest_time=b.rest_time,
 a.cuttime=if(b.cuttime='1',b'1',b'0'),
 a.note=b.note
 where a.rwid=b.rwid and b.rwid>0; 
insert into tworktype_rest 
(ltUser,ltPid,worktype_guid,holiday,rest_stHHMM,rest_time
,cuttime,note)
select
in_LtUser,in_ltPid,in_worktype_guid,in_Holiday,rest_stHHMM,rest_time
,if(cuttime='1',b'1',b'0'),note
from tmp01
where rwid=0;
#------------
	if in_Holiday='1' then # 假日/平日
	 set outMsg='假日_修改完成';
	else 
	 set outMsg='平日_修改完成'; 
	end if; # 假日/平日
end if; # 90

if err_code=0 && in_holiday=0 then # 91 非必要，修改平日時
 # 修改平日後，若假日為空，複至一份，方便修改
 set isCnt=0; 
 Select count(*) into isCnt from tworktype_rest 
 where holiday=1 and WorkType_Guid=in_WorkType_Guid ;
 if isCnt=0 then # 91-1
	insert into tworktype_rest 
	(ltUser,ltPid,worktype_guid,holiday,rest_stHHMM,rest_time
	,cuttime,note)
	select
	in_LtUser,in_ltPid,in_worktype_guid,'1',rest_stHHMM,rest_time
	,if(cuttime='1',b'1',b'0'),note
	from tmp01
	where 1=1;
 end if;# 91-1
end if; # 91

if err_code=0 then # 99 清除 tmp table 
 drop table if exists tmp01;
 drop table if exists tmp02_a;
 drop table if exists tmp02_b;
 drop table if exists tmp03;
 end if; # 99 清除 tmp table
 
end; # begin