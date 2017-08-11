drop procedure if exists p_tDepartment_save;

delimiter $$

create procedure p_tDepartment_save
( 
in_OUguid  varchar(36),
in_LtUser  varchar(36),
in_ltPid   varchar(36), 
in_Rwid    int, # 0 新增 > 0 該資料的rwid
in_DepID   varchar(36),
in_DepDesc varchar(36),
in_WorkID  varchar(36),
in_UpDepID varchar(36),
in_StopUsed bit,
out outMsg text,
out outRwid int,
out err_code int
)
begin

declare tlog_note text; 
declare isCnt int;  
set err_code=0;
set outRwid=0;

set tlog_note= concat("call p_tDepartment_save(\n'"
,in_OUguid         ,"',\n'"
,in_ltUser         ,"',\n'"
,in_ltpid          ,"',\n'"
,in_Rwid           ,"',\n'"
,in_DepID          ,"',\n'"
,in_DepDesc        ,"',\n'"
,in_WorkID         ,"',\n'"
,in_UpDepID        ,"',\n'" 
,in_StopUsed       ,"',\n" 
,'@a'              ,","
,'@b'              ,","
,'@c' 
,");");

call p_tlog(in_ltpid,tlog_note);
set outMsg='p_tworkinfo_save,開始'; 

if err_code=0 Then # 10 判斷 OUguid是否存在
  set isCnt=0; set outMsg='10 判斷';
  Select rwid into isCnt from tOUset Where OUguid=in_OUguid;
  if isCnt=0 Then set err_code=1; set outMsg=concat('無此OUguid: ',ifnull(in_OUguid,'')); end if;
end if; # 10

if err_code=0 Then # 20 判斷 DepID 
  set isCnt=0; set outMsg='20 判斷';
  Select rwid into isCnt From tCatCode Where syscode='A07' and OUguid=in_OUguid And CodeID=in_DepID limit 1;
  if isCnt>0 And in_Rwid=0 Then set err_code=1; set outMsg='該DepID已被使用'; end if;
end if; # 20

if err_code=0 And ifnull(in_UpDepID,'')!='-1' Then # 30 上層部門有輸入時
  set isCnt=0; set outMsg='30 判斷';
  Select rwid into isCnt From tCatCode Where syscode='A07' And OUguid=in_OUguid And codeID=in_UpDepID limit 1;
  if isCnt=0 Then set err_code=1; set outMsg='所屬部門不存在'; end if;
end if; # 30

if err_code=0 Then
  if in_DepID=in_UpDepID Then set err_code=1; set outMsg='上層主管不能跟自身相同'; end if;
end if;

if err_code=0 And ifnull(in_WorkID,'')!='-1' Then # 40 判斷班別有輸入時
  set isCnt=0; set outMsg='40 判斷';
  Select rwid into isCnt From tCatcode Where syscode='A01' And OUguid=in_OUguid And CodeID=in_WorkID limit 1;
  if isCnt=0 Then set err_code=1; set outMsg='班別錯誤'; end if;
end if; # 40

if err_code=0 Then # 50
  if in_DepDesc='' Then set err_code=1; set outMsg='部門名稱空白'; end if;
end if; # 50


if err_code=0 && in_Rwid =0 Then # 90 新增/修改tCatcode
  insert into tCatCode
  (codeGuid,SysCode,OUguid,CodeID,CodeDesc,Stop_used
   ,codeseq
  )  
  (Select
  uuid()  ,'A07',in_OUguid,in_DepID,in_DepDesc,in_StopUsed
   ,(Select max(codeseq) from tcatcode where syscode='A07' and ouguid=in_OUguid)
  );
  set outMsg='tCatcode 新增完成';
end if;

if err_code=0 && in_Rwid > 0 Then # 90 修改tCatcode
 
  update tCatcode set
  CodeID=in_DepID,
  CodeDesc=in_DepDesc,
  Stop_used=in_StopUsed
  Where Codeguid = (Select DepGuid from tdepartment Where rwid=in_Rwid );
  
  set outMsg='tCatcode 修改完成';
end if;

if err_code=0 && in_Rwid =0 Then # 95 A 新增
  insert into tDepartment # 一定要在 catcode新增後，才能用
  (DepGuid,Up_DepGuid,WorkGuid)
  Values (
  (Select codeGuid From tCatCode Where SysCode='A07' And OUguid=in_OUguid And CodeID=in_DepID),
  (Select codeGuid From tCatCode Where SysCode='A07' And OUguid=in_OUguid And CodeID=in_UpDepID),
  (Select codeGuid from tCatCode Where Syscode='A01' And OUguid=in_OUguid And CodeID=in_WorkID)
  );
  set outRwid=LAST_INSERT_ID();
  set outMsg=concat('tDepartment 新增/修改完成',outRwid);  
end if; # 95

if err_code=0 && in_Rwid > 0 Then # 95 B 修改
  Update tDepartment set
  Up_DepGuid=(Select codeGuid From tCatCode Where SysCode='A07' And OUguid=in_OUguid And CodeID=in_UpDepID),
  WorkGuid=(Select codeGuid from tCatCode Where Syscode='A01' And OUguid=in_OUguid And CodeID=in_WorkID)
  Where Rwid=in_Rwid;
   set outRwid=in_Rwid;
   set outMsg=concat('tDepartment 修改完成',outRwid);  
end if; # 95

 
end # Begin