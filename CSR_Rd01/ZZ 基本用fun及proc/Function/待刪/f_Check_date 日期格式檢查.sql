drop function if exists f_check_date;

DELIMITER $$

CREATE FUNCTION f_check_date(
f_varA  varchar(36)
) RETURNS varchar(36)
BEGIN
declare in_year  char(4);
declare in_month char(2);
declare in_day   char(2);
declare feb_day  int;
declare err_code int default 0;

# 輸入年月日 若日期正確，回傳日期，錯誤傳null
# f_check_date('2014/01/01') -> '2014-01-01'
# f_check_date('2014-01-01') -> '2014-01-01'
# f_check_date('20140101')   -> '2014-01-01'
# f_check_date('20140209')   ->  Null

# 去除常見日期用分隔號
set f_varA=replace(f_varA,'/','');
set f_varA=replace(f_varA,'-','');
set f_varA=replace(f_varA,' ','');
set f_varA=replace(f_varA,':',''); 

#判斷是否純數字，且長度8碼
#if f_varA not regexp '^[0-9]{8}' then set err_code=1; end if;

if err_code=0 then # 10 取年月日的值
	set in_year =substring(f_varA,1,4);
	set in_month=substring(f_varA,5,2);
	set in_day  =substring(f_varA,7,2);
end if; # 10 取年月日的值

if err_code=0 && not (in_year between 1 and 9999) then
set err_code=1;
end if;

if err_code=0 && not (in_month between 1 and 12) then
	set err_code=1; 
end if;

if err_code=0 && not (in_day between 1 and 31) then
	set err_code=1;
end if;

if err_code=0 && in_day=31 && in_month in ('02','04','06','09','11') then
	set err_code=1;
end if;

if err_code=0 && in_month='02' then # 判斷2月是否潤月
	Case
	When mod(in_year,400 )=0 then set feb_day=29; # 年份逢 400倍數，潤
	When mod(in_year,100 )=0 then set feb_day=28; # 年份逢 100倍數，不潤
	When mod(in_year,4   )=0 then set feb_day=29; # 年份逢   4倍數，潤
	Else set feb_day=28; # 平常不潤 
	end case;
	if in_day>feb_day then set err_code=1; end if;
end if; # 判斷2月是否潤月

if err_code=0 then
	return concat(in_year,in_month,in_day); #(f_varA);
else 
	return null; # 格式有誤
end if;
 
END$$
DELIMITER ;
