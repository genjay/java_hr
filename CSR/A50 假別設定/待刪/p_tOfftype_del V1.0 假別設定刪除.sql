drop procedure if exists p_tOfftype_del;

delimiter $$

create procedure p_tOfftype_del
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
call p_tOfftype_del
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

DECLARE err_code int default '0'; 
DECLARE droptable int default '0'; # 0 代表測試中 1，正常使用

set @in_OUguid = IFNULL(in_OUguid,'');
set @in_ltUser = IFNULL(in_ltUser,'');
set @in_ltpid  = IFNULL(in_ltpid,''); 
set @in_Rwid   = IFNULL(in_Rwid,'0'); 
set @outRwid   = 0;
set @outMsg    =''; 

 insert into t_log (ltpid,note) values ('p_tOfftype_del',
concat( "call p_tOfftype_del(\n'"
,@in_OUguid  ,"',\n'"
,@in_ltUser  ,"',\n'"
,@in_ltpid   ,"',\n'"  
,@in_Rwid  ,"',\n"
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");" )); 

if err_code=0 Then # 10 判斷該假別是否已被使用(請假單)
   set @isCnt=0;
   Select rwid into @isCnt from toffdoc Where offtypeguid = (Select offtypeguid from tofftype Where rwid=@in_Rwid) limit 1;
   if @isCnt>0 Then set err_code=1; set @outMsg="該假別已被使用(toffdoc)、無法刪除"; end if;
end if;

if err_code=0 Then # 10 判斷該假別是否已被使用(加班單設定)
   set @isCnt=0;
   Select rwid into @isCnt from tOvertype Where offtypeguid = (Select offtypeguid from tofftype Where rwid=@in_Rwid) limit 1;
   if @isCnt>0 Then set err_code=1; set @outMsg="該假別已被使用(tOvertype)、無法刪除"; end if;
end if;


IF err_code=0 Then # ZZ End   

   Select rwid into @isCnt From tcatcode Where codeguid in (
   Select offtypeguid from tOfftype Where rwid=in_Rwid) limit 1;

   delete from tofftype Where offtypeguid in (Select codeguid from tcatcode where ouguid=@in_OUguid) 
     And rwid=@in_Rwid ;
   
call p_tCatCode_del
(
in_OUguid,in_ltUser,in_ltpid
,@isCnt   # tcatcode.rwid
,@a
,@b
,@c
);

   set outMsg  =if(@outMsg='','刪除成功',@outMsg);
   set outRwid =if(@outRwid=0,@in_Rwid,@outRwid);
   set outError=err_code;
Else
   
   set outMsg  =if(@outMsg='','失敗',@outMsg);
   set outRwid =if(@outRwid=0,@in_Rwid,@outRwid);
   set outError=err_code;
end if; # ZZ

end;