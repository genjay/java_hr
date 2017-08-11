drop procedure if exists p_tCatCode_reset_SEQ; # 分類碼刪除

delimiter $$

create procedure p_tCatCode_reset_SEQ
(
 in_OUguid  varchar(36)
,in_ltUser  varchar(36)
,in_ltpid   varchar(36) /*程式代號*/ 
,in_Syscode varchar(36) # syscode
,out outMsg  text /*回傳訊息，直接給user看的*/
,out outRwid  int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin
/* 
call p_tCatCode_reset_SEQ
(
 'microjet'
,'ltuser'
,'ltpid'
,'A00'
,@a
,@b
,@c
);

*/
declare tlog_note text;
declare droptable int default 1;
set err_code=0;
 
SET tlog_note= concat( "call p_tCatCode_reset_SEQ(\n'"
,in_OUguid  ,"',\n'"
,in_ltUser  ,"',\n'"
,in_ltpid   ,"',\n'"  
,in_Syscode  ,"',\n"
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");");

call p_tlog(in_ltPid,tlog_note); 
set outMsg='reset SEQ'; 

if err_code=0 Then # 10 產生新的 codeseq
  drop table if exists tmp01;
  create  table tmp01 as
  Select a.OUguid,a.Syscode,a.CodeID,@rownumESLLKJ:=@rownumESLLKJ+10 seq
  from (select * from tcatcode order by ouguid,syscode,codeseq) a
  left join (select @rownumESLLKJ:=0 ) c on 1=1
  where a.ouguid=in_OUguid and a.syscode=in_Syscode ;
end if;

if err_code=0 Then # 90 修改 tcatcode codeseq
  update tcatcode a,tmp01 b 
  set a.codeseq=b.seq
  where a.ouguid=b.ouguid and a.syscode=b.syscode and a.codeid=b.codeid;
end if;

if droptable=1 Then # drop temp table
  drop table if exists tmp01;
end if; # drop temp table
 
  
end # begin