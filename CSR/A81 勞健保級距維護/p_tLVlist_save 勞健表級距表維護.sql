drop procedure if exists p_tLVlist_save;

delimiter $$

create procedure p_tLVlist_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_Valid_St date
,in_type_Z18 varchar(36)
,in_m_Amt     text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)

begin
declare isCnt int; 
declare strA text;
declare isDel int default 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION#, SQLWARNING
BEGIN
    ROLLBACK;
END;
set err_code=0; 
set outMsg='p_tLVlist_save 執行中';

set outMsg=in_m_Amt;
  set strA=concat('(',replace(in_m_Amt,',','),('),')');
  set strA=replace(strA,',( )','');
  set strA=replace(strA,'(),','');
set outMsg=strA; 

if err_code=0 && strA='()' then # 40 若strA='()'代表刪除模式
  set isDel=1; 
end if; # 40

if err_code=0 && isDel=0   then # 50
  drop table if exists tmp01;
  Create /*temporary*/ table tmp01 
  (Amt int);
  

  set @sql=concat('insert into tmp01 (Amt) Values ',
  strA  ,';');
   prepare s1 from @sql;
   execute s1;

 set outMsg=@sql;
 -- set outMsg=concat(in_Valid_St,in_type_Z18);
end if; # 50

if err_code=0 then # 90
  delete from tlvlist
  where OUguid=in_OUguid And Valid_St=in_Valid_St And type_z18=in_type_Z18;

  if isDel=0 then 
  Insert into tLvlist
  (Valid_st,type_z18,m_Amt,OUguid)
  Select distinct in_Valid_St,in_type_Z18,Amt,in_OUguid from tmp01;
  end if;

end if; # 90 

end; #begin