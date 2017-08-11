drop procedure if exists p_to_tCardtime;

delimiter $$ 

create procedure p_to_tCardtime
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_cardtype_id varchar(36) # 卡鐘格式
,in_tblName   text # table_name
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare time_start datetime;
declare isCnt int;
declare run_i int default 1;
declare in_cardtype_rule varchar(36); 
declare All_cnt int; # 上傳總筆數
declare Ok_cnt int; # 成功筆數
/*
declare A_str_st,A_str_lth int;
declare Y_str_st,Y_str_lth int;
declare M_str_st,M_str_lth int;
declare D_str_st,D_str_lth int;
declare H_str_st,H_str_lth int;
declare E_str_st,E_str_lth int;
declare S_str_st,S_str_lth int;
*/

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp_Proc01;
    set outMsg='sql error';
    set err_code=1;
  end if;
END;   

set time_start=now();
set isCnt=0;
set err_code=0;
set outMsg='p_to_tCardtime 執行中';

insert into tlog_proc (note) values (in_tblName);
 

if err_code=0 then # 10
 Select rwid,cardtype_rule into isCnt,in_cardtype_rule
 from tcard_type
 Where OUguid=in_OUguid and cardtype_id=in_cardtype_id;
 if isCnt=0 then set err_code=1; set outMsg='格式選擇錯誤'; end if;
end if; # 10 

if err_code=0 then # 20 將格式用,分開，要組Insert sql用
 set @in_cardtype_rule=replace(in_cardtype_rule,'A','),("A",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'Y','),("Y",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'M','),("M",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'D','),("D",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'H','),("H",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'E','),("E",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'S','),("S",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'I','),("I",');
 set @in_cardtype_rule=concat(@in_cardtype_rule,')');
 set @in_cardtype_rule=substring(@in_cardtype_rule,3,9999);
end if; # 20  將格式用,分開，要組Insert sql用

if err_code=0 then # 21 用table及sql來轉換rule格式

	drop table if exists tmp_Proc838a;
	create temporary table tmp_Proc838a 
	(rwid int NOT NULL auto_increment
	,cardtype varchar(36),str_lth int,
	PRIMARY KEY (`rwid`)) engine=myisam; 
	set @sql=concat('Insert into tmp_Proc838a (cardtype,str_lth) values'
	,@in_cardtype_rule,';');

	prepare s1 from @sql;
	execute s1;
	drop table if exists tmp_Proc838b;
	create temporary table tmp_Proc838b engine=myisam select * from tmp_Proc838a;

	drop table if exists tmp_Proc838C;
	create temporary table tmp_Proc838C engine=myisam 
	select a.rwid,a.cardtype,a.str_lth
	,(select ifnull(sum(str_lth),0) from tmp_Proc838b b where b.rwid<a.rwid)+1 str_st
	from tmp_Proc838a a
	;

	select str_st,str_lth into @A_str_st,@A_str_lth from tmp_Proc838c a where a.cardtype ='A';
	select str_st,str_lth into @Y_str_st,@Y_str_lth from tmp_Proc838c a where a.cardtype ='Y';
	select str_st,str_lth into @M_str_st,@M_str_lth from tmp_Proc838c a where a.cardtype ='M';
	select str_st,str_lth into @D_str_st,@D_str_lth from tmp_Proc838c a where a.cardtype ='D';
	select str_st,str_lth into @H_str_st,@H_str_lth from tmp_Proc838c a where a.cardtype ='H';
	select str_st,str_lth into @E_str_st,@E_str_lth from tmp_Proc838c a where a.cardtype ='E';
	select str_st,str_lth into @S_str_st,@S_str_lth from tmp_Proc838c a where a.cardtype ='S'; 
end if; # 20 

if err_code=0 then # 21 取得上傳總筆數
set @sql=concat("Select count(*) into @isCnt from ",in_tblName,";");
prepare s1 from @sql;
execute s1;
set All_cnt=@isCnt;
end if; 

if err_code=0 then # 判斷符合日期格式資料筆數，不等於0，才往下跑
set @sql=concat(" 
select count(*) into @isCnt from ",in_tblName,"
where str_to_date(concat(
 substring(in_data,@Y_str_st,@Y_str_lth)
,substring(in_data,@M_str_st,@M_str_lth)
,substring(in_data,@D_str_st,@D_str_lth)
,substring(in_data,@H_str_st,@H_str_lth)
,substring(in_data,@E_str_st,@E_str_lth)
,substring(in_data,@S_str_st,@S_str_lth))
,'%Y%m%d%H%i%s') is not null;");
prepare s1 from @sql;
execute s1;
if @isCnt=0 then set err_code=1; set outMsg='無符合資料'; end if;
end if;


if err_code=0 then # 若無半筆資料，以下程式會掛點
drop table if exists tmp_Proc838d;
set @sql=concat("
create temporary table tmp_Proc838d engine=myisam
select rwid from ",in_tblName,"
where str_to_date(concat(
 substring(in_data,@Y_str_st,@Y_str_lth)
,substring(in_data,@M_str_st,@M_str_lth)
,substring(in_data,@D_str_st,@D_str_lth)
,substring(in_data,@H_str_st,@H_str_lth)
,substring(in_data,@E_str_st,@E_str_lth)
,substring(in_data,@S_str_st,@S_str_lth))
,'%Y%m%d%H%i%s') is not null;");
prepare s1 from @sql;
execute s1;
alter table tmp_Proc838d add index (rwid);

drop table if exists tmp_Proc898;
set @sql=concat("
create temporary table tmp_Proc898 engine=myisam
Select rwid,in_data,substring(in_data,@A_str_st,@A_str_lth) cardno
,str_to_date(concat(
 substring(in_data,@Y_str_st,@Y_str_lth)
,substring(in_data,@M_str_st,@M_str_lth)
,substring(in_data,@D_str_st,@D_str_lth)
,substring(in_data,@H_str_st,@H_str_lth)
,substring(in_data,@E_str_st,@E_str_lth)
,substring(in_data,@S_str_st,@S_str_lth))
,'%Y%m%d%H%i%s') dTime
from ",in_tblName,"
where  
rwid in (select rwid from tmp_Proc838d);");
prepare s1 from @sql;
execute s1;

end if; 

if err_code=0 && 1 then
	Select count(*) into OK_cnt from tmp_Proc898
	where dtime !='0000-00-00 00:00:00';

	insert into tcardtime (OUguid,cardno,dtcardtime)
	select in_OUguid,cardno,dTime 
	from tmp_Proc898
	where dtime !='0000-00-00 00:00:00'
	Group by cardno,dTime; 
	set outMsg=concat('匯入完成 筆數：',OK_cnt);
end if;

if err_code=0 then # 99 清除 tmp_Proc table 
 drop table if exists tmp_Proc838a;
 drop table if exists tmp_Proc838b;
 drop table if exists tmp_Proc838c;
 drop table if exists tmp_Proc838d;
 drop table if exists tmp_Proc898;
 end if; # 99 清除 tmp_Proc table
  
end; # begin