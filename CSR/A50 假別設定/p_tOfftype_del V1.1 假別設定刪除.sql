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
,out err_code int  # err_code
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
 
DECLARE droptable int default '0'; # 0 代表測試中 1，正常使用
declare tmpA,tmpB,tmpC text;
declare isCnt int;
set err_code=0;
set outRwid=0;
set outMsg='p_tOfftype_del 執行中';


if err_code=0 then  # 10 判斷該假別是否已被使用(請假單)
  set isCnt=0;
  Select rwid into isCnt from tOffdoc
  Where offtypeguid = (Select offtypeguid from tofftype Where rwid=in_Rwid) limit 1;
  if isCnt>0 then set err_code=1; set outMsg="該假別已被使用(toffdoc)、無法刪除"; end if;
end if; # 10 

if err_code=0 Then # 20 判斷該假別是否已被使用(加班單設定)
   set isCnt=0;
   Select rwid into isCnt from tOvertype Where offtypeguid = (Select offtypeguid from tofftype Where rwid=in_Rwid) limit 1;
   if isCnt>0 Then set err_code=1; set outMsg="該假別已被使用(tOvertype)、無法刪除"; end if;
end if;

if err_code=0 then # 90 刪除資料
  set isCnt=0; 
  Select rwid into isCnt From tcatcode Where codeguid in (
   Select offtypeguid from tOfftype Where rwid=in_Rwid) limit 1;

   delete from tofftype 
  Where offtypeguid in (Select codeguid from tcatcode where ouguid=in_OUguid) 
     And rwid=in_Rwid ;
   
  call p_tCatCode_del
  (
  in_OUguid,in_ltUser,in_ltpid
  ,isCnt   # tcatcode.rwid
  ,tmpA,tmpB,tmpC
  ); 
  set outMsg='刪除成功';
end if; # 90 
 
end; # Begin