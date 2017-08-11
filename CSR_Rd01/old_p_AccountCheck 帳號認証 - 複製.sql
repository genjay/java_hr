drop procedure if exists p_AccountCheck;

delimiter $$

create procedure p_AccountCheck
(
 in_Aid         Varchar(4000)  # 帳號 Aid
,in_PassWd      Varchar(4000)  # 宓碼 
,in_login_info  varchar(4000)  # 登入相關訊息
,out outAidGuid Varchar(36)    # 帳號的Guid  
,out outlistOU  text # 回傳可選擇OU
,out outMsg     text # 回傳訊息
,out outRwid    int  # 回傳單據號，新增單號、錯誤單號
,out err_code   int  # err_code
)

begin
declare is_Cnt,is_Change_PWD int ;
declare is_PassWd text;  
declare is_Valid_st,is_Valid_end datetime;
 
 set err_code=0;
/*

 call p_AccountCheck
(
 'a00514'
,'1234'
,'192.168.10.10'
,@AidGuid 
,@outRestPSW
,@a,@b,@c);

select @Aidguid,@OUlis_t,@a,@b,@c;
*/

set outMsg='p_AccountCheck開始執行';

if err_code=0 then # 10 取得帳號資料
  set is_Cnt=0;
  Select  rwid,PassWd,Change_PWD,Valid_st,Valid_end,Aid_Guid
    into is_Cnt,is_PassWd,is_Change_PWD,is_Valid_st,is_Valid_end,outAidGuid
  from tAccount Where Aid=in_Aid ;
  if is_Cnt=0 Then set err_code=1; set outMsg='帳號錯誤'; end if;
end if; # 10

if err_code=0 then
 if is_PassWd=Sha(in_PassWD) 
    then set outMsg='帳密正確';
    else set err_code=2; set outMsg='密碼錯誤'; 
 end if;
end if; # 20

if err_code=0 then
 if is_Change_PWD=1 then set err_code=3; set outMsg='請先變更密碼'; end if;  
end if;

if err_code=0 then
 if is_Valid_st< now() And IFNULL(is_Valid_end,'9999-12-31') > now() 
   then set outMsg='時間有效';
   else set err_code=4 ;set outMsg='帳號過期';   
 end if;
end if; 


if err_code=0 then # 90 回傳可登入 OU 清單
  Select group_concat(concat(OUid,',',ouName)) into outlistOU
  from tAccount a
  left join tAccount_ou b on a.aid_guid=b.aid_guid
  left join tOUset c on b.OUguid=c.OUguid
  where a.aid=in_Aid;
end if; # 90  

if 1=1 then # 99 log 記錄
  Insert into tlog_login (login_id,aid_guid,login_info,login_err_code,login_outmsg )
  Values (in_Aid,outAidGuid,in_login_info,err_code,outMsg);
end if; # 99 log 記錄


end;