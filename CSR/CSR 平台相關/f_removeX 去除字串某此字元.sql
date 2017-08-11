
drop function if exists  f_removeX;
DELIMITER $$

CREATE DEFINER=`admin`@`%` FUNCTION `f_removeX`(In_STR VARCHAR(4000)) RETURNS VARCHAR(4000)
BEGIN
  
 # 用來除出、空白、-、:、/ 等字元
  set @X1 = replace(In_STR,' ','');
  set @X1 = replace(@X1,'-','');
  set @X1 = replace(@X1,':','');
  set @X1 = replace(@X1,'/','');
  set @X1 = replace(@X1,'.','');

#  set @DateA= left(@X1,8);
#  set @TimeA= right(@X1,4);
  Return @X1;
  # Return  str_to_date(concat(@DateA,@TimeA),'%Y%m%d%H%i');
 
 END