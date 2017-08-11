drop procedure if exists p_OUcheck;

delimiter $$

create procedure p_OUcheck
(
 in_Aidguid Varchar(36)     #  傳入 in_ltUser
,in_OUList  Varchar(4000)   #  傳入 OU 選擇後資料 OUid 'microjet'
,out outOUguid Varchar(36)  # 回傳 OUguid
,out outOUid   varchar(36)  # 回傳 OUid
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)

begin
declare isCnt int ; 
set err_code=0;
set outMsg='00 p_OUcheck 執行開始';
/*
set @aid_guid=(select aid_guid from taccount where aid='a00514@microjet.com.tw');
set @ou_list=(select concat(ouid,' ',ouname) from tOUset limit 1);
call p_OUcheck
(
 @aid_guid
,@ou
,@OUguid
,@a,@b,@C
);
 
select @a,@b,@c,@aid_guid,@OUguid; 
*/

if err_code=0 Then # 10 抓該 OUguid
  set outOUguid=''; set outMsg='ou 開始';
  Select OUid,OUguid into outOUid,outOUguid From tOUset Where ouID=in_OUlist;
  if outOUguid='' Then set err_code=1;  set outMsg='ou錯誤'; end if;
end if; # 10

if err_code=0 Then # 15 抓該 in_Aidguid
  set outMsg='in_Aidguid 判斷開始';
  set isCnt=0;
  Select rwid into isCnt From tAccount Where Aid_guid=in_Aidguid;
  if isCnt=0 Then set err_code=1;  set outMsg='人員錯誤'; end if;
end if; # 15

IF err_code=0 Then # 20
  set isCnt=0;
  Select rwid into isCnt From tAccount_OU Where Aid_Guid=in_Aidguid And ouGuid=outOUguid 
  And Valid_St < Now() And IFNULL(Valid_End,'9999-12-31') > Now();
  IF isCnt=0 Then set err_code=1; set outMsg='已經過期'; end if;
 

end if; # 20

end; # begin