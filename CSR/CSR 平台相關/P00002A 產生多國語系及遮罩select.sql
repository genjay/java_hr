-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `P00002A`( varouguid varchar(36),varempguid varchar(36)
 ,varlangid varchar(36),varPid varchar(36),varTblName varchar(36)
 ,out outSTRA varchar(5000),out outSTRB varchar(5000),out outSTRC varchar(5000))
begin

-- 用來處理多國語系及資料遮罩程式
-- call p00002A('microjet','a00514','TW','J01001','tperson',@X,@y,@z);
-- 



declare savep1 int; 
declare save_sql_safe_updates int;
declare save_max_heap_table_size int;
declare save_group_concat_max_len int;

-- --- save system setting

set save_sql_safe_updates= (select @@sql_safe_updates );
set save_max_heap_table_size=(select @@max_heap_table_size);
set save_group_concat_max_len=(select @@group_concat_max_len);


set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小 
set group_concat_max_len=5000;
 

SELECT 
GROUP_CONCAT(
IF(IFNULL(B.DISPLAY,A.DISPLAY)='M',
  CONCAT('f_MASK(',A.COLUMN_NAME ,",'",IFNULL(B.MASK,A.MASK),"')") 
,A.COLUMN_NAME)
ORDER BY a.SORT),
group_concat(ifnull(c.column_desc,a.column_name) order by a.sort ),
group_concat(a.column_name order by a.sort)
into outSTRA,outSTRB,outSTRC
FROM tcolumn_secap A
left join tcolumn_secemp b on a.pid=b.pid and a.table_name=b.table_name and a.column_name=b.column_name 
   and B.OUGUID=varouguid AND b.empguid=varempguid
LEFT JOIN tcolumn_Desc c on a.pid=c.pid and a.table_name=b.table_name and a.column_name=c.column_name
   and c.langid=varlangid
WHERE a.PID=varPid AND a.TABLE_NAME=varTblName
and ifnull(b.display,a.display) in ('S','M');


-- 改回原始設定值

set sql_safe_updates=save_sql_safe_updates ;
set max_heap_table_size= save_max_heap_table_size;
set group_concat_max_len=save_group_concat_max_len;

end