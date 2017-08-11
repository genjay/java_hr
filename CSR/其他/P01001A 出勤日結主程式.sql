drop procedure if exists P01001A;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `P01001A`(varOUguid varchar(36),varDutydate date,inputTable varchar(200))
begin

declare yestoday date ;
declare nextday date;
set yestoday=(select varDutydate -interval 1 day);
set nextday =(select varDutydate +interval 1 day);

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小

-- START 產生 輸入資料用的TABLE
DROP TABLE IF EXISTS tmpA_P01001;

SET @sql = CONCAT("create temporary table if not exists tmpA_P01001 
		   engine=memory
		   select empguid from ",inputTable,
           " Where ouguid=",
           "'" , varOUguid,"'"); 
  -- 若加上distinct 雖可避免前端重復資料進入
  -- 但是在5萬筆，varchar(36)的狀況下，會多5秒執行

    PREPARE s1 from @sql;
    #SET @paramA = serviceName;
    EXECUTE s1 ;#USING @paramA;

create index iEmp on tmpA_P01001 (empguid);

call p01001a_10(varOUguid,varDutydate);
call p01001a_20(varOUguid,varDutydate);
call p01001a_30(varOUguid,varDutydate);
call p01001a_40(varOUguid,varDutydate);
call p01001a_50(varOUguid,varDutydate);
call p01001a_60(varOUguid,varDutydate);
call p01001a_90(varOUguid,varDutydate);


-- END 產生 輸入資料用TABLE 
 

DROP TABLE IF EXISTS tmpA_P01001;

end