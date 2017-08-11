
drop procedure if exists p04;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p04`
(
 IN inSTR_A text /*empid,dutydate key 值*/
,IN inSTR_B text /*offtype*/
,IN inSTR_C text /*dutyoffmins*/
,IN inTable   varchar(255) /*資料來源table*/
,IN inCRtable varchar(255) /*資料產出table_name*/
)
BEGIN

/* 
 需使用 tmp_pool 的schema 
 
 將view或table轉置 
 
 call p03('empid,dutydate','offtype','offmins','tmp01','tmp_d01c');

 不可存在 tmp_d01C 

*/

declare run_i int default 1; 
DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN   
 # 發生sql error 時，drop tmp_ table 
 IF @Is_temp_table =0 /*使用TEMP TABLE*/ THEN
   # 刪除代替inTable 使用的，tmp_ table 
   set @sql_dropTable = concat("drop table if exists ",@inTable,";");

   prepare s1 from @sql_dropTable;
   execute s1;
 end if;
 END; 
if 1=1 then # 產生 tmpX01 
 drop table if exists tmpX01;
 set @sql=concat("
 create temporary table tmpX01 engine=myisam
 select * from ",inTable,";");
 prepare s1 from @sql;
 execute s1;

# 加index ，整體時間可能加長
set @sql=concat("alter table tmpX01 add index i01 (",inSTR_A,',',inSTR_B,");");
 prepare s1 from @sql;
 execute s1; 
end if;

if 1=1 then # 產生 tmpX02 空table
drop table if exists tmpX02;
select concat(group_concat( distinct col_type SEPARATOR  ' text,')) 
into @sql
from tmpX01;
set @inSTR_A=concat(replace(inSTR_A,',',' varchar(255),'),' varchar(255)');

set @sql=concat('create temporary table tmpX02 (',@inSTR_A,',',@sql,' text);');
prepare s1 from @sql;
execute s1;
end if;

if 1=1 then # 產生 insert tmpX02 的sql
 set @sql=concat("Select  group_concat(",inSTR_C," order by ",inSTR_A,") "
 ,"from tmpX01 group by ",inSTR_A," ");
 
end if;
  

END