
drop procedure if exists p05;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p05`
(
 IN inSTR_A text /*empid,dutydate key 值*/
,IN inSTR_B text /*offtype*/
,IN inSTR_C text /*dutyoffmins*/
,IN inTable   varchar(255) /*資料來源table*/
,IN inCRtable varchar(255) /*資料產出table_name*/
)
BEGIN

declare err_code int default 0;
declare run_i int default 1;  
declare sql_column   text;

if err_code=0 then 

set @sql=concat("
select group_concat(distinct ",inSTR_B," order by ",inSTR_B,") into @strXX from ",inTable,";");

prepare s1 from @sql;
execute s1;

end if; 

if err_code=0 then # 組成轉置用的sql
 set @sql=concat('Select ',inSTR_A,'\n');
 while run_i > 0 do
  set @sql_column=f_strIndex(@strXX,',',run_i);
  if @sql_column is null 
  then set run_i=-1; 
  else
  set @sql_part=concat(",sum(if(",inSTR_B,"='",@sql_column,"',",inSTR_C,",0)) ",@sql_column,"\n");
  set @sql=concat(@sql,@sql_part);
  end if;
  set run_i=run_i+1;
 end while;

set @sql=concat(@sql," from ",inTable," group by ",inSTR_A);
end if;

if err_code=0 then
 set @sql=concat("create temporary table ",inCRtable,' engine=myisam ',@sql);
 prepare s1 from @sql;
 execute s1;
end if; 

END