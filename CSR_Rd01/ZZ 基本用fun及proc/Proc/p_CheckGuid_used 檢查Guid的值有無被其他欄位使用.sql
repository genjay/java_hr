drop procedure if exists p_CheckGuid_used ;

delimiter $$

create procedure p_CheckGuid_used
(
 in_Table      varchar(36)        # 排除的Table
,in_Guid_ColumnName   varchar(36) # 此欄位結尾一定要是 guid
,in_GuidValue  varchar(36)
,out outMsg    text 
,out outRwid   int
,out err_code  int 
)
begin
/* 執行範例
call p_CheckGuid_used
(
 'tdept' # in_Table      varchar(36)
,'dep_guid' #,in_GuidName   varchar(36)
,'A4647CC3-6A16-474E-8EDB-0F900A00D9A5' #,in_GuidValue  varchar(36)
,@a #,out outMsg    text
,@b # outRwid
,@c # err_code
);
*/

declare strSql_All,strTable_All,strSql,strTable text;
declare i int default 1;

set err_code=0;

if err_code=0 then # 10 判斷是否被其他table 使用
/*
請複至到宣告處
declare strSql_All,strTable_All,strSql,strTable text;
declare i int default 1;
*/

 if @@group_concat_max_len<4294967295 then
   set group_concat_max_len=4294967295; # 32 bit 極限 太小Grou_concat 無法抓出所有資料
 end if;

set @in_codeGuid_749032=in_GuidValue;

select  
group_concat(
concat(
"select rwid into @isCnt_749032 from "
,a.table_name," "
," Where "
,a.column_name
,"= @in_codeGuid_749032 limit 1")
SEPARATOR ';'),group_concat(concat(a.table_name,'.',a.column_name) SEPARATOR ';')
into strSql_All,strTable_All
from information_schema.columns a
left join information_schema.tables b on a.table_schema=b.table_schema and a.table_name=b.table_name
Where  1=1 
  And a.table_name in (select table_name from information_schema.columns Where column_name='rwid') # 判斷屬於自己建立的table
  and a.table_schema=schema()
  and b.table_type='BASE TABLE' 
  and Not (a.table_name =in_Table and a.column_name=in_Guid_ColumnName) # 排除自己，否則陷入無限回圈
  and a.column_name like '%guid' ;

While i>0 Do # 10-01 While 
 set strSql  = f_strIndex(strSql_All,';',i);
 set strTable= f_strIndex(strTable_All,';',i);
 set i=i+1;
 if ifnull(strSql,'')='' Then set i=0; # 10-02
 else 
 set @strSql_749032=strSql; 
 set @isCnt_749032=0; 
 prepare s1 from @strSql_749032;
 execute s1; # 執行後，isCnt 會變成存成資料的rwid  
 if @isCnt_749032>0 Then  
  set i=0;set err_code=1; 
  set outRwid=@isCnt_749032; 
  set outMsg=concat(strTable,' 使用中，無法刪除',' rwid:',@isCnt_749032); 
 Else 
  set outMsg='未找到使用此值的table';
 end if;
 end if; # 10-02 
end While; # 10-01 

end if; # 10 

end ;