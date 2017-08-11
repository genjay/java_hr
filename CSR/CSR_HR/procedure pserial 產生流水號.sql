delimiter $$
#產生1,2,3... input cnt 為筆數
#用此方法速度很慢,遠慢於下列方法
#create table tserno select rwid from tcardtime order by 1 limit 30;
create procedure pserial (in cnt int)
begin

DECLARE i int default 0;

 drop table if exists tserno; 

 create table tserno (rwid int unsigned NOT NULL AUTO_INCREMENT ,
 PRIMARY KEY (rwid));

while i<cnt do
 
 set i=i+1;  
 insert into tserno (rwid) values (i);
end while;
end $$
 

delimiter ;

