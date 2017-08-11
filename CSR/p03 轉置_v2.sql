
drop procedure if exists p03;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `P03`
(
 IN inSTR_A TEXT /*empid,dutydate key 值*/
,IN inSTR_B TEXT /*offtype*/
,IN inSTR_C TEXT /*dutyoffmins*/
,IN inTable   varchar(255) /*資料來源table*/
,IN inCRtable varchar(255) /*資料產出table_name*/
)
BEGIN
 
DECLARE run_i int default 1;
DECLARE colA varchar(255);
DECLARE tmp_Alias varchar(255) default "HHH"; 
DECLARE tmp_Value varchar(255) default "UUU"; 

DECLARE EXIT  HANDLER FOR 1062
SELECT CONCAT(inSTR_A,',',inSTR_B," IN SOURCE TABLE ",inTable," NEED UNIQUE ");
###

DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN   
 # 發生sql error 時，drop tmp_ table  
 
   set @sql_dropTable = concat("drop table if exists ",@tmpTable,";");

   prepare s1 from @sql_dropTable;
   execute s1; 
 END;  


SET max_heap_table_size = 1024*1024*1024;


/* 使用方法
call p03('empid','offtype','offmins','tmp_d01C_1','tmp_d02c');

tmp_01C_1 為資料來源
輸入條件 1,2，必需為unique ，才能使用此程式
*/

/*============================================================
  建立tmp_table，及依 inSTR_A 建立索引*/
IF 1=1  THEN # 建立 tmp_table及索引
   set @tmpTable = concat("tmp_pool.tmp_",replace(uuid(),'-','_'));
   set @sql_tmpTable = concat("create table "
                               ,@tmpTable
                               ," engine=memory "
                               ," as select * from "
                               ,inTable,";");

   prepare s1 from @sql_tmpTable;
   execute s1;
   set @sql_tmpTable = concat("alter table ",@tmpTable," add unique index i01 (",inSTR_A,',',inSTR_B,");");
--   set @sql_tmpTable = concat("alter table ",@tmpTable," add unique index i01 (",inSTR_A,");");
   prepare s1 from @sql_tmpTable;
   execute s1;

END IF;

/* 
建立tmp_table，及依 inSTR_A 建立索引
=============================================================*/

/*============================================================
  */

IF 1=1 THEN 

  While run_i > 0 Do
  
  set colA = f_strIndex(inSTR_A,',',run_i); # colA= 'empid'

  if colA is null Then set run_i = -1; end if; # inSTR_A 結束時，run_i=-1 結束回圈

  if run_i =1 Then 
   set @sql_p1 = concat("Select distinct a.",colA); # colA='empid'
   set @tmp_AA = concat(tmp_Alias); 
   set @sql_p4A= concat("left join ",@tmpTable," as ",@tmp_AA    # left join tmp01 as hhh
                 ," On ",@tmp_AA,".",inSTR_B,"='",tmp_Value,"'"   # On hhh.offtype='UUU' 
                 ," And a.",colA,"=",@tmp_AA,".",colA ," \n" );   # And a.empid=HHH.empid 

  elseif run_i > 1 Then 
   set @sql_p1 = concat(@sql_p1,",a.",colA);  
   set @sql_p4A= concat(@sql_p4A," and a.",colA,"=",@tmp_AA,'.',colA
                 ,'\n');
  
  end if;

  set run_i = run_i + 1;  

  end While ;

END IF;


/*
 =============================================================*/


/*============================================================
  取得 offtype 明細*/
drop table if exists tmp02;
set @sql_tmp02 = concat("create temporary table tmp02 
      select group_concat(distinct ",inSTR_B," order by ",inSTR_B," ) strB from ",@tmpTable);

prepare s1 from  @sql_tmp02;
execute s1;

select strB into @strB from tmp02;

drop table if exists tmp02;

/* 取得 offtype 明細 ，結尾
==============================================================*/


/*===============================================================
 計算 @sql_p2,@sql_p4
 @sql_p2=",OFF01.offmins as OFF01,off01_1.offmins as off01_1,OFF02.offmins as OFF02 "

 @sql_p4="left join tmp_pool.tmp_ac525f6d_f2bc_11e3_8210_000c29364755 as OFF01 On a.empid=OFF01.empid and a.dutydate=OFF01.dutydate and OFF01.offtype='OFF01'
         left join tmp_pool.tmp_ac525f6d_f2bc_11e3_8210_000c29364755 as off01_1 On a.empid=off01_1.empid and a.dutydate=off01_1.dutydate and off01_1.offtype='off01-1'"
*/
 set run_i = 1;
 
While 1 and run_i > 0 Do
  
  set colA = f_strIndex(@strB,',',run_i); # colA= 'OFF01'

  if colA is null Then set run_i = -1; end if; # 結束時，run_i=-1 結束回圈

if run_i =1 Then 
   set @sql_p2 = concat(",",colA,".",inSTR_C," as ",colA); #  inSTR_C='Offmins",colA='OFF01"
   set @sql_p2 = replace(@sql_p2,'-','_'); # 因為offtype會有 off01-1，sql內不能用(-)號

   set @sql_p4 =  replace(@sql_p4A,tmp_Alias,replace(colA,'-','_'));
 
   set @sql_p4 =  replace(@sql_p4,tmp_Value,colA); # 取代 offtype='UUU' -> 'OFF01-1'
   
elseif run_i > 1 Then 
   set @sql_p2 = concat(@sql_p2,",",colA,".",inSTR_C," as ",colA); #  inSTR_C='Offmins",colA='OFF01"
   set @sql_p2 = replace(@sql_p2,'-','_'); # 因為offtype會有 off01-1，sql內不能用(-)號

   set @sql_p4 = concat(@sql_p4,replace(@sql_p4A,tmp_Alias,replace(colA,'-','_')));   
   set @sql_p4 =  replace(@sql_p4,tmp_Value,colA); # 取代 offtype='UUU' -> 'OFF01-1'
end if;
  
  set run_i = run_i + 1;  

end While ;



/*
 計算 @sql_p2,@sql_p4
 @sql_p2=",OFF01.offmins as OFF01,off01_1.offmins as off01_1,OFF02.offmins as OFF02 "

 @sql_p4="left join tmp_pool.tmp_ac525f6d_f2bc_11e3_8210_000c29364755 as OFF01 On a.empid=OFF01.empid and a.dutydate=OFF01.dutydate and OFF01.offtype='OFF01'
         left join tmp_pool.tmp_ac525f6d_f2bc_11e3_8210_000c29364755 as off01_1 On a.empid=off01_1.empid and a.dutydate=off01_1.dutydate and off01_1.offtype='off01-1'"
=============================================================== */

if inCRtable like 'tmp%' Then # 產生temp table 結果，只能使用tmp開頭名稱
  
  set @sql_output = concat("drop table if exists ",inCRtable,";");
   prepare s1 from @sql_output;
    execute s1;
 
  set @sql_output = concat(
          "create temporary table ",inCRtable," \n"
		 ,@sql_p1,@sql_p2,'\n'
         ,'from ',inTable,' AS A \n'
         ," ",@sql_p4) ;
   prepare s1 from @sql_output;
   execute s1;

end if ;


#### 結束、清除相關 temp table

if 1=1 then
   set @sql_tmpTable = concat("drop table ",@tmpTable,";");
   prepare s1 from @sql_tmpTable;
   execute s1;
end if;

#### 結束、清除相關 temp table 


END