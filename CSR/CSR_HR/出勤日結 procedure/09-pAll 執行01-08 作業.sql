delimiter $$

create procedure pAll (var_OUguid varchar(36),var_Dutydate int)

begin

declare yestoday int ;
declare nextday int;
set yestoday=(select (str_to_date(var_Dutydate,'%Y%m%d')-interval 1 day)+0);
set nextday =(select (str_to_date(var_Dutydate,'%Y%m%d')+interval 1 day)+0);

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小

call get_emp(var_OUguid,var_Dutydate);
call get_dutystd(var_OUguid,var_Dutydate);
call get_time(var_OUguid,var_Dutydate);

end$$
