delimiter $$

drop function if exists f_mask $$

CREATE DEFINER=`sa`@`%` FUNCTION `f_mask`(str_inputA varchar(32), str_inputB varCHAR(32)) RETURNS char(32) CHARSET utf8
BEGIN
# Declare variables
DECLARE len_inputA int;
DECLARE len_inputB int;
DECLARE loop_i int;
Declare str_tmpA varchar(36);
declare str_inputC char; /*mask符號*/
 
# Initialize variables

IF ifnull(str_inputB,'')='' then set str_inputB='***'; end if;


SET len_inputA  = LENGTH(str_inputA);
SET len_inputB  = LENGTH(str_inputB);
SET loop_i      = 1;
SET str_tmpA  = '';
SET str_inputC='*'; /*mask符號*/

# Construct formated string

While loop_i <= len_inputB Do

   SET str_tmpA = concat(str_tmpA,if(substring(str_inputB,loop_i,1)='*',str_inputC,substring(str_inputA,loop_i,1)));
 
   set loop_i=loop_i+1;
 
end while;
 

RETURN str_tmpA;
END$$

