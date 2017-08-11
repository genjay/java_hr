delimiter $$

drop function if exists f_strIndex$$

CREATE DEFINER=`root`@`localhost` FUNCTION `f_strIndex`
(input_strA text,input_Int int) RETURNS text
BEGIN
 
/* f_strIndex('abe,eodk,koki',2)='eodk'
   f_strIndex('abc,ddd,eee',5)=null
*/
 

declare intA int default 0;
declare intB int default 0;
declare varB text default '';
declare varA text default '';
declare varC text default '';

  if input_Int = 1 then set varC=substring_index(input_strA,',',1) ;

  else 
   set varA=substring_index(input_strA,',',input_Int-1);
   set intA=length(varA);
 
   set varB=substring_index(input_strA,',',input_Int);
   set intB=length(varB);
   set varC=substring(varB,-(intB-intA-1));
   
  end if ;

   if intB=intA and intB>0 then set varC=null;  end if;

   -- RETURN (intA);
     RETURN (varC);
END$$

