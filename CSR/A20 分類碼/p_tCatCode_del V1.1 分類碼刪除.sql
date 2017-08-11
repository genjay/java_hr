drop procedure if exists p_tCatCode_del; # 分類碼刪除

delimiter $$

create procedure p_tCatCode_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/ 
,in_Rwid      int  /*要修改的單據rwid*/
,out outMsg  text /*回傳訊息，直接給user看的*/
,out outRwid  int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin
/* 
call p_tCatCode_del
(
 'microjet'
,'ltuser'
,'ltpid'
,33   # tcatcode.rwid
,@a
,@b
,@c
);

*/
 
declare tlog_note text; 
declare codetype  text;
declare isCnt int; 
declare strSql_All text;
declare strSql text;
declare strTable_All text;
declare strTable text;
declare i int default 1;
declare debug int default 1; # 0正常/1除錯
set err_code=0;
set in_OUguid=IFNULL(in_OUguid,''); 
SET in_ltUser=IFNULL(in_ltUser,'');
SET in_ltpid =IFNULL(in_ltpid,''); 
SET in_Rwid  =IFNULL(in_Rwid,0);  
call p_sysset(1);

SET tlog_note= concat( "call p_tCatCode_del(\n'"
,in_OUguid  ,"',\n'"
,in_ltUser  ,"',\n'"
,in_ltpid   ,"',\n'"  
,in_Rwid  ,"',\n"
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");");

call p_tlog(in_ltPid,tlog_note); 

if err_code=0 Then # 05 判斷 Syscode like 'Z%'時
  set isCnt=0; set outMsg='05 Syscode為Z開頭時，只能修改說明、新增';
  Select rwid into isCnt from tCatcode Where  Rwid=in_Rwid And SysCode like 'Z%'; 
  if isCnt>0 Then set err_code=1; set outMsg='Sysocde為Z開頭，系統用不能刪除'; end if;
end if; # 05

if err_code=0 then # 00 檢查ouguid
  if ifnull(in_OUguid,'')='' Then set err_code=1; set outMsg='OUguid為必要條件'; end if;
end if;

if err_code=0 Then # 05 抓@in_codeGuid_749032_749032
  set isCnt=0;
  select count(*),codeGuid into isCnt,@in_codeGuid_749032 from tcatcode where ouguid=in_ouguid and rwid=in_rwid;
  if isCnt=0 Then set err_code=1; set outMsg="無此筆資料"; end if; 
end if;

 
if err_code=0 then # 10 判斷是否被其他table 使用
select  
group_concat(
concat(
"select 1 rwid into @isCnt_749032 from "
,a.table_name," "
," Where "
,a.column_name
,"= @in_codeGuid_749032 limit 1")
SEPARATOR ';'),group_concat(a.table_name SEPARATOR ';')
into strSql_All,strTable_All
from information_schema.columns a
left join information_schema.tables b on a.table_schema=b.table_schema and a.table_name=b.table_name
Where  1=1 
  And a.table_name in (select table_name from information_schema.columns Where column_name='rwid')
  and a.table_schema=schema()
  and b.table_type='BASE TABLE' 
  and Not a.table_name in ('tcatcode')
  and a.column_name like '%guid' ;

While i>0 Do # 10-01 While 
 set strSql = f_strIndex(strSql_All,';',i);
 set strTable= f_strIndex(strTable_All,';',i);
 set i=i+1;
 if ifnull(strSql,'')='' Then set i=0; # 10-02
 else 
 set @strSql_749032=strSql;
 if debug=1 Then call p_tlog(in_ltpid,strSql); end if; # 除錯用
 set @isCnt_749032=0; 
 prepare s1 from @strSql_749032;
 execute s1; # 執行後，isCnt 會變成存成資料的rwid  
 if @isCnt_749032>0 Then 
  Select concat(codeid) into codetype from tcatcode where rwid=in_Rwid; 
 set i=0;set err_code=1; set outMsg=concat('「',codetype,'」',strTable,'使用中，無法刪除'); set outRwid=in_Rwid; end if;
 end if; # 10-02 
end While; # 10-01 
end if; # 10 

if err_code=0 then # 90 刪除
  Select concat(codeid) into codetype 
  from tcatcode where rwid=in_Rwid;    
  delete from tcatcode where rwid=in_Rwid And ouguid=in_OUguid;
  set outMsg=concat('「',codetype,'」','刪除成功'); set outRwid=in_Rwid;
end if; 
 
 
  
end # begin