
drop procedure if exists p03;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `P03`
(
 IN inSTR_A TEXT /*empid,dutydate key 值*/
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

 
# 將table 資料轉置，產生另一temp table
set @inSTR_A = inSTR_A ;
set @inSTR_B = inSTR_B ;   
set @inSTR_C = inSTR_C;  
set @inTable=inTable;
set @inCRtable=inCRtable;

 set @sql_p1='';  # Select a.empid,a.payYYYYMM
 set @sql_p2 =''; # OFF01.offmins as OFF01,OFF02.offmins as OFF02,OFF02_2.offmins as OFF02_2,OFF04.offmins as OFF04,OFF07.offmins as OFF07,OFF08.offmins as OFF08,OFF11.offmins as OFF11,OFF12.offmins as OFF12,OFF14.offmins as OFF14,OFF15.offmins as OFF15,OFF16.offmins as OFF16,OFF17.offmins as OFF17,OFF18.offmins as OFF18
 set @sql_p3= concat('from ',inTable," a "); # from tmp01 a 
 set @sql_p4_1=''; # left join tmp01 x_u_y_z On x_u_y_z.offtype= 'MM_OO_PP' and a.empid= x_u_y_z.empid   And a.payYYYYMM= x_u_y_z.payYYYYMM  
 set @sql_p4_2=''; # left join tmp01 OFF18 On OFF18.offtype= 'OFF18' and a.empid= OFF18.empid   And a.payYYYYMM= OFF18.payYYYYMM  
 set @sql_p4_all =''; 
 /* @sql_p4_all=
 left join tmp01 OFF01 On OFF01.offtype= 'OFF01' and a.empid= OFF01.empid   And a.payYYYYMM= OFF01.payYYYYMM  
 left join tmp01 OFF02 On OFF02.offtype= 'OFF02' and a.empid= OFF02.empid   And a.payYYYYMM= OFF02.payYYYYMM  
 left join tmp01 OFF02_2 On OFF02_2.offtype= 'OFF02-2' and a.empid= OFF02_2.empid   And a.payYYYYMM= OFF02_2.payYYYYMM  
*/ 
 

#########################################
/*
   將call P03('empid,dutydate','offtype','dutyoffmins','tmp01','tmpOut01');
   產生
   set @sql_p4 = "x_u_y_z.offtype='x_u_y_z' and a.empid= x_u_y_z.empid   And a.empid= x_u_y_z.empid   And a.dutydate= x_u_y_z.dutydate  "
*/
#########################################

select count(*) into @Is_temp_table 
from information_schema.tables
where table_schema=schema()
and table_name=inTable ;

IF @Is_temp_table =0  THEN
/*使用TEMP TABLE，則建立一般engine=memory table 使用
  因temp table 無法被使用於子查詢，子join */
   set @inTable = concat("tmp_pool.tmp_",replace(uuid(),'-','_'));
   set @sql_inTable = concat("create table ",@inTable," engine=memory as select * from ",inTable,";");

   prepare s1 from @sql_inTable;
   execute s1;

END IF;

While run_i > 0 do

set @colA = f_strIndex(inSTR_A,',',run_i);

if @colA is null Then set run_i = -1; end if ;

if run_i = 1 Then
 
  set @sql_p4_1 = concat("left join ",@inTable," x_u_y_z On x_u_y_z.",inSTR_B,"= 'MM_OO_PP' and ","a.",@colA,"= x_u_y_z.",@colA,"  ");
  set @sql_p1 = concat("Select a.",@colA);
  
  -- set @sql_where = concat(" Where a.",@colA,"!=''");
  
end if;

if run_i > 1 Then   
   set  @sql_p4_1 = concat(@sql_p4_1," And ","a.",@colA,"= x_u_y_z.",@colA,"  ");
   set  @sql_p1 = concat(@sql_p1,",a.",@colA);

   -- set @sql_where = concat(@sql_where," OR a.",@colA,"!=''");
end if;

   set run_i = run_i + 1; 

end While;

####################################
/*
 產生
 left join tmp01 OFF03 On a.empid= OFF03.empid   And a.dutydate= OFF03.dutydate  
 left join tmp01 OFF04 On a.empid= OFF04.empid   And a.dutydate= OFF04.dutydate  
 left join tmp01 OFF06 On a.empid= OFF06.empid   And a.dutydate= OFF06.dutydate  


*/
#####################################
drop table if exists tmp02;

set @sql = concat("create temporary table tmp02 
     select group_concat(distinct ",inSTR_B," order by ",inSTR_B," ) strB from ",@inTable);

prepare s1 from @sql;
execute s1;

select strB into @strB from tmp02;

set run_i = 1;
 
While run_i > 0 Do
  
  set @Alias = f_strIndex(@strB,',',run_i);   
  
 
  if @Alias is null Then set run_i= -1 ; else

  set @sql_p4_2 = replace(replace(@sql_p4_1,'x_u_y_z',@Alias),'-','_'); # 因為別名不能用-號，所以換成_
  
  set @sql_p4_2 = replace(@sql_p4_2,'MM_OO_PP',@Alias);  # 'MM_OO_PP' 是 offtype="MM_OO_PP"，因為是值，所以不能取代

  set @sql_p4_all= concat(@sql_p4_all,'\n',@sql_p4_2 );

  if run_i =1 Then 
  set @sql_p2 = replace(concat(@Alias,".",inSTR_C," as ",@Alias),'-','_');  
  else
  set @sql_p2 = replace(concat(@sql_p2,",",@Alias,".",inSTR_C," as ",@Alias),'-','_');
  end if;

  set run_i = run_i + 1;
  
   end if;

end While;


#####################################################
/*

*/
#####################################################


select count(*) into @inCRtable_exists
from information_schema.tables
where table_schema=schema()
and table_name=inCRtable;

if @inCRtable_exists = 0 Then
 # 若 inCRtable 不是 一般table 則 drop 掉
 set @sql_drop = concat("drop table if exists ",inCRtable,';');
 prepare s1 from @sql_drop;
 execute s1;
end if;

set @sql_f=concat("create temporary table ",inCRtable," ",@sql_p1,',\n',@sql_p2,'\n',@sql_p3,@sql_p4_all
           -- ,@sql_where
           ); 

prepare s1 from @sql_f;
execute s1;

 
IF @Is_temp_table =0 /*使用TEMP TABLE*/ THEN
   # 刪除代替inTable 使用的，tmp_ table 
   set @sql_dropTable = concat("drop table if exists ",@inTable,";");

   prepare s1 from @sql_dropTable;
   execute s1;

END IF;

 

END