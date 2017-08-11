drop function if exists f_check_datetime;

DELIMITER $$

CREATE FUNCTION f_check_datetime(
f_varA  varchar(36)) 
	RETURNS datetime
BEGIN
	declare in_year  int;
	declare in_month int;
	declare in_day   int;
	declare feb_day  int;
	declare err_code int default 0;
	declare HH int default 0 ;
	declare mm int default 0 ;
	declare ss int default 0 ;
	declare varA_lth int default 0 ;

# 正則式Regexp 放在fuctoin 內，會遠慢於在外面
# 
# 輸入年月日 若日期正確，回傳完整日期時間格式含秒
# 格式，1 年月日 2．年月日時分 3．年月日時分秒
# f_check_date('2014/01/01') -> '2014-01-01 00:00:00'
# f_check_date('2014-01-01') -> '2014-01-01 00:00:00'
# f_check_date('20140101')   -> '2014-01-01'
# f_check_date('20140209')   ->  Null

	set f_varA=replace(f_varA,'/','');
	set f_varA=replace(f_varA,'-','');
	set f_varA=replace(f_varA,':','');
	set f_varA=replace(f_varA,' ','');

#判斷是否純數字，且長度8碼
if f_varA not regexp '^[0-9]*$' then set err_code=1; end if;
	set varA_lth=length(f_varA);
if varA_lth not in (8,12,14) then set err_code=1; end if;

if err_code=0 && varA_lth>=14 then set ss  =substring(f_varA,13,2); 
else set ss=0; end if;

if err_code=0 &&  varA_lth>=12 then set mm  =substring(f_varA,11,2);
else set mm=0; end if;

if err_code=0 &&  varA_lth>=10 then set HH  =substring(f_varA, 9,2); 
else set HH=0; end if;

if err_code=0 then 
	set in_year =substring(f_varA,1,4);
	set in_month=substring(f_varA,5,2);
	set in_day  =substring(f_varA,7,2);
end if;

if err_code=0 && not (HH between 0 and 23) then set err_code=1; end if;
if err_code=0 && not (mm between 0 and 59) then set err_code=1; end if;
if err_code=0 && not (ss between 0 and 59) then set err_code=1; end if;

if err_code=0 && not (in_month between 1 and 12) then
	set err_code=1; 
end if;

if err_code=0 && not (in_day between 1 and 31) then
	set err_code=1;
end if;

if err_code=0 && in_month='02' then # 判斷2月是否潤月
	Case
#	When mod(in_year,4000)=0 then set feb_day=28; # 年份逢4000倍數，不潤
	When mod(in_year,400 )=0 then set feb_day=29; # 年份逢 400倍數，潤
	When mod(in_year,100 )=0 then set feb_day=28; # 年份逢 100倍數，不潤
	When mod(in_year,4   )=0 then set feb_day=29; # 年份逢   4倍數，潤
	Else set feb_day=28; # 平常不潤 
	end case;
	if in_day>feb_day then set err_code=1; end if;
end if; # 判斷2月是否潤月

if err_code=0 && in_month in (4,6,9,11) && in_day>30 then
	set err_code=1;
end if;

if err_code=0 then
	return  
concat(
	 lpad(in_year,4,'0'),'-'
	,lpad(in_month,2,'0'),'-'
	,lpad(in_day,2,'0'),' '
	,lpad(HH,2,'0'),':'
	,lpad(mm,2,'0'),':'
	,lpad(ss,2,'0')  
	);
else 
	 return null; # 格式有誤
end if;
  
END$$
DELIMITER ;
