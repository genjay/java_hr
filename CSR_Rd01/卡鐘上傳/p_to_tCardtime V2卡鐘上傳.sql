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
declare getNow datetime default now();
declare isCnt int;
declare in_cardtype_rule varchar(36); 
declare All_cnt int; # 上傳總筆數
declare Ok_cnt int; # 成功筆數

set err_code=0;

insert into tlog_proc (note) values (concat(ltUser,',',ltPid));

if err_code=0 && 0 then # 00 (非必要)建立一個跟來源一樣的tmp table
 drop table if exists tmp78;
 set @sql=concat("create table tmp78 "
	,"select * from ",in_tblName,";");
 prepare s1 from @sql;
 execute s1;
insert into tlog_proc (note) values (@sql);
end if; # 00 


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
	create /*temporary*/ table tmp_Proc838a 
	(rwid int NOT NULL auto_increment
	,cardtype varchar(36),str_lth int,
	PRIMARY KEY (`rwid`)) engine=myisam; 
	set @sql=concat('Insert into tmp_Proc838a (cardtype,str_lth) values'
	,@in_cardtype_rule,';');

	prepare s1 from @sql;
	execute s1;
	drop table if exists tmp_Proc838b;
	create /*temporary*/ table tmp_Proc838b engine=myisam select * from tmp_Proc838a;

	drop table if exists tmp_Proc838C;
	create /*temporary*/ table tmp_Proc838C engine=myisam 
	select a.rwid,a.cardtype,a.str_lth
	,(select ifnull(sum(str_lth),0) from tmp_Proc838b b where b.rwid<a.rwid)+1 str_st
	from tmp_Proc838a a
	;
	set @Y_str_st=0; set @Y_str_lth=0;
	set @M_str_st=0; set @M_str_lth=0;
	set @D_str_st=0; set @D_str_lth=0;
	set @H_str_st=0; set @H_str_lth=0;
	set @E_str_st=0; set @E_str_lth=0;
	set @S_str_st=0; set @S_str_lth=0;


	select str_st,str_lth into @A_str_st,@A_str_lth from tmp_Proc838c a where a.cardtype ='A';
	select str_st,str_lth into @Y_str_st,@Y_str_lth from tmp_Proc838c a where a.cardtype ='Y';
	select str_st,str_lth into @M_str_st,@M_str_lth from tmp_Proc838c a where a.cardtype ='M';
	select str_st,str_lth into @D_str_st,@D_str_lth from tmp_Proc838c a where a.cardtype ='D';
	select str_st,str_lth into @H_str_st,@H_str_lth from tmp_Proc838c a where a.cardtype ='H';
	select str_st,str_lth into @E_str_st,@E_str_lth from tmp_Proc838c a where a.cardtype ='E';
	select str_st,str_lth into @S_str_st,@S_str_lth from tmp_Proc838c a where a.cardtype ='S'; 
    select sum(str_lth) into   @All_lth from tmp_Proc838c a ;
end if; # 21 用table及sql來轉換rule格式


if err_code=0 then # 22 取得上傳總筆數
	set @sql=concat("Select count(*) into @isCnt from ",in_tblName,";");
	prepare s1 from @sql;
	execute s1;
	set All_cnt=@isCnt;
end if; # 22 取得上傳總筆數

if err_code=0 then # 23 判斷每行長度，及日期需數字
drop table if exists tmp_Proc838d;
set @sql=concat("
create table tmp_Proc838d engine=myisam
 Select rwid,in_data
 ,Case 
  When length(in_data)<@All_lth then '長度不足'
  When not substring(in_data,@Y_str_st,@Y_str_lth) REGEXP '^[0-9]*$' then '年有非數字'
  When not substring(in_data,@Y_str_st,@Y_str_lth) between 0 and 9999 then '年不在0-9999'
  When not substring(in_data,@M_str_st,@M_str_lth) REGEXP '^[0-9]*$' then '月有非數字'
  When not substring(in_data,@M_str_st,@M_str_lth) between 1 and 12  then '月不在1-12'
  When not substring(in_data,@D_str_st,@D_str_lth) REGEXP '^[0-9]*$' then '日有非數字'
  When not substring(in_data,@D_str_st,@D_str_lth) between 1 and 31  then '日不在1-31'
  When not substring(in_data,@H_str_st,@H_str_lth) REGEXP '^[0-9]*$' then '時有非數字'
  When not substring(in_data,@H_str_st,@H_str_lth) between 0 and 23  then '時不在0-23'
  When not substring(in_data,@E_str_st,@E_str_lth) REGEXP '^[0-9]*$' then '分有非數字'
  When not substring(in_data,@E_str_st,@E_str_lth) between 0 and 59  then '分不在0-59'
  When not substring(in_data,@S_str_st,@S_str_lth) REGEXP '^[0-9]*$' then '秒有非數字'
  When not substring(in_data,@S_str_st,@S_str_lth) between 0 and 59  then '秒不在0-59'
  else '0' # 無錯誤
  end err_msg
 from ",in_tblName,";");
 prepare s1 from @sql;
 execute s1;
end if; # 23 

if err_code=0 then # 90 新增至 tcardtime
set isCnt=0;
Select count(*) into isCnt from tmp_Proc838d where err_msg='0';

drop table if exists tmp_Proc838e;
create table tmp_Proc838e engine=myisam
select  distinct 
 substring(in_data,@A_str_st,@A_str_lth) cardno
,str_to_date(concat(
 substring(in_data,@Y_str_st,@Y_str_lth)
,substring(in_data,@M_str_st,@M_str_lth)
,substring(in_data,@D_str_st,@D_str_lth)
,substring(in_data,@H_str_st,@H_str_lth)
,substring(in_data,@E_str_st,@E_str_lth)
,substring(in_data,@S_str_st,@S_str_lth))
,'%Y%m%d%H%i%s') dTime
from tmp_Proc838d 
where err_msg='0';
 
insert into tcardtime  (ltUser,ltPid,OUguid,cardno,dtcardtime)
select in_ltUser,in_ltPid,in_OUguid,cardno,dTime
from tmp_Proc838e b
where not exists (select * from tcardtime x where x.OUguid=in_OUguid
 and x.cardno=b.cardno and x.dtcardtime=b.dTime); 

set outMsg=concat('匯入',All_cnt,'行',',成功',isCnt,', ',f_timediff(now(),getNow));
end if; # 90  新增至 tcardtime

if err_code=0 && 0 then # 99 清除 tmp table 
 drop table if exists tmp_proc838a;
 drop table if exists tmp_proc838b;
 drop table if exists tmp_proc838c;
 drop table if exists tmp_proc838d;
 drop table if exists tmp_proc838e;
end if; # 99 清除 tmp table
  
end; # begin