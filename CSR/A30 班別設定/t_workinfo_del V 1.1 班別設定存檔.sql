drop procedure if exists p_tworkinfo_del;

delimiter $$

create procedure p_tworkinfo_del
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
declare isCnt int;
declare in_Workguid varchar(36);
declare tmpA,tmpB,tmpC text;
declare tlog_note text;
set err_code=0;

SET tlog_note= concat( "call p_tworkinfo_del(\n'"
,in_OUguid  ,"',\n'"
,in_ltUser  ,"',\n'"
,in_ltpid   ,"',\n'"  
,in_Rwid  ,"',\n"
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");");

call p_tlog(in_ltPid,tlog_note);

if err_code=0 then
  if ifnull(in_OUguid,'')='' then set err_code=1; set outMsg='OUguid為必要條件'; end if;
end if;


if err_code=0 Then # 00 抓 workguid
   set in_Workguid='';
   set outMsg='00 抓 workguid';
   Select WorkGuid into in_Workguid from tworkinfo Where rwid=in_Rwid;
   if in_Workguid='' Then set err_code=1; set outMsg=concat("此筆資料不存在，單號：",in_Rwid); end if;
end if; # 00

if err_code=0 Then # 10 判斷有沒有被tSchDep 使用
   set isCnt=0; set outMsg='10 判斷有沒有被tSchDep 使用';
   Select rwid into isCnt from tSchDep Where workguid=in_Workguid limit 1;
   if isCnt>0 Then set err_code=1; set outMsg="此班別已被部門班別(tSchDep)使用，無法刪除"; end if;
end if; # 10 

if err_code=0 Then # 20 判斷有沒有被tSchEmp 使用
   set isCnt=0; set outMsg='20 判斷有沒有被tSchEmp 使用';
   Select rwid into isCnt from tSchEmp Where workguid=in_Workguid limit 1;
   if isCnt>0 Then set err_code=1; set outMsg="此班別已被個人班別(tSchEmp)使用，無法刪除"; end if;
end if; # A02 

if err_code=0 Then # 30
   set isCnt=0; set outMsg='30 判斷有沒有被tduty_A 使用';
   Select rwid into isCnt from tduty_a Where workguid=in_Workguid limit 1;
   if isCnt>0 Then set err_code=1; set outMsg="此班別已被(tDuty_a)使用，無法刪除"; end if;
end if; # 30

if err_code=0 Then # 40 有休息時刻表不能刪
   set isCnt=0; set outMsg='40 有休息時刻表不能刪';
   Select rwid into isCnt From tworkrest Where workguid=in_Workguid limit 1;
   if isCnt > 0 Then set err_code=1; set outMsg="已經休息時刻表"; end if;
end if; # 00

if err_code=0 Then # 90 刪除
  Select rwid into isCnt from tcatcode Where codeGuid=in_Workguid limit 1;
  call p_tlog('ll','刪除tcatcode前');
   delete from tworkinfo Where rwid=in_Rwid
   and 
   Not (workguid in (select workguid from tSchDep)
    and workguid in (select workguid from tSchEmp)
    and workguid in (select workguid from tduty_a));

  call p_tCatCode_del(in_OUguid,in_ltUser,in_ltpid,isCnt
        ,tmpA,tmpB,tmpC);
  set outMsg='成功';

end if;

end # Begin
