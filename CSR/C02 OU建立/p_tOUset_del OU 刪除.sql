drop procedure if exists p_tOUset_del;

delimiter $$

create procedure p_tOUset_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) 
,in_Rwid   int     # 單據的Rwid
,out outMsg   text /*回傳訊息，直接給user看的*/
,out outRwid  int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin 
declare isCnt int;
declare in_Del_OUguid,in_Del_ID varchar(36);
declare strSql_All,strSql,strTable_All,strTable text; 
declare i int default 1;
set err_code=0;
set outRwid=0;
set outMsg='p_tOUset_save 執行中';

call p_sysset(1);

if err_code=0 then # 10
  set in_Del_OUguid=''; set in_Del_ID='';
  Select OUguid,OUid into in_Del_OUguid,in_Del_ID from tOUset Where rwid=in_Rwid;
  if in_Del_OUguid='' then set err_code=1; set outMsg='無此資料'; end if;
end if; # 10

if err_code=0 then # 20 
  Select 
  Group_concat(
  concat('Select rwid into  @isCnt_p_tOUset_del from ',a.table_name,' Where OUguid=\'',in_Del_OUguid,'\' limit 1') SEPARATOR ';')
  ,group_concat(a.table_name SEPARATOR ';')
  into strSql_All,strTable_All
  from information_schema.columns a 
  left join information_schema.tables b on a.table_schema=b.table_schema and a.table_name=b.table_name
  where a.table_schema=schema()
    and b.table_type='BASE TABLE' 
    and Not a.table_name in ('tOUset')
    And a.column_name = 'OUguid';

While i>0 Do # 10-01 While 
 set strSql = f_strIndex(strSql_All,';',i);
 set strTable= f_strIndex(strTable_All,';',i);
 set i=i+1; 
 if ifnull(strSql,'')='' Then set i=0; # 10-02
 else 
 set @strSql_p_tOUset_del=strSql;
--  if debug=1 Then call p_tlog(in_ltpid,strSql); end if; # 除錯用 
 set @isCnt_p_tOUset_del=0; 
 prepare s1 from @strSql_p_tOUset_del;
 execute s1; # 執行後，isCnt 會變成存成資料的rwid  
 if @isCnt_p_tOUset_del>0 Then 
   
 set i=0;set err_code=1; set outMsg=concat('「',in_Del_ID,'」',strTable,'使用中，無法刪除'); set outRwid=in_Rwid; end if;
 end if; # 10-02 
end While; # 10-01 

end if; # 20

if err_code=0 then # 90
  delete from tOUset Where Rwid=in_Rwid;
  set outMsg=concat('「',in_Del_ID,'」','已刪除');
end if; # 90



end; # Begin