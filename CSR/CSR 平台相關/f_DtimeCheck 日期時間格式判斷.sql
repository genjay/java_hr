
drop function if exists  f_DtimeCheck;
DELIMITER $$

CREATE DEFINER=`admin`@`%` FUNCTION `f_DtimeCheck`(In_STR VARCHAR(4000)) RETURNS VARCHAR(4000)
BEGIN
  
# 輸入完整數字，判斷是否能轉成日期格式
  
  if f_IsNum(In_STR)=0 Then return '輸入條件包含非數字'; end if;

  if length(In_STR) Not in (12,14) Then return '長度不正確，需12或14碼'; end if;

  if substring(In_STR,5,2) Not between 1 And 12 Then return '月份錯誤'; end if;

  if substring(In_STR,7,2) Not between 1 And 31 Then return '日期錯誤'; end if;

  if substring(In_STR,9,2) Not between 0 And 23 Then return '小時錯誤'; end if;

  if substring(In_STR,11,2) Not between 0 And 60 Then return '分鐘錯誤'; end if; 

  return 'OK';
  
 
 END