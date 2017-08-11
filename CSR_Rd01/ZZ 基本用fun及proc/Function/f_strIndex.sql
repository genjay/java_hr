drop function if exists f_strIndex;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` FUNCTION `f_strIndex`
(input_strA longtext,input_delim varchar(10),input_Int int) RETURNS text CHARSET utf8
BEGIN
 
/* f_strIndex('abe,eodk,koki',',',2)='eodk'
   f_strIndex('abc,ddd,eee',',',5)=null
*/
  
declare intA int default 0;
declare intB int default 0;
declare varB longtext default '';
declare varA longtext default '';
declare varC longtext default '';
 
Case 
When input_Int<=0 Then set varC=null ;
When input_Int =1 Then set varC=substring_index(input_strA,input_delim,1) ;
Else 
   set varA=substring_index(input_strA,input_delim,input_Int-1);
   set intA=length(varA);
 
   set varB=substring_index(input_strA,input_delim,input_Int);
   set intB=length(varB);
 
   
   if intB=intA and intB>0 /*已超過資料筆數*/ then set varC=null ;
   Else  set varC=substring(varB,-(intB-intA-1)); 
   end if;

end Case;



   -- RETURN (intA);
     RETURN (varC);
END