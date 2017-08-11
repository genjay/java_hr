drop procedure if exists p_ChangePassWD;

delimiter $$

create procedure p_ChangePassWD
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_Aid        Varchar(4000)  # 帳號 Aid
,in_OldPassWd  Varchar(4000)   # 宓碼  
,in_NewPassWd  Varchar(4000)   # 新密碼
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)

begin
declare isCnt int ;
declare inPassWD_min int;
declare inPassWd_Max int;
declare in_Aid_Guid varchar(36);
set err_code=0;
set outMsg='p_AccountChange 開始';
 
if err_code=0 then # 10 判斷新舊密碼是否一樣
  if in_OldPassWd=in_NewPassWd 
    Then set err_code=1; set outMsg='新舊密碼不可一樣'; 
    else set outMsg='Pass-新舊密碼不同';end if;
end if;

IF err_code=0 Then # 15 判斷新宓碼
  Select PassWD_length_min,PassWD_length_max into inPassWD_min,inPassWd_Max 
  from tSystem_set where systemName='default';
  if length(in_NewPassWd) < inPassWD_min Then set err_code=1; set outMsg=concat('新密碼過短，要超過 ',inPassWD_min,'碼'); end if;
  if length(in_NewPassWd) > inPassWD_max Then set err_code=1; set outMsg=concat('新密碼過長，要小於 ',inPassWD_max,'碼'); end if;
end if; # 15

if err_code=0 Then # 20 判斷有無此帳號
  set isCnt=0;
  Select rwid,Aid_Guid into isCnt,in_Aid_Guid From tAccount 
  Where (Aid=in_Aid);
  if isCnt=0 Then set err_code=1; set outMsg='帳號不存在'; end if;
 
end if; # 20

if err_code=0 Then # 30 判斷舊密碼正確性
  set isCnt=0;
  Select rwid into isCnt From tAccount 
  Where Aid_Guid=in_Aid_Guid 
    And IFNULL(PassWD,'') in ('',Sha(in_OldPassWd));
  if isCnt=0 Then set err_code=1; set outMsg='舊密碼錯誤'; else set outMsg='Pass-舊密碼核對';end if;

end if;

if err_code=0 Then # 90 修改宓碼
  Update tAccount set PassWD=Sha(in_NewPassWd),Change_PWD=0
  Where Aid_Guid=in_Aid_Guid;
  set outMsg='密碼修改完成';
end if;


end;