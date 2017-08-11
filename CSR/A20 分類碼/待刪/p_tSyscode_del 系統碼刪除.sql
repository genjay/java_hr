drop procedure if exists p_tSysCode_del; # 分類碼存檔

delimiter $$

create procedure p_tSysCode_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/ 
,in_Rwid int  /*要修改的假單rwid*/
,out outMessage text /*回傳訊息，直接給user看的*/
,out outDupRWID int  /*重疊的請假單*/
,out outErr_code int /*成功失敗代碼*/
)

begin
/*

call p_tSysCode_del(
 'microjet'
,'user'
,'pid'
,12   #rwid  
,@a,@b,@c);
select @a,@b,@c;

*/
DECLARE err_code int default '0';

set @in_OUguid=in_OUguid;
set @in_ltUser =in_ltUser;
set @in_ltpid = in_ltpid;  
set @in_Rwid =in_Rwid;
set outMessage='';
set outDupRWID='0';

   IF err_code=0 and ifnull(in_OUguid,'')='' Then set err_code=1; set outMessage="OUguid 為必要輸入條件"; end if;
   IF err_code=0 and ifnull(in_rwid,0)=0     Then set err_code=1; set outMessage="rwid 不可為空白或零"; end if;

 IF err_code=0 Then # tcatcode
    set @isCnt=0;
    Select rwid into @isCnt from tcatcode where syscode=(select syscode from tsyscode where rwid=@in_rwid) limit 1;
    if @isCnt > 0 Then set err_code=1; set outMessage="此syscode已被catcode 使用，不能刪除"; set outDupRWID=@isCnt; end if;
 end if;

 IF err_code=0 Then # tcatcode2
    set @isCnt=0;
    Select rwid into @isCnt from tcatcode2 where syscode=(select syscode from tsyscode where rwid=@in_rwid) limit 1;
    if @isCnt > 0 Then set err_code=1; set outMessage="此syscode已被catcode2使用，不能刪除"; set outDupRWID=@isCnt; end if;
 end if;


 IF err_code=0 Then 
     Delete from tsyscode where rwid=@in_rwid 
     and Not 
       (syscode in (select syscode from tcatcode ) or 
        syscode in (select syscode from tcatcode2));

    set outMessage="刪除成功";
 end if;

 set outErr_code=err_code;
  
end