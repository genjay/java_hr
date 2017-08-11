
drop procedure if exists p_Droptmp;

delimiter $$
create procedure p_Droptmp( )
begin
## drop tmp_開頭的 table ，建立時間超過 30分鐘

# call p_Droptmp();

declare Nodata int default 0 ;
declare drop_tablename text;
DECLARE cur_1 CURSOR FOR select concat(table_schema,'.',table_name)
                         from information_schema.tables
                         where 
							 table_schema in ('csrhr','tmp_pool')
                         and table_name like 'tmp%'
                         and f_minute(timediff(now(),create_time))> 30 ;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET Nodata = 1;

OPEN cur_1;

REPEAT
FETCH cur_1 INTO drop_tablename;

 if Nodata=0 and drop_tablename is not null Then
 set @x=concat("drop table if exists ",drop_tablename,";");
 prepare s1 from @x;
 execute s1;
 -- insert into log_a (aa) values (@x);
 end if;

UNTIL Nodata = 1
END REPEAT;

CLOSE cur_1; 


end;