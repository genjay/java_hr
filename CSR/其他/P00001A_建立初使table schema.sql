DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `P00001A`(varSTR varchar(36))
begin
 
 -- 建立初使table schema 用，半成品

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小
 

SET @sql = CONCAT("create schema if not exists ",varSTR ); 

    PREPARE s1 from @sql;
    #SET @paramA = serviceName;
    EXECUTE s1 ;#USING @paramA;
  

end