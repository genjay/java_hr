drop procedure if exists p_tAccount_ou_save;

delimiter $$

create procedure p_tAccount_ou_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltPid  varchar(36)
,in_Aid        Varchar(4000)  # 帳號 Aid
,in_Aid_Desc   varchar(36)    # 帳號名稱 
,in_Aid_OUID   varchar(36)    # 帳號所屬 OU，空白代表，在單OU環境操作，使用in_OUguid
,in_Valid_st   varchar(36)    # 生效日 
,in_Valid_end  varchar(36)    # 失效日
,in_PassWD     varchar(36)    # 空白代表，不變更密碼
,in_Change_PWD  int # 0 不需變更/1 需要變更
,in_Note      text
,in_Rwid      int
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)

begin
declare isCnt,need_CreateAid int ;
declare in_Aid_Guid,in_Aid_OUguid varchar(36); 
set err_code=0;
set outMsg='p_tAccount_ou_save 開始';
set need_CreateAid=0;
 
if err_code=0 then # 10 判斷帳號是否存在
  set isCnt=0;
  Select rwid,Aid_Guid into isCnt,in_Aid_Guid from tAccount where aid=in_Aid;
  if isCnt=0 then set need_CreateAid=1; end if;
end if;

if err_code=0 then # 20 抓取選擇的 OUguid
  set isCnt=0;
  Select rwid,OUguid into isCnt,in_Aid_OUguid from tOUset Where OUID = in_Aid_OUID;
  if isCnt=0 then set err_code=1; set outMsg='OUid 不存在'; end if; 
end if; # 20 
 
if err_code=0 && need_CreateAid=1 Then # 90 建立帳號
 if need_CreateAid=1 then 
 set in_Aid_Guid = uuid();
 set in_PassWD = if(in_PassWD='','1234',in_PassWD);
 Insert into tAccount
 (Aid_Guid,Aid,Aid_Desc,Valid_St,PassWD,change_pwd)
 Values
 (in_Aid_Guid,in_Aid,in_Aid_Desc,in_Valid_st,sha(in_PassWD),in_Change_PWD);
 end if;
end if; # 90

if err_code=0 && in_Rwid=0 then # 90 新增
  if in_Valid_end='' then set in_Valid_end=null;  end if;
  Insert into tAccount_ou (OUguid,Aid_Guid,Valid_st,Valid_end)
  Select in_Aid_OUguid,in_Aid_Guid,in_Valid_st,in_Valid_end;
  set outRwid =  last_insert_id();
  set outMsg = concat('「',in_Aid,'」','新增完成');
end if; # 90 

if err_code=0 && in_Rwid>0 then # 90 修改

  if in_Valid_end='' then set in_Valid_end=null;  end if;
  update tAccount_ou set
  Valid_st=in_Valid_st,
  Valid_end=in_Valid_end,
  note=in_note 
  Where Rwid = in_Rwid;
  set outMsg = concat('「',in_Aid,'」','修改完成');
  Update tAccount set Change_PWD=in_Change_PWD
  Where Aid_Guid=in_Aid_Guid; 
  if in_PassWD !='' then 
     Update tAccount set PassWD=Sha(in_PassWD) ,Change_PWD=in_Change_PWD
  Where Aid_Guid=in_Aid_Guid; 
  end if;
end if; # 90 修改



end;