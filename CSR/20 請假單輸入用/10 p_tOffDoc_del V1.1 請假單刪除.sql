drop procedure if exists p_tOffDoc_del;

delimiter $$

create procedure p_tOffDoc_del
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
call p_tOffDoc_del
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
declare isCnt int;
declare in_CloseStatus int;
DECLARE EXIT HANDLER FOR SQLEXCEPTION#, SQLWARNING
BEGIN
    ROLLBACK;
END;
set err_code=0;
set outRwid=0;
set outMsg='p_tOffDoc_del 執行中';


IF err_code=0 Then # 10 判斷 @in_Rwid 單據是否存在、及是否關帳
   set isCnt=0;
   set in_CloseStatus=0;
   Select rwid,CloseStatus_z07 into isCnt,in_CloseStatus from tOffDoc Where rwid=in_Rwid 
    And EmpGuid in (Select EmpGuid from tperson Where OUguid=in_OUguid);
   if err_code=0 && isCnt=0 Then set err_code=1; set outMsg=concat("無此單據,單號：",in_Rwid); end if;
   if err_code=0 && in_CloseStatus=1 Then set err_code=1; set outMsg=concat("此單據已關帳、無法刪除",in_Rwid); end if;   
end if;

if err_code=0 then # 20 刪除資料
 
start TRANSACTION;
  delete from tOffQuota_used 
  Where OffDocGuid=(select offDocGuid from tOffdoc where  rwid = in_Rwid); 
  delete from toffdoc_duty
  where offdocguid = (select offdocguid from toffdoc where rwid = in_Rwid);
  delete from toffdoc 
  where CloseStatus_z07='0' #未關帳
  And empguid in (select empguid from tperson where ouguid=in_OUguid) # 該 OU的人員
  and rwid=in_Rwid; 
 
commit;
 
end if; # 20
 
end ; # begin