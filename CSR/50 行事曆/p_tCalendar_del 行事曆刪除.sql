drop procedure if exists p_tCalendar_del; # 行事曆刪除

delimiter $$

create procedure p_tCalendar_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/
,in_Rwid int  /*要修改單rwid*/
,out outMessage text /*回傳訊息，直接給user看的*/
,out outDupRWID int  /*重疊的請假單*/
,out outErr_code int /*成功失敗代碼*/
)

begin
/*
執行範例 

*/

DECLARE err_code int default '0'; 

set @in_OUguid = in_OUguid;
set @in_ltUser = in_ltUser;
set @in_ltpid = if(trim(in_ltpid)='','p_tCalendar_del',in_ltpid);
set @in_Rwid = in_Rwid; 

 call p_SysSet(1); #設定
  
Case 
/*不需連資料庫的錯誤類型*/
When IFNULL(in_OUguid,'')=''  
 Then set outMessage="in_OUguid錯誤，請重新輸入";
      set err_code= 1;


Else /*需要連資料庫判斷的錯誤類型*/
###################################################################
 IF err_code = 0 And in_Rwid = 0 Then # x01

    set outMessage="rwid 錯誤，請重新輸入";
    set err_code= 1;

  end if; # x01

  IF err_code=0 And in_Rwid > 0 Then # x02

     set @isCnt=0;
     select rwid into @isCnt from tcalendar Where rwid=@in_rwid 
       and calguid in (select codeguid from tcatcode where ouguid=@in_OUguid);
     if @isCnt=0 then # X03 @isCnt=0 代表無資料
        set err_code=1;
        set outMessage="無此rwid資料";
     end if ; # X03 

  end if; # x02


end  case ;

###### 以下為判斷正確性後，進入新增、修改階段

IF err_code = 0 And in_Rwid > 0 Then # 輸入資料無誤時，執行
  
  delete from tcalendar 
  Where rwid = @in_Rwid
    and calGuid in (select codeGuid from tcatcode where ouguid=@in_OUguid); 
  
  set @Change_RWID = @in_Rwid ; /*修改時，rwid等於 in_Rwid*/
  set outMessage = "資料刪除成功";

end if; #  

set outErr_code = err_code;

IF err_code = 0 Then # 錯誤碼為 0時，執行相關程式用
  set @x=1;  # 無意義，可刪除，若語法無錯時
end if;
 

 call p_SysSet(0); #還原
end;