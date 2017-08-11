drop procedure if exists p_Account_resetPWD;

delimiter $$

create procedure p_Account_resetPWD
(
 in_AidGuid    Varchar(4000)  # 帳號 Aid or Aid_Guid
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)

begin
declare isCnt int ; 
set err_code=0;
set outMsg='p_AccountChange 開始';
/*
call p_Account_resetPWD
(
 'a000514@microjet.com.tw'
,@a,@b,@c
);

select @a,@b,@c;
*/

if err_code=0 Then # 10
  set isCnt=0; set outMsg='帳號判斷';
  Select rwid into isCnt from tAccount Where (Aid_Guid=in_AidGuid or Aid=in_AidGuid);
  if isCnt=0 Then set err_code=1; set outMsg='無此帳號'; end if;
end if; # 10

if err_code=0 Then # 90
  update tAccount set PassWD=SHA('1234') Where Rwid=isCnt;
  set outMsg='密碼重設完成';
end if;

end;