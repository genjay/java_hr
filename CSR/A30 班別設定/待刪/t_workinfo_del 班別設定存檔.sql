drop procedure if exists p_tworkinfo_del;

delimiter $$

create procedure p_tworkinfo_del
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

DECLARE err_code int default '0'; 
DECLARE droptable int default '0'; # 0 代表測試中 1，正常使用

set @in_OUguid = IFNULL(in_OUguid,'');
set @in_ltUser = IFNULL(in_ltUser,'');
set @in_ltpid  = IFNULL(in_ltpid,''); 
set @in_Rwid   = IFNULL(in_Rwid,'0'); 
set @outRwid   = 0;
set @outMsg    =''; 

if err_code=0 Then # A00
   set @WorkGuid='';
   Select WorkGuid into @WorkGuid from tworkinfo Where rwid=@in_Rwid;
   if @WorkGuid='' Then set err_code=1; set @outMsg=concat("此筆資料不存在，單號：",@in_Rwid); end if;

end if; # A00

if err_code=0 Then # A01
   set @isCnt=0;
   Select rwid into @isCnt from tSchDep Where workguid=@workguid limit 1;
   if @isCnt>0 Then set err_code=1; set @outMsg="此班別已被部門班別(tSchDep)使用，無法刪除"; end if;
end if; # A01 

if err_code=0 Then # A02
   set @isCnt=0;
   Select rwid into @isCnt from tSchEmp Where workguid=@workguid limit 1;
   if @isCnt>0 Then set err_code=1; set @outMsg="此班別已被個人班別(tSchEmp)使用，無法刪除"; end if;
end if; # A02 

if err_code=0 Then # A03
   set @isCnt=0;
   Select rwid into @isCnt from tduty_a Where workguid=@workguid limit 1;
   if @isCnt>0 Then set err_code=1; set @outMsg="此班別已被(tDuty_a)使用，無法刪除"; end if;
end if; # A03


if err_code=0 Then # 00
   set @isCnt=0;
   Select rwid into @isCnt From tworkrest Where workguid=@WorkGuid limit 1;
   if @isCnt > 0 Then set err_code=1; set @outMsg="已經休息時刻表，無法刪除"; end if;
end if; # 00


if err_code=0 Then # End
   delete from tworkinfo Where rwid=@in_Rwid;
   insert into t_log (note) values (concat('inRwid',@in_Rwid,' ','workguid',@workguid));
   if err_code=0 Then # End-10 刪除cat code 
      set  @catcode_rwid=0;
      Select rwid into @catcode_rwid from tcatcode Where codeGuid=@workGuid limit 1;
      call p_tCatCode_del(@in_OUguid,@in_ltUser,@in_ltpid,@catcode_rwid
        ,@a,@b,@c);
   end if; # End-10
   set outMsg  =if(@outMsg='','刪除成功',@outMsg);
   set outRwid =if(@outRwid=0,@in_Rwid,@outRwid);
   set outError=err_code;
Else
   
   set outMsg  =if(@outMsg='','失敗',@outMsg);
   set outRwid =if(@outRwid=0,@in_Rwid,@outRwid);
   set outError=err_code;
end if; # End



end 
