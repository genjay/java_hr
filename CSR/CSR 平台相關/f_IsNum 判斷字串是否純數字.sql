
DROP FUNCTION IF EXISTS `f_IsNum` ;　　

DELIMITER $$


CREATE FUNCTION `f_IsNum` (In_STR VARCHAR(4000)) RETURNS INT

BEGIN
DECLARE I_isnum INT DEFAULT 0;

 # f_IsNum('abc') = 0
 # f_IsNum(1234) =1 ;

 set I_isnum = In_STR REGEXP '^[0-9][0-9]*$';

# '^[0-9][0-9]*[0-9]$ 輸入一碼時，會錯誤
 
 # ^[0-9] 開頭第一字在[0-9] 中
 # [0-9]* 中間字元在[0-9] 中
 # [0-9]$ 最後字元在[0-9] 中
 
 Case 
 When I_isnum = 1 
 Then RETURN 1 ;
 Else RETURN 0 ;
 End Case ;

 END  $$

 DELIMITER ;