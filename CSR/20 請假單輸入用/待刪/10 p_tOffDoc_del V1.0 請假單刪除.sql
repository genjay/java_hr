drop procedure if exists p_tOffDoc_del;

delimiter $$

create procedure p_tOffDoc_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36)  
,in_Rwid   int  # 單據Rwid
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out outError int  # err_code
)

begin
/*
執行範例 
call p_tOffDoc_del
(
 'microjet'
,'ltuser'
,'ltpid'
,10   #rwid
,@a
,@b
,@c
);


*/

DECLARE err_code  int default '0'; 
DECLARE droptable int default '0'; # 0 代表測試中 1，正常使用

set @in_OUguid = IFNULL(in_OUguid,'');
set @in_ltUser = IFNULL(in_ltUser,'');
set @in_ltpid  = IFNULL(in_ltpid,''); 
set @in_Rwid   = IFNULL(in_Rwid,'0'); 
set @outRwid   = 0;
set @outMsg    =''; 

 insert into t_log (ltpid,note) values ('p_tOffDoc_del',
concat( "call p_tOffDoc_del(\n'"
,@in_OUguid  ,"',\n'"
,@in_ltUser  ,"',\n'"
,@in_ltpid   ,"',\n'"  
,@in_Rwid    ,"',\n"
,'@a'        ,","
,'@b'        ,","
,'@c' 
,");" )); 

IF err_code=0 Then # A00 判斷 @in_Rwid 單據是否存在、及是否關帳
   set @isCnt=0;
   set @CloseStatus_z07=0;
   Select rwid,CloseStatus_z07 into @isCnt,@CloseStatus_z07 from tOffDoc Where rwid=@in_Rwid And EmpGuid in (Select EmpGuid from tperson Where OUguid=@in_OUguid);
   if err_code=0 and @isCnt=0 Then set err_code=1; set @outMsg=concat("無此單據,單號：",@in_Rwid); end if;
   if err_code=0 and @CloseStatus_z07=1 Then set err_code=1; set @outMsg=concat("此單據已關帳、無法刪除",@in_Rwid); end if;   
end if;

IF err_code=0 Then # ZZ End   

   delete from tOffQuota_used Where OffDocGuid=(select offDocGuid from tOffdoc where  rwid = @in_Rwid);
 
   delete from toffdoc 
   where CloseStatus_z07='0' #未關帳
   And empguid in (select empguid from tperson where ouguid=@in_OUguid) # 該 OU的人員
   and  rwid=@in_Rwid; 
  
   set outMsg  =if(@outMsg='','刪除成功',@outMsg);
   set outRwid =if(@outRwid=0,@in_Rwid,@outRwid);
   set outError=err_code;
Else
   
   set outMsg  =if(@outMsg='','失敗',@outMsg);
   set outRwid =if(@outRwid=0,@in_Rwid,@outRwid);
   set outError=err_code;
end if; # ZZ

end;