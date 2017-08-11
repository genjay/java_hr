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
	Select count(*),group_concat(concat(b.OUid,',',b.ouName) order by OUid)
	into is_Cnt,outlistOU
	from tAccount_OU a
	left join tOUset b on a.OUguid=b.OUguid
	Where a.Aid=in_Aid and a.PassWd=Sha(in_PassWD) 
	and a.Valid_st < now()
	and ifnull(a.Valid_end,'9999-12-31 23:59')> now();
	if is_Cnt=0 Then set err_code=1; set outMsg='帳密錯誤';
	else set outMsg='認証通過';end if;
end if; # 10

if 1 then
	# 停用 aid_guid set outAidGuid='8eb9e89d-6ef5-11e4-8bc2-000c29364755';
	set outAidGuid=in_Aid;
end if;

if 1=1 then # 99 log 記錄
  Insert into tlog_login 
  (login_id,aid_guid,login_info,login_err_code,login_outmsg )
  Values 
  (in_Aid,outAidGuid,in_login_info,err_code,outMsg);
end if; # 99 log 記錄


end;