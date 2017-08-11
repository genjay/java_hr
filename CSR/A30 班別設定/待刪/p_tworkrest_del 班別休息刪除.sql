drop procedure if exists p_tworkrest_del;

delimiter $$

create procedure p_tworkrest_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36)  
,in_Rwid int  /*要修改的單據rwid*/
,out outMsg text /*回傳訊息，直接給user看的*/
,out outRwid int  /*重疊的請假單*/
,out outErrCode int /*成功失敗代碼*/
)

begin
/*
執行範例 
call p_tworkrest_save
(
 'microjet' #ouguid
,'in_ltUser' # ltUser
,'in_ltpid' # ltpid 
,'A' # workID
,'0' # holiday
,'07:00:00' # in_stHHMM time
,'0' # in_stNext int -1/0/1
,'07:10:00' # in_enHHMM time
,'0' #in_enNext int -1/0/1
,'0' # cuttime 0/1
,'Note ' # 備註
,'0' # inRwid int  要修改的單據，放 0，就可以
,@outMessage #回傳訊息，直接給user看的
,@outDupRWID #重疊的請假單
,@outErr_code #成功失敗代碼
);

*/

DECLARE err_code int default '0';

set @in_OUguid = in_OUguid;
set @in_ltUser = in_ltUser;
set @in_ltpid = in_ltpid;
set @in_Rwid=in_Rwid;
 
delete  from tworkrest 
where rwid=@in_Rwid ;


end;