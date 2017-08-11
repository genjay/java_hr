drop FUNCTION if exists f_minute;

delimiter $$

CREATE DEFINER=`root`@`localhost` FUNCTION `f_minute`(f_varA varchar(20)) RETURNS int(11)
BEGIN

# 將timediff 結果換成分鐘數，秒數部份無條件進位
 
DECLARE OUTPUT int;
DECLARE VAR_A VARCHAR(20);
SET VAR_A=SUBSTRING(f_varA,1+INSTR(f_varA,'-'),8);

  Set OUTPUT=(select 
  substring(VAR_A,1,2)*60+ # 小時
  substring(VAR_A,4,2)+    # 分
  if(substring(VAR_A,7,2)='00',0,1)  # 秒
 );
   
  RETURN (OUTPUT);
END$$

