drop function if exists f_datetime;

DELIMITER $$

CREATE FUNCTION f_datetime(
f_varA  varchar(36),f_varB varchar(20)) 
	RETURNS varchar(36)
BEGIN
declare in_year  int;
declare in_month int;
declare in_day   int;
declare feb_day  int;
declare err_code int default 0; 
declare in_HH int default 0 ;
declare in_mm int default 0 ;
declare in_ss int default 0 ;
declare varA_lth int default 0 ;

# 此程式類似str_to_date 
# 主要用於str_to_date 在create table 及insert select ...時，無法完成
# 此程式在遇到不合理日期時，會回傳null
# 此程式執行速度慢stt_to_date 約十幾倍，使用上請注意
# f_datetime(valid_st,'%Y-%m-%d %H:%i:%s') 12秒
# str_to_date(valid_st,'%Y-%m-%d %H:%i:%s') 0.5秒



if f_varB='' then set f_varB='%Y-%m-%d %H:%i:%s'; end if;
# 去除常見日期用分隔號
set f_varA=replace(f_varA,'/','');
set f_varA=replace(f_varA,'-','');
set f_varA=replace(f_varA,' ','');
set f_varA=replace(f_varA,':',''); 

#判斷開頭前8碼需為數字
if f_varA not regexp '^[0-9]{8,}' then set err_code=1; end if;
set varA_lth=length(f_varA);
if varA_lth not in (8,12,14) then set err_code=1; end if;

if err_code=0 then
	set in_year =substring(f_varA,1,4);
	set in_month=substring(f_varA,5,2);
	set in_day  =substring(f_varA,7,2);
end if;

if err_code=0 && varA_lth>=14 then set in_ss  =substring(f_varA,13,2); 
else set in_ss=0; end if;

if err_code=0 &&  varA_lth>=12 then set in_mm  =substring(f_varA,11,2);
else set in_mm=0; end if;

if err_code=0 &&  varA_lth>=10 then set in_HH  =substring(f_varA, 9,2); 
else set in_HH=0; end if;

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

if err_code=0 && not (in_HH between 0 and 23) then set err_code=1; end if;
if err_code=0 && not (in_mm between 0 and 59) then set err_code=1; end if;
if err_code=0 && not (in_ss between 0 and 59) then set err_code=1; end if;
 
if err_code=0 then 
	return date_format(  
concat(
	 lpad(in_year ,4,'0'),'-'
	,lpad(in_month,2,'0'),'-'
	,lpad(in_day  ,2,'0'),' '
	,lpad(in_HH,2,'0'),':'
	,lpad(in_mm,2,'0'),':'
	,lpad(in_ss,2,'0')  
	),f_varB);
else 
	return null; # 格式有誤
end if;
 
END$$
DELIMITER ;
