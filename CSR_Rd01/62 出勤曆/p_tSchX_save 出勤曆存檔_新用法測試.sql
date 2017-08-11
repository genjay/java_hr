drop procedure if exists p_tSchX_save;

delimiter $$ 

create procedure p_tSchX_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_X_type    text # Emp 或 Dep
,in_Dep_ID    text # PK 值, 傳emp_id或Dep_id
,in_Col       text # 欄位名稱，需與in_Data 序列一致
,in_Data      text # (日期、假日、班別)，EX ('20150101','0','A'),('20150102','1','B')...
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare in_Dep_Guid varchar(36);
declare in_Emp_Guid varchar(36);
declare in_Worktype_Guid varchar(36);


/*
call p_tSchX_save
(
'**common**','',''
,'Dep' # ,in_X_type    text # Emp 或 Dep
,'100'
,'Caldate,holiday,worktype_id' #,in_Col       text # 欄位名稱，需與in_Data 序列一致
,"('2015-02-01','1','A'),('2015-02-02','0','A'),('2015-02-03','0','A'),('2015-02-04','0','A'),('2015-02-05','0','A'),('2015-02-06','0','A'),('2015-02-07','1','A'),('2015-02-08','1','A'),('2015-02-09','0','A'),('2015-02-10','0','A'),('2015-02-11','0','A'),('2015-02-12','0','A'),('2015-02-13','0','A'),('2015-02-14','1','A'),('2015-02-15','1','A'),('2015-02-16','0','A'),('2015-02-17','0','A'),('2015-02-18','0','A'),('2015-02-19','0','A'),('2015-02-20','0','A'),('2015-02-21','1','A'),('2015-02-22','1','A'),('2015-02-23','0','A'),('2015-02-24','0','A'),('2015-02-25','0','A'),('2015-02-26','0','A'),('2015-02-27','0','A'),('2015-02-28','1','A')" 
 # ",in_Data      text # (日期、假日、班別)，EX ('20150101','0','A'),('20150102','1','B')...
,@a,@b,@c
)  ;
*/
/*
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
    set outMsg='sql error';
    set err_code=1;
  end if;
END;  
*/
 
set err_code=0; set outRwid=0; set outMsg='p_tSchX_save 執行中';

insert into tlog_proc (ltpid,note) values 
 ('in_X_type',in_X_type)
,('in_Col',in_Col)
,('in_Data',in_Data);

set in_Data=replace(in_Data,'/','-'); # 日期格式統一改成用 - 分隔

if err_code=0 && in_X_type='Dep' then # 09 抓dep_guid
 set isCnt=0;
 Select rwid,dep_guid into isCnt,in_Dep_Guid
 from tdept 
 Where OUguid=in_OUguid and dep_id=in_Dep_id;
 if isCnt=0 then set err_code=1; set outMsg='in_Dep_Guid 錯誤'; end if;
end if; # 09

if err_code=0 && in_X_type='Emp' then # 09 抓Emp_guid
 set isCnt=0;
 Select rwid,Emp_guid into isCnt,in_Emp_Guid
 from tperson 
 Where OUguid=in_OUguid and emp_id=in_Dep_id;
 if isCnt=0 then set err_code=1; set outMsg='in_Emp_Guid 錯誤'; end if;
end if; # 09

if err_code=0 then # 10 產生tmp01
 drop table if exists tmp01;
 set @sql=concat("create temporary table tmp01 ("
 ,replace(in_Col,","," varchar(4000),")
 ," varchar(4000)"
 ," ,worktype_guid varchar(36),std_on datetime,std_off datetime) engine=myisam;"
 );
 prepare s1 from @sql;
 execute s1;
ALTER TABLE tmp01 
CHANGE COLUMN `caldate` `caldate` date NULL  
,add index i01 (caldate);
 
end if;

if err_code=0  then # 20 insert into tmp01
 set @sql=concat("Insert into tmp01 (",in_Col
 ,") values "
 ,in_Data
 ,";"
 );
 prepare s1 from @sql;
 execute s1; 

 update tmp01 a,tworktype b 
 set a.CalDate=date_format(caldate,'%Y-%m-%d'),
     a.worktype_guid=b.worktype_guid,
	 a.std_on =(str_to_date(concat(a.CalDate,' ', b.OnDutyHHMM),
                '%Y-%m-%d %H:%i:%s') + interval b.OnNext_Z04 day) ,
     a.std_off=(str_to_date(concat(a.CalDate,' ', b.OffDutyHHMM),
                '%Y-%m-%d %H:%i:%s') + interval b.OffNext_Z04 day) 
 Where b.OUguid=in_OUguid and a.worktype_id=b.worktype_id;
end if; # 20

if err_code=0 then # 30 判斷是否出現上班時間重疊
 set isCnt=0;
 drop table if exists tmp02;
 create temporary table tmp02 select * from tmp01;
 # 因下方sql，用不到tmp02.caldate的index，所以tmp02，不要建index 
 select count(*),
 Group_concat(concat(a.caldate,'與',b.caldate,' 時間重疊\n'))
 into isCnt,outMsg
 from tmp01 a
 left join tmp02 b on a.caldate= (b.caldate -interval 1 day) 
 Where b.Std_on<a.Std_off;

 if isCnt>0 then set err_code=1;  end if; 
end if; 
 
if err_code=0 && in_X_type='Dep' then
Insert into tsch_dep 
       (Dep_guid,dutydate,holiday,worktype_guid)
select in_Dep_guid,a.caldate,a.holiday,a.worktype_guid
from tmp01 a
where not exists (select * from vtsch_dep x /*與標準不同時才新增修改*/
 where a.caldate=x.caldate and x.dep_id=in_Dep_id 
   and a.holiday=x.holiday and a.worktype_id=x.worktype_id)
on duplicate key update
 holiday=a.holiday
,WorkType_Guid=a.WorkType_Guid;
set outMsg='修改完成';
end if; 

if err_code=0 && in_X_type='Emp' then
Insert into tsch_emp
       (Emp_guid,dutydate,holiday,worktype_guid)
select in_Emp_guid,a.caldate,a.holiday,a.worktype_guid
from tmp01 a
where not exists (select * from vtsch_emp x /*與標準不同時才新增修改*/
 where a.caldate=x.caldate and x.emp_id=in_Dep_id 
   and a.holiday=x.holiday and a.worktype_id=x.worktype_id)
on duplicate key update
 holiday=a.holiday
,WorkType_Guid=a.WorkType_Guid;
set outMsg='修改完成';
end if;

if err_code=0 then # 99 
 drop table if exists tmp02;
 drop table if exists tmp01; 
end if; # 99

end; # begin