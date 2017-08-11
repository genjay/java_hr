drop procedure if exists p_tOUset_calendar_save;

delimiter $$ 

create procedure p_tOUset_calendar_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/ 
,in_data      text # 格式 (2014-01-01,0),(2014-01-02,1)...
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
    set outMsg='程式發生SQL error';
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tOUset_calendar_save 執行中';

if err_code=0 then # 將資料放至 tmp01 table
drop table if exists tmp01;
create temporary table tmp01 (caldate date,holiday int);

set @sql=concat('Insert into tmp01 (caldate,holiday) values ',in_data,';');
prepare s1 from @sql;
execute s1;
alter table tmp01 add index i01 (caldate);

end if;

if err_code=0 then # 90 修改
 update tOUset_Calendar a,tmp01 b Set
 a.holiday=b.holiday 
 Where a.OUguid=in_OUguid and a.caldate=b.caldate;
 set outMsg='存檔完成';
end if;

end; # begin