drop procedure if exists p_tforgetdoc_del;

delimiter $$

create procedure p_tforgetdoc_del
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
declare in_CloseStatus_z07 text;
declare in_Close_Date date;
DECLARE EXIT HANDLER FOR SQLEXCEPTION#, SQLWARNING
BEGIN
    ROLLBACK;
END;
set err_code=0;
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

IF err_code=0 Then # 10 判斷 in_Rwid 單據是否存在，
   set isCnt=0;
   set in_CloseStatus_z07=0;
   Select rwid,CloseStatus_z07 into isCnt,in_CloseStatus_z07 from tforgetdoc 
   Where rwid=in_Rwid And EmpGuid in (Select EmpGuid from tperson Where OUguid=in_OUguid);
   if err_code=0 && isCnt=0 Then set err_code=1; set outMsg=concat(in_Rwid," 無此單據"); end if;
   if err_code=0 && in_CloseStatus_z07!='0' Then set err_code=1; set outMsg=concat(in_Rwid," 此單據已關帳、無法刪除"); end if;   
end if;
 
if err_code=0 Then # 90 刪除資料
  delete from tforgetdoc where CloseStatus_z07='0' And rwid=in_Rwid ;
  set outMsg=concat(in_Rwid,' 刪除完成'); set outRwid=in_Rwid;
end if; # 90 刪除資料
 

end;