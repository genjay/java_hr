drop procedure if exists p_tOvertype_del;

delimiter $$

create procedure p_tOvertype_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36)  
,in_Rwid   int  # 單據Rwid
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)

begin
/*
執行範例 
call p_tforgetdoc_del
(
 'microjet'
,'ltuser'
,'ltpid'
,10   #rwid
,@a
,@b
,@c
);


*/ 
declare tlog_note text; 
declare tmpA,tmpB,tmpC text;
declare isCnt int;
set err_code=0;
SET tlog_note= concat( "call p_tOvertype_del(\n'"
,in_OUguid  ,"',\n'"
,in_ltUser  ,"',\n'"
,in_ltpid   ,"',\n'"  
,in_Rwid  ,"',\n"
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");");
call p_tlog('p_tOvertype_del',tlog_note);
set outMsg='p_tOvertype_del 執行開始';

if err_code=0 Then # 10 
  set isCnt=0;
  Select rwid into isCnt from tOvertype Where Overtypeguid in (select codeguid from tcatcode where OUguid=in_OUguid) And Rwid=in_Rwid;
  if isCnt=0 Then set err_code=1; set outMsg='此設定不存在'; end if;
end if; # 10
 
IF err_code=0 Then # 20 判斷要刪除的設定，是否被使用
   set isCnt=0; set outMsg='20 判斷要刪除的設定，是否被使用';
   Select rwid into isCnt from tOverdoc 
   Where overTypeGuid = (select overTypeGuid from tOvertype where rwid=in_Rwid) limit 1;
   if isCnt>0 Then set err_code=1; set outMsg="此設定已被使用(tOverdoc)"; end if;
end if; # 20 判斷要刪除的設定，是否被使用

IF err_code=0 Then # 90 刪除
  set outMsg='90 刪除中';  
   Select rwid into isCnt From tcatcode Where codeguid in (
   Select Overtypeguid from tOvertype Where rwid=in_Rwid) limit 1;
   delete from tOvertype Where rwid=in_Rwid;
   set outMsg='tOvertype 刪除完成，準備刪除tCatCode';
  call p_tCatCode_del
  (
   in_OUguid,in_ltUser,in_ltpid
  ,isCnt   # tcatcode.rwid
  ,tmpA,tmpB,tmpC
  );
  if tmpC=0 Then set outMsg  = tmpA; set outRwid = in_Rwid; 
  Else set err_code=1; set outMsg= 'CatCode 刪除失敗'; End if;
end if; # 90 刪除

end;