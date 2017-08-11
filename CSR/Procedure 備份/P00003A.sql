DELIMITER $$
CREATE DEFINER=`sa`@`%` PROCEDURE `P00003A`(IN inSTR_A TEXT,IN inSTR_B text,IN inSTR_C text,IN inSTR_D varchar(255),inSTR_E varchar(255)
,out sOUT varchar(5000))
BEGIN


-- P00003A 將view 象樞杻方式轉置
-- call P00003A_20('empid,dutydate','offtype','offmins','voffduty','displaysort',@x);
-- 除第一欄可以多欄位外，其它部份目前只設計成一欄位
-- 用來產生left join ... 部分的sql

 declare strPartA text default ""; /*Select ... 部份*/
 declare strPartB text default ""; /*from ... 部份*/
 declare strPartC text default "";/*left join ... 部份*/
 declare run_i int default 1; /*loop 執行控制用*/ 

drop table if exists tmpA_P00003;

 Set @sql= concat("Create temporary table tmpA_P00003 As 
 Select group_concat(distinct ",inSTR_B," Order by ",inSTR_E,") as x1 ",
  " From ",inSTR_D);

/* 因為execute 無法傳 table 變數，所以先產生tmp table 
   再從tmp table 撈出資料
*/

call P00003A_10(inSTR_A,inSTR_B,inSTR_C ,inSTR_D,inSTR_E,@C );
 
 prepare s1 from @sql;
 execute s1 ;

 DEALLOCATE PREPARE s1;

 select x1 into @A1 from tmpA_P00003 ;

 drop table tmpA_P00003;

 Set strPartA=concat("Select A.",replace(inSTR_A,',',',A.'));

 Set strPartB=concat("From ",inSTR_D," A \n");
 

 /*@A1 = 'OFF01,OFF02,OFF03'*/

 While run_i>0 do
  Set @B1=f_strIndex(@A1,',',run_i);
  Set run_i=run_i+1;
  IF @B1 IS NULL THEN
   SET run_i=0;
   Set strPartA=concat(strPartA,"\n");
   Else 
	Set strPartA=concat(strPartA,",",@B1,".",inSTR_C," ",@B1);
    Set strPartC=concat(ifnull(strPartC,''),replace(@C,'XXX',@B1),'\n');
  End if;
  
 end While;

 set sOUT= concat("create view vt99 AS ",strPartA,strPartB,strPartC);

if   1=1 then 
 set @sql2=sOUT;
 
 drop view if exists vt99;
 prepare s2 from @sql2;
 execute s2 ;

 DEALLOCATE PREPARE s2;
end if;

END$$
DELIMITER ;
