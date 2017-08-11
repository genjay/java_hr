delimiter $$
create procedure test3
(IN inSTR_A varchar(5000),IN inSTR_B varchar(5000),IN inSTR_C varchar(5000),IN inSTR_D varchar(5000)
,out sOUT text)

begin
 
 declare done int default 0;

 -- declare cur1 cursor for select DISTINCT offtype,displaysort from VOFFDUTY  ;

 -- declare continue handler for not found set done=1;

 declare outSTR_A text;
 declare outSTR_B text;
 declare outSTR_C text;
 declare outSTR_D text;

set outSTR_A = (select concat('a.',replace(inSTR_A,',',',a.'))) ;

drop table if exists tmp01;

Set @sql= concat("create table tmp01  
 as Select group_concat(distinct concat(", inSTR_B ,",' ',",inSTR_B,")"
 ," order by displaysort ) x1 from ",inSTR_D);  

prepare s1 from @sql;

execute s1 ;

select x1 into outSTR_B from tmp01;

set outSTR_B=replace(outSTR_B,' ',concat('.',inSTR_C,' '));

-- set outSTR_B=concat(outSTR_B,'.',inSTR_C);
 

-- set outSTR_B=@dout;



set sOUT = concat("Select ", outSTR_A,",",outSTR_B );

set sOUT = concat(sOUT," From ",inSTR_D ," A");

-- set sOUT = outSTR_B;

 


      

end

  
