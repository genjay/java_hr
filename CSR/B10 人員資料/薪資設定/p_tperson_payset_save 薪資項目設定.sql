drop procedure if exists p_tperson_payset_save;  # 人員薪資設定

delimiter $$

create procedure p_tperson_payset_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36)  
,in_Rwid   int
,in_EmpID  Varchar(36)
,in_TypeA06 varchar(36)
,in_PayMoney decimal(12,3)
,out outMsg text /*回傳訊息，直接給user看的*/
,out outRwid int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin
/*
執行範例  

*/

declare tlog_note text; 
declare isCnt int;
declare in_WorkGuid text;
set err_code =0;
set outRwid=0;
/*
set tlog_note= concat("call p_tworkrest_save(\n'"
,in_OUguid    ,"',\n'"
,in_ltUser    ,"',\n'"
,in_ltpid     ,"',\n'"  
,in_WorkID    ,"',\n'"  
,in_holiday   ,"',\n'"  
,in_stHHMM    ,"',\n'"  
,in_stNext    ,"',\n'"  
,in_enHHMM    ,"',\n'"  
,in_enNext    ,"',\n'"  
,in_CutTime   ,"',\n'"  
,in_Note      ,"',\n'"     
,in_Rwid      ,"',\n"
,'@a'         ,","
,'@b'         ,","
,'@c' 
,");");
*/

call p_tlog(in_ltPid,tlog_note);
set outMsg='p_tperson_payset_save,開始';

set outMsg= concat (in_Rwid,' ',in_EmpID,' ',in_TypeA06,' ',in_PayMoney);

if err_code=0 then # 10 判斷有無修改
  set isCnt=0;
  select rwid into isCnt from tperson_payset
where Empguid = (select empguid from tperson where ouguid=in_OUguid and empid=in_EmpID)
and a06_Guid = (select codeguid from tcatcode where ouguid=in_OUguid and syscode='A06' and codeID = in_TypeA06)
and PayMoney=in_PayMoney ;
  if isCnt>0 then set err_code=1; set outMsg='';/*無修改，不要顯示*/ end if;
end if; # 10

if err_code=0 && in_Rwid>0 then # 90 修改
  update tperson_payset set
   ltUser=in_ltUser,ltPid=in_ltPid,
   A06_Guid=(select codeguid from tcatcode where ouguid=in_OUguid and syscode='A06' and codeID=in_TypeA06)     
  ,PayMoney=in_PayMoney
  where rwid=in_Rwid;

end if;

if err_code=0 && in_Rwid=0 then # 90 新增

  Insert into tperson_payset 
  (ltUser,ltPid,Empguid,A06_Guid,PayMoney)
  select
  in_ltUser,in_ltpid
   ,(select empguid from tperson where ouguid=in_OUguid and empid=in_EmpID)
   ,(select codeguid from tcatcode where ouguid=in_OUguid and syscode='A06' and codeID=in_TypeA06)  
   ,in_PayMoney; 

end if;
 

end; # Begin