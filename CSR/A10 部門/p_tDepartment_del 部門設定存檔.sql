drop procedure if exists p_tDepartment_del;

delimiter $$

create procedure p_tDepartment_del
( 
in_OUguid  varchar(36),
in_LtUser  varchar(36),
in_ltPid   varchar(36), 
in_Rwid    int,  
out outMsg text,
out outRwid int,
out err_code int
)
begin

declare tlog_note text; 
declare isCnt int;  
# declare in_CodeGuid varchar(36);
declare in_DepID text;
declare tmpA,tmpB,tmpC text;
set err_code=0;


set tlog_note= concat("call p_tDepartment_del(\n'"
,in_OUguid         ,"',\n'"
,in_ltUser         ,"',\n'"
,in_ltpid          ,"',\n'"  
,in_Rwid           ,"',\n" 
,'@a'              ,","
,'@b'              ,","
,'@c' 
,");");

call p_tlog(in_ltpid,tlog_note);
set outMsg='p_tDepartment_del,開始'; 

if err_code=0 Then # 10
  if in_Rwid=0 Then set err_code=1; set outMsg='in_Rwid 不可為 0'; end if;
end if; # 10

if err_code=0 && 1 Then # 15 抓 DepID
  Select concat('(',codeID,' ',codeDesc,')') into in_DepID from tcatcode Where codeguid = 
  (Select DepGuid from tdepartment Where Rwid=in_Rwid);

end if; # 15

if err_code=0 Then # 20
  set isCnt=0;
  Select rwid into isCnt from tperson Where depguid = (select depguid from tdepartment Where Rwid=in_Rwid);
  if isCnt>0 Then set err_code=1; set outMsg=concat(in_DepID,' 此部門 tperson 使用中，不能刪除'); end if;
end if; 

if err_code=0 Then # 30
  set isCnt=0;
  Select rwid into isCnt from tdepartment Where UP_depguid = (Select depguid from tdepartment Where Rwid=in_Rwid);
  if isCnt>0 Then set err_code=1; set outMsg=concat(in_DepID,' 此部門 tdepartment 上層部門使用中，不能刪除'); end if;
end if;



if err_code=0 Then # 90
  set outMsg='刪除中';  
  Select rwid into isCnt from tCatcode Where codeguid = (select depguid from tdepartment Where Rwid=in_Rwid);
  Delete from tdepartment Where rwid=in_Rwid;
  
  call p_tCatCode_del(in_OUguid,in_ltUser,in_ltpid,isCnt
        ,tmpA,tmpB,tmpC);
  if tmpC=0 Then set outMsg= concat(in_DepID,' 刪除完成');
  Else set outMsg=tmpA; end if;
end if; # 90
 
 
end # Begin