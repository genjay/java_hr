drop procedure if exists p_tOUset_save;

delimiter $$

create procedure p_tOUset_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) 
,in_OUID   varchar(36)
,in_OUname varchar(36)
,in_Seq    int
,in_Rwid   int  # 0 新增
,out outMsg   text /*回傳訊息，直接給user看的*/
,out outRwid  int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin 
declare isCnt int;
declare in_Aid_Guid,in_Add_OUguid varchar(36);
set err_code=0;
set outRwid=0;
set outMsg='p_tOUset_save 執行中';
 

if err_code=0 && in_Rwid=0 then # 90
  set in_Add_OUguid = uuid();
  Insert into tOUset (ltUser,OUguid,OUID,OUName,Seq)
  Select in_ltUser,in_Add_OUguid,in_OUID,in_OUname,in_Seq;
  Set outRwid=LAST_INSERT_ID();
  Set outMsg='新增完成';
 
end if; # 90

if err_code=0 && in_Rwid>0 then # 90
  Update tOUset Set
  OUID=in_OUID,
  OUname=in_OUname,
  Seq=in_Seq
  Where Rwid=in_Rwid;
  set outRwid=in_Rwid;
  set outMsg='修改完成';
end if; # 90

end; # Begin