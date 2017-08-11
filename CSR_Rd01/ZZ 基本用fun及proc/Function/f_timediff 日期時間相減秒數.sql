drop FUNCTION if exists f_timediff;

delimiter $$

CREATE DEFINER=`root`@`localhost` FUNCTION `f_timediff`(
f_varA datetime,
f_varB datetime
) RETURNS int(11)
BEGIN

# 時間差距，時間單位(秒)
 
DECLARE int_diff int;
declare var_timediff varchar(36);
DECLARE VAR_A VARCHAR(20);

set var_timediff=timediff(f_varA,f_varB);

set int_diff= right(var_timediff,2);
set int_diff=int_diff + 60*substring(var_timediff,instr(var_timediff,':')+1,2); /*分*/

if substring(var_timediff,1,1)='-' 
then /*負數時*/
 set int_diff=(-int_diff)+60*60*substring(var_timediff,1,instr(var_timediff,':')-1);
else /*正數*/
 set int_diff=(+int_diff)+60*60*substring(var_timediff,1,instr(var_timediff,':')-1);
end if;
 
   
  RETURN (int_diff);
END$$

