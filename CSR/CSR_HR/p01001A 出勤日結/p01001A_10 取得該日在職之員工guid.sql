-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `P01001A_10`
(varOUguid varchar(36),varDutyDate int,inputTable varchar(200))
begin
declare yestoday int ;
declare nextday int;
set yestoday=(select (str_to_date(varDutyDate,'%Y%m%d')-interval 1 day)+0);
set nextday =(select (str_to_date(varDutyDate,'%Y%m%d')+interval 1 day)+0);

SET @sql = CONCAT('create temporary table if not exists P01001A_10_tmp01 
		   engine=memory
		   select empguid from ',inputTable ); 
    PREPARE s1 from @sql;
    #SET @paramA = serviceName;
    EXECUTE s1 ;#USING @paramA;

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小

drop table if exists P01001A_10_OUTPUT;
create temporary table if not exists P01001A_10_OUTPUT engine=memory
select a.empguid,a.depguid,a.cardno
from tperson a
where  
    varDutyDate>=a.arrivedate # 到職後才要出勤
and varDutyDate<=Case When a.leavedate>0 Then a.leavedate Else 29991231 end #離職前要出勤
and varDutyDate<=Case When  a.stopdate>0 Then  a.stopdate Else 29991231 End #留停前要出勤
and varOUguid=a.OUguid
and a.empguid in (select empguid from P01001A_10_tmp01);

drop table if exists P01001A_10_tmp01;
 
end