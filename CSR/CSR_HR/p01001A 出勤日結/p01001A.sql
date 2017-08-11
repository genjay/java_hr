-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `P01001A`
(varOUguid varchar(36),varDutydate int,inputTable varchar(200))
begin

declare yestoday int ;
declare nextday int;
set yestoday=(select (str_to_date(varDutydate,'%Y%m%d')-interval 1 day)+0);
set nextday =(select (str_to_date(varDutydate,'%Y%m%d')+interval 1 day)+0);

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小

call P01001A_10(varOUguid,varDutydate,inputTable);
call P01001A_20(varOUguid,varDutydate);
call P01001A_30(varOUguid,varDutydate);
call P01001A_40(varOUguid,varDutydate);

end