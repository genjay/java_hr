drop function if exists f_date;

DELIMITER $$

CREATE FUNCTION f_date(
f_varA  varchar(36)) 
	RETURNS varchar(36)
BEGIN
declare in_year  int;
declare in_month int;
declare in_day   int;
declare feb_day  int;
declare err_code int default 0; 

# 去除常見日期用分隔號
set f_varA=replace(f_varA,'/','');
set f_varA=replace(f_varA,'-','');
set f_varA=replace(f_varA,' ','');
set f_varA=replace(f_varA,':',''); 

#判斷開頭前8碼需為數字
if f_varA not regexp '^[0-9]' then set err_code=1; end if;

if err_code=0 then
	set in_year =substring(f_varA,1,4);
	set in_month=substring(f_varA,5,2);
	set in_day  =substring(f_varA,7,2);
end if;

if err_code=0 && in_year between 1 and 9999 then
	if in_month between 1 and 12 then
		Case 
# 因為前面沒有判斷是否純數字，所以between 不可用字串 '1' and '12'
# 在數字間的字串會通過判斷式
		When in_day between 1 and 28 then set err_code=0;
		When in_day between 29 and 30 && not in_month in ('02') then set err_code=0;
		When in_day = '31' && in_month in ('01','03','05','07','08','10','12') then set err_code=0;
		When in_day = '29' && mod(in_year,4)=0 && mod(in_year,100)!=0 then set err_code=0;
		
		else set err_code=1; # 
		end case;
else set err_code=1; end if; # in_month
else set err_code=1; end if; # in_year
 
if err_code=0 then 
	return (concat(lpad( in_year,4,'0'),'-',lpad(in_month,2,'0'),'-',lpad(  in_day,2,'0')));
else 
	return null; # 格式有誤
end if;
 
END$$
DELIMITER ;
