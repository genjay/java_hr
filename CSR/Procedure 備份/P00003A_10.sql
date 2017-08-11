DELIMITER $$
CREATE DEFINER=`sa`@`%` PROCEDURE `P00003A_10`(IN inSTR_A TEXT,IN inSTR_B text,IN inSTR_C text,IN inSTR_D varchar(255),inSTR_E varchar(255)
,out sOUT text)
BEGIN


-- P00003A 將view 象樞杻方式轉置
-- call P00003A_20('empid,dutydate','offtype','offmins','voffduty','displaysort',@x);
-- 除第一欄可以多欄位外，其它部份目前只設計成一欄位
-- 用來產生left join ... 部分的sql

declare strA text default "";
declare strB text default "";
declare strC text default ""; 
declare run_i int default 1; /*loop 執行控制用*/ 

While run_i > 0 do 

 IF run_i=1 Then 

  set @A1=f_strIndex(inSTR_A,',',run_i);
  set strA=concat("left join voffduty as XXX ON XXX.offtype='XXX' AND XXX.",@A1,"=A.",@A1 ) ;
  set strB=strA;
  end if;

 set run_i=run_i+1;
 set @A2=f_strIndex(inSTR_A,',',run_i);

 IF @A2 is NULL 
 Then /*最後一筆*/
       set run_i= 0;
	   set strB=concat(strB,"\n");
 else 
       Set strB=concat(strB," And XXX.",@A2,"=A.",@A2); 
 end if;

  set strC=concat(strB);

end While;
 
 
set sOUT=strC;
  

END$$
DELIMITER ;
