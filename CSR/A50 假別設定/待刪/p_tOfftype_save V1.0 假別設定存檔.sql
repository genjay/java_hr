drop procedure if exists p_tOfftype_save;

delimiter $$

create procedure p_tOfftype_save
(
 in_OUguid varchar(36)
,in_LtUser varchar(36)
,in_ltPid varchar(36)
,in_rwid int(10) unsigned
,in_offtype varchar(36)
,in_offdesc varchar(50)
,in_OffUnit int(11)
,in_OffMin int(11)
,in_Deduct_percent decimal(8,3)
,in_CutFullDuty bit(1)
,in_IncludeHoliday bit(1)
,in_Can_Duplicate bit(1)
,in_QuotaCtrl bit(1) 
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out outError int  # err_code
)

begin
/*
範例
call p_tOfftype_save
(
'microjet','ltuser','ltpid'
,46  # in_rwid int(10) unsigned
,'xoff301' # in_offtype varchar(36)
,'假別測試'
,120 # in_OffUnit int(11)
,60 # in_OffMin int(11)
,60 # in_Deduct_percent decimal(8,3)
,0  # in_CutFullDuty bit(1)
,0  # in_IncludeHoliday bit(1)
,0  # in_Can_Duplicate bit(1)
,0  # in_QuotaCtrl bit(1)
,@A # out outMsg   text # 回傳訊息
,@B # out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,@C # out outError int  # err_code
)
;

select @a,@b,@c;
 


*/

DECLARE err_code int default '0'; 
DECLARE droptable int default '0'; # 0 代表測試中 1，正常使用

set @in_OUguid=ifnull(in_OUguid,'');
set @in_ltUser=ifnull(in_ltUser,'');
set @in_ltPid=ifnull(in_ltPid,'');
set @in_rwid  = ifnull(in_rwid,'0');
set @in_offtype  = ifnull(in_offtype,'');
set @in_offdesc  = ifnull(in_offdesc,'');
set @in_OffUnit  = ifnull(in_OffUnit,'0');
set @in_OffMin  = ifnull(in_OffMin,'0');
set @in_Deduct_percent  = ifnull(in_Deduct_percent,'0');
set @in_CutFullDuty  = ifnull(in_CutFullDuty,b'0');
set @in_IncludeHoliday  = ifnull(in_IncludeHoliday,b'0');
set @in_Can_Duplicate  = ifnull(in_Can_Duplicate,b'0');
set @in_QuotaCtrl  = ifnull(in_QuotaCtrl,b'0'); 
set outMsg='';
set outRwid=0;
set outError=0;
set @in_TypeGuid='';

IF err_code=0 And @in_Rwid > 0 Then # 10 修改時，抓出
   Set @isCnt = 0;
   Select rwid,codeGuid into @isCnt ,@in_TypeGuid
   From tcatcode Where syscode='A00' And CodeID=@in_offtype And OUguid=@in_OUguid 
    And codeguid Not in  (select offtypeguid from tofftype Where rwid=@in_Rwid);
   if @isCnt>0 Then set err_code=1; set @outMsg=concat("此代碼，已被使用： ",@in_offtype); end if;
END IF; # 10 

IF err_code=0 Then # 20
   if @in_offdesc='' Then set err_code=1; set @outMsg=concat('假別說明不能空白'); end if;
End if; # 20

if err_code=0 Then # 99 新增/修改 catcode 
   set @isCnt=0;
   Select rwid into @isCnt from tcatcode Where codeguid = (select offTypeGuid from tOfftype where rwid=@in_Rwid);
   set @save_in_Rwid= @in_Rwid;
   call p_tCatCode_save
   (@in_OUguid,@in_ltUser,@in_ltpid
   ,'A00'  # Syscode A00 假別
   ,@in_offtype # 假別
   ,@in_offdesc # 假別說明 
   ,0 # Seq 
   ,0 # Stopused
   ,'' # Note
   ,@isCnt  # Rwid
   ,@a,@b,@c);  
      set @in_Rwid=@save_in_Rwid ;
   if @c > 0 Then set err_code=1; set @outMsg=concat("catcode新增/修改錯誤",@a); end if;


end if; # 99


if err_code=0 Then # End

   if err_code=0 Then # End-01 抓取產生的catcode guid
      Select rwid,codeGuid into @isCnt ,@in_TypeGuid
      From tcatcode Where syscode='A00' And CodeID=@in_offtype And OUguid=@in_OUguid ;
   end if; # End-01

   if @in_Rwid=0 Then # End-02 新增時
      insert into tOfftype(
      ltUser,ltpid
      ,offTypeGuid,OffUnit,OffMin,Deduct_percent,CutFullDuty,IncludeHoliday,Can_Duplicate,QuotaCtrl)
      values
      (@in_ltUser,@in_ltpid
      ,@in_TypeGuid,@in_OffUnit,@in_OffMin,@in_Deduct_percent,@in_CutFullDuty,@in_IncludeHoliday,@in_Can_Duplicate,@in_QuotaCtrl);
   set outMsg  = '新增成功';
   set outRwid = LAST_INSERT_ID() ;
   set outError=err_code;

   Else # End-02 修改時
      update tOfftype Set
      ltUser=@in_ltUser
     ,ltpid=@inltpid
     ,OffUnit=@in_OffUnit
     ,OffMin=@in_OffMin
	 ,Deduct_percent=@in_Deduct_percent
 	 ,CutFullDuty=@in_CutFullDuty
     ,IncludeHoliday=@in_IncludeHoliday
     ,Can_Duplicate=@in_Can_Duplicate
     ,QuotaCtrl=@in_QuotaCtrl Where rwid=@in_Rwid;
   set outMsg  = "修改成功";
   set outRwid = @in_Rwid;
   set outError=err_code;
   End if; # End-02



Else # 錯誤時 err_code > 0
   set outMsg  =@outMsg;
   set outRwid =@outRwid;
   set outError=err_code;
end if; # End 

end;