-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`sa`@`%` PROCEDURE `P00003A_20`(IN inSTR_A TEXT,IN inSTR_B text,IN inSTR_C text,IN inSTR_D varchar(255),inSTR_E varchar(255)
,out sOUT text)
BEGIN


-- P00003A 將view 象樞杻方式轉置
-- P00003A('empid,dutydate','offtype','offmins','voffduty',@x);
-- 除第一欄可以多欄位外，其它部份目前只設計成一欄位
-- 用來產生left join ... 部分的sql

 declare strA text default ""; /*Select ... 部份*/
 declare strB text default ""; /*from ... 部份*/
 declare strC text default ""; /*left join ... 部份*/
declare run_i int default 1; /*loop 執行控制用*/ 

drop table if exists tmp00003A_20;

 Set @sql= concat("Create table tmp00003A_20 As 
 Select group_concat(distinct ",inSTR_B," Order by ",inSTR_E,") as x1 ",
  " From ",inSTR_D);

/* 因為execute 無法傳 table 變數，所以先產生tmp table 
   再從tmp table 撈出資料
*/

call P00003A_10(inSTR_A,inSTR_B,inSTR_C ,inSTR_D,inSTR_E,@strPartC );
 
 prepare s1 from @sql;
 execute s1 ;

 select x1 into @A1 from tmp00003A_20 ;

 While run_i>0 do 
  set @B1=f_strIndex(@A1,run_i);
  if @B1 is null Then set run_i=0; /*停止*/
   else 
    if run_i=1 
     then 
      set @C1=concat("A.",replace(inSTR_A,',',",A."));
      set @PartC=replace(@strPartC,'XXX',@B1);
	 else 
      set @C1=concat(ifnull(@C1,''),',',@B1,".",inSTR_C  -- a.empid,a.dutydate,off01.offmins
        ," as ",@B1); 

	  set @PartC=replace(concat(@PartC,@strPartC),'XXX',@B1);
	  
    end if;
	set run_i=run_i+1;
  end if;
   
  
end while;

 set sOUT=@C1;

END