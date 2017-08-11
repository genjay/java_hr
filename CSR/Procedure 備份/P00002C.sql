DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `P00002C`(
  varouguid varchar(36),varempguid varchar(36)
 ,varlangid varchar(36),varPid varchar(36),varTblName varchar(36)
 ,VARrwid int
 ,out outSTRA text ,out outSTRB text,out outSTRC text)
begin

-- P00002C 產生多國語的的columns的sql語句
-- call P00002c('microjet','a00514','tw','j01001','tperson',0,@x,@y,@z);

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
  
drop table if exists tmpA_P00002;

create table tmpA_P00002
select  
 a.column_name
,Case /*多國語系，若有則以多國語系DESC輸出*/
 When IFNULL(Y.column_Desc,'')!='' Then Y.column_Desc  
 Else  a.column_desc 
 End MutiDesc 
,a.column_Desc /*預設DESC*/
,Case /*display與mask為一組的*/
 When IFNULL(d.display,'')!='' Then  d.mask 
 When IFNULL(c.display,'')!='' Then  c.mask 
 When IFNULL(b.display,'')!='' Then  b.mask 
 Else a.mask
 end mask
,Case  /*showtype 最多到pid 能不一樣，減少設定錯誤，造成混亂*/
 -- When IFNULL(d.showtype,'')!='' Then d.showtype /*人員權限*/
 -- When IFNULL(c.showtype,'')!='' Then c.showtype /*角色權限*/
 When IFNULL(b.showtype,'')!='' Then b.showtype /*程式權限*/
 else a.showtype /*dd權限*/
 end showtype
,Case 
 When IFNULL(d.display,'')!='' Then d.display
 When IFNULL(c.display,'')!='' Then c.display
 When IFNULL(b.display,'')!='' Then b.display
 else a.display
 end display
,Case 
 When IFNULL(d.sort,'')!='' Then d.sort
 When IFNULL(c.sort,'')!='' Then c.sort
 When IFNULL(b.sort,'')!='' Then b.sort
 else a.sort
 end sort
from tcolumn_secdd a 
inner join  information_schema.columns a1 on a1.table_name=varTblName
 and a.column_name=a1.column_name and a1.table_schema=schema()
left join tcolumn_secpid b on a.column_name=b.column_name and b.pid=varPid
left join tcolumn_secrole c on a.column_name=c.column_name 
 and c.ouguid=varouguid and c.pid=varPid
 and c.roleguid in (select roleguid from trolemember where empguid=varempguid)
left join tcolumn_secemp d on a.column_name=d.column_name
 and d.ouguid=varouguid and d.pid=varPid 
 and d.empguid=varempguid
left join tcolumn_desc Y on a.column_name=Y.column_name and Y.langID=varlangid
 and Y.pid=varPid;

select /*傳回column_name相關資料*/
group_concat(
concat(IFNULL(mutidesc,''),',',IFNULL(showtype,''),',',IFNULL(column_name,''),',',IFNULL(column_desc,''))
order by sort)
into outSTRA
from tmpA_P00002
where display in ('S','M') ;


select group_concat(column_name order by sort) into outSTRC
from tmpA_P00002
where display in ('S','M') ;


IF outSTRA is null Then 
 set outSTRA='無欄位資料可顯示，請檢查DD資料設定\n 或 table input 是否正確';
Else 

 select -- *產生sql ???? 部份的前置指令 select ???? from ... 
group_concat(
Case 
When a.display='M' THEN concat('f_mask(',a.column_name,",'",mask,"') as ", a.MutiDesc)
else concat(a.column_name,' as ',a.MutiDesc)
end order by a.sort) 
into @tmpX1
from tmpA_P00002 a
where  display in ('S','M') ;
END IF;


-- 傳出第二參數outSTRB，可以執行的sql指令

IF VARrwid=0 THEN

 -- VARriid=0 為多筆顯示，不加where 及order by 
Set outSTRB=concat("select ",@tmpX1  
 ," from ",varTblName
 ," ");

ELSE 
-- 指定單筆，只能顯示一筆，為修改畫面使用
Set outSTRB=concat("select ",@tmpX1  
 ," from ",varTblName
 ," Where rwid=",VARrwid
 ," limit 1");
 
end if;


drop table if exists tmpA_P00002;

-- 改回原始設定值

set sql_safe_updates=save_sql_safe_updates ;
set max_heap_table_size= save_max_heap_table_size;
set group_concat_max_len=save_group_concat_max_len;

end$$
DELIMITER ;
