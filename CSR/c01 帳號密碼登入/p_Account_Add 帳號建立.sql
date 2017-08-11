drop procedure if exists p_Account_Add;

delimiter $$

create procedure p_Account_Add
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltPid  varchar(36)
,in_Aid        Varchar(4000)  # 帳號 Aid
,in_Valid_st   varchar(36)    # 生效日 
,in_NewPassWd  Varchar(4000)   # 宓碼   
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)

begin
declare isCnt int ;
declare inPassWD_min int;
declare inPassWd_Max int;
set err_code=0;
set outMsg='p_Account_Add 開始';
 
if err_code=0 then # 10 判斷帳號是否存在
  set isCnt=0;
  Select rwid into isCnt from tAccount where aid=in_Aid;
  if isCnt>0 then set err_code=1; set outMsg=concat(in_Aid,'帳號已存在'); end if;
end if;

IF err_code=0 Then # 15 判斷新宓碼
  Select PassWD_length_min,PassWD_length_max into inPassWD_min,inPassWd_Max from tSystem_set where systemName='default';
  if length(in_NewPassWd) < inPassWD_min Then set err_code=1; set outMsg=concat('新密碼過短，要超過 ',inPassWD_min,'碼'); end if;
  if length(in_NewPassWd) > inPassWD_max Then set err_code=1; set outMsg=concat('新密碼過長，要小於 ',inPassWD_max,'碼'); end if;
end if; # 15

if err_code=0 Then # 90 修改宓碼
 Insert into tAccount
 (Aid_Guid,Aid,Valid_St,PassWD)
 Values
 (uuid(),in_Aid,in_Valid_st,sha(in_NewPassWd));
end if;


end;