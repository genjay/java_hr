drop procedure if exists p_AccountCheck;

delimiter $$

create procedure p_AccountCheck
(
 in_Aid     Varchar(4000)  # 帳號 Aid
,in_PassWd  Varchar(4000)  # 宓碼 
,out outAidGuid Varchar(36) # 帳號的Guid 
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)

begin
declare isCnt int ;
 set err_code=0;
/*
call p_AccountCheck
(
 'a00514@microjet.com.tw'
,'1234'
,@AidGuid 
,@a,@b,@c);

select @Aidguid,@OUlist,@a,@b,@c;
*/

set outMsg='p_AccountCheck開始執行';

if err_code=0 then # 10 判斷帳號
  set isCnt=0;
  Select rwid into isCnt from tAccount Where Aid=in_Aid ;
  if isCnt=0 Then set err_code=1; set outMsg='帳號錯誤'; end if;
end if; # 10

if err_code=0 then # 15 宓碼為空
  set isCnt=0;
  Select rwid into isCnt from tAccount Where Aid=in_Aid And IFNULL(PassWd,'')='';
  if isCnt>0 Then set err_code=2; set outMsg='請先變更密碼'; end if;
end if;

if err_code=0 Then # 20 判斷宓碼
  set isCnt=0;
  Select rwid into isCnt from tAccount Where Aid=in_Aid and PassWd=Sha(in_PassWD);
  if isCnt=0 then set err_code=1; set outMsg='密碼錯誤'; 
   else set outMsg='帳密正確'; end if;
end if; # 20

if err_code=0 Then # 30 有效時間判斷
  set isCnt=0;
  Select rwid into isCnt from tAccount Where Aid=in_Aid and PassWd=Sha(in_PassWD)
  And Valid_st< now() And IFNULL(Valid_end,'9999-12-31') > now();
  IF isCnt=0 Then set err_code=1 ;set outMsg='帳號過期'; end if;
end if;

if err_code=0 Then # 40 抓Aid_Guid
  Select Aid_Guid into outAidGuid from tAccount Where Aid=in_Aid ;
 
end if; # 40

end;