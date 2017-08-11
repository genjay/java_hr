DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `P01002A`(varOUguid varchar(36),varDutyDate int,inputTable varchar(200))
begin

-- Call P01001A_10('microjet',20130502,'tdutya')
-- 取得tdutya 資訊，產生20130502，的請假加總資料

declare yestoday int ;
declare nextday int;
set yestoday=(select (str_to_date(varDutyDate,'%Y%m%d')-interval 1 day)+0);
set nextday =(select (str_to_date(varDutyDate,'%Y%m%d')+interval 1 day)+0);


drop table if exists P01002A_tmp01;
SET @sql = CONCAT("create temporary table if not exists P01002A_tmp01 
		   engine=memory
		   select empguid,dutydate,stdon,stdoff from ",inputTable
           ," Where ouguid='",varOUguid,"'" 
           ," And dutydate=" ,varDutyDate  ); 
    PREPARE s1 from @sql;
    #SET @paramA = serviceName;
    EXECUTE s1 ;#USING @paramA;

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小




-- drop table P01001A_10_tmp01;
 
end$$
DELIMITER ;
