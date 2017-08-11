drop function if exists f_check_time;

DELIMITER $$

CREATE FUNCTION f_check_time(
f_varA  varchar(36)
) RETURNS varchar(36)
BEGIN
declare HH int default 0;
declare mm int default 0;
declare ss int default 0;
declare err_code int default 0;

# 檢查時間格式，HH:mm:ss 時分秒，分格號可有可無
# 正確回傳 HH:mm:ss
# f_Check_time('12:30:00') -> '12:30:00'
# f_Check_time('12:30')    -> '12:30:00'
# f_Check_time('12:30:0')  -> null 不含分隔號必需4碼或6碼

set f_varA=replace(f_varA,':','');
set f_varA=replace(f_varA,'/','');
set f_varA=replace(f_varA,'-','');

#判斷是否純數字，且長度4碼或6碼
if f_varA not regexp '^[0-9]{4}([0-9]{2})?$' then set err_code=1; end if;

if err_code=0 then # 抓取時分秒
	set HH=substring(f_varA,1,2);
	set mm=substring(f_varA,3,2);
	set ss=if(length(f_varA)=6,substring(f_varA,5,2),0);
end if; # 抓取時分秒

if err_code=0 && not (HH between 0 and 23) then
	set err_code=1;
end if;

if err_code=0 && not (mm between 0 and 59) then
	set err_code=1;
end if;

if err_code=0 && not (ss between 0 and 59) then
	set err_code=1;
end if;

if err_code=0 then
	return concat(lpad(HH,2,'0'),':',lpad(mm,2,'0'),':',lpad(ss,2,'0'));
else 
	return null; # 格式有誤
end if;
 
END$$
DELIMITER ;
