drop procedure if exists p_tcard_type_save;

delimiter $$
# 刷卡機格式存檔
create procedure p_tcard_type_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_Rwid   int  # 0 代表新增，大於 0 代表修改 
,in_cardtype_id   varchar(36)
,in_cardtype_desc varchar(36)
,in_cardtype_rule varchar(36)
,in_stop_used     int
,in_note      text
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
    drop table if exists tmp01;
    drop table if exists tmp_Proc838a;
    set outMsg='格式錯誤';
    set err_code=1;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tOffDoc_save 執行中';

if err_code=0 then # 10
  set isCnt=0;
  Select rwid into isCnt from tcard_type 
  Where ouguid = in_OUguid And cardtype_id = in_cardtype_id And rwid != in_Rwid ;
  if isCnt > 0 then set err_code=1; set outMsg='已存在其他相同資料'; end if;
end if; # 10

 
if err_code=0 && in_stop_used=0 then # 20 將格式用,分開，要組Insert sql用
 set in_cardtype_rule=upper(in_cardtype_rule);
 set @in_cardtype_rule=in_cardtype_rule;
 set @in_cardtype_rule=replace(@in_cardtype_rule,'A','),("A",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'B','),("B",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'C','),("C",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'D','),("D",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'E','),("E",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'F','),("F",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'G','),("G",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'H','),("H",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'I','),("I",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'J','),("J",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'K','),("K",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'L','),("L",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'M','),("M",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'N','),("N",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'O','),("O",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'P','),("P",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'Q','),("Q",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'R','),("R",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'S','),("S",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'T','),("T",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'U','),("U",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'V','),("V",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'W','),("W",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'X','),("X",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'Y','),("Y",');
 set @in_cardtype_rule=replace(@in_cardtype_rule,'Z','),("Z",');
 set @in_cardtype_rule=concat(@in_cardtype_rule,')');
 set @in_cardtype_rule=substring(@in_cardtype_rule,3,9999);

insert into tlog_proc (note) values (@in_cardtype_rule);
	drop table if exists tmp_Proc838a;
	create /*temporary*/ table tmp_Proc838a 
	(rwid int NOT NULL auto_increment
	,cardtype varchar(36),str_lth int,
	PRIMARY KEY (`rwid`)) engine=myisam; 
	set @sql=concat('Insert into tmp_Proc838a (cardtype,str_lth) values'
	,@in_cardtype_rule,';');
insert into tlog_proc (note) values (@sql);
	prepare s1 from @sql;
	execute s1;
	DEALLOCATE PREPARE s1; 

set isCnt=0;
select count(*),concat(cardtype,' 不可重複')
into isCnt,outMsg
from tmp_Proc838a
Where not cardtype in ('I')
Group by cardtype
having count(*)>1 limit 1;

if isCnt>0 then set err_code=1; end if;  

end if; # 20  將格式用,分開，要組Insert sql用 
 
if err_code=0 && in_Rwid=0 then # 90 

  set outMsg='Insert ing...';
  insert into tcard_type
  (ouguid,cardtype_id,cardtype_desc,cardtype_rule,stop_used,note)
  select 
   in_ouguid,in_cardtype_id,in_cardtype_desc,in_cardtype_rule,in_stop_used,in_note;
  set outRwid=last_insert_id();
  set outMsg=concat(in_cardtype_id,' 新增完成');
end if; # 90 

if err_code=0 && in_Rwid>0 then # 90 
  set outMsg='update ing...';
  update tcard_type set
   cardtype_id   = in_cardtype_id
  ,cardtype_desc = in_cardtype_desc
  ,cardtype_rule = in_cardtype_rule
  ,stop_used     = in_stop_used
  ,note          = in_note
  where rwid =  in_Rwid;
  set outRwid = in_Rwid;
  set outMsg = concat(in_cardtype_id,' 修改完成');
end if; # 90 
 
end; # begin