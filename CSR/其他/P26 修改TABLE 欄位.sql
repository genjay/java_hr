drop procedure if exists p26;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p26`()
BEGIN
  
 DECLARE b INT;
 declare a,LAST_A text;

 DECLARE cur_1 CURSOR FOR select distinct concat("alter table ",table_schema,'.',table_name ,'\n'
"add column ltdate datetime default CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP  after rwid
,add column ltUser varchar(36) after ltdate
,add column ltpid  varchar(36) after ltUser  ;")
from information_schema.columns  
where   
  table_schema in ('csrhr','csr_system','csr_memo')
and table_name in (select table_name from information_schema.tables where table_type='BASE TABLE')
order by table_name;

 DECLARE CONTINUE HANDLER FOR NOT FOUND SET b = 1;
 OPEN cur_1;
 REPEAT
 FETCH cur_1 into a;
  if @sql!= a Then  
    set @sql=a;
    prepare s1 from @sql;
    execute s1;
  end if; 

 UNTIL b = 1
 END REPEAT;
 CLOSE cur_1; 
END