drop procedure if exists p_tOfftype_save;

delimiter $$

create procedure p_tOfftype_save
(
 in_OUguid  varchar(36)
,in_LtUser  varchar(36)
,in_ltPid   varchar(36)
,in_rwid    int(10) unsigned
,in_offtype varchar(36)
,in_offdesc varchar(50)
,in_OffUnit int(11)
,in_OffMin  int(11)
,in_Deduct_percent decimal(8,3)
,in_CutFullDuty    bit(1)
,in_IncludeHoliday bit(1)
,in_Can_Duplicate  bit(1)
,in_QuotaCtrl bit(1) 
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
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
 
DECLARE droptable int default '0'; # 0 代表測試中 1，正常使用
declare in_Offtypeguid varchar(36);
declare isCnt int;
declare tmpA,tmpB,tmpC int;
declare in_codeDesc varchar(36);
set err_code=0; set outMsg='p_tOfftype_save 執行中';

#set outMsg=in_offdesc;
# set err_code=1;

IF err_code=0 And in_Rwid > 0 Then # 10 修改時，抓出
   Set isCnt = 0;
   Select rwid,codeGuid into isCnt ,in_Offtypeguid
   From tcatcode 
   Where syscode='A00' And CodeID=in_offtype And OUguid=in_OUguid 
    And codeguid Not in (select offtypeguid from tofftype Where rwid=in_Rwid);
   if isCnt>0 Then set err_code=1; set outMsg=concat("此代碼，已被使用： ",in_offtype); end if;
END IF; # 10 

IF err_code=0 Then # 20
   if in_offdesc='' Then set err_code=1; set outMsg=concat('假別說明不能空白'); end if;
End if; # 20

if err_code=0 Then # 99 新增/修改 catcode 
   set isCnt=0;
   Select rwid,codeDesc into isCnt,in_codeDesc from tcatcode 
   Where syscode='A00' And OUguid=in_OUguid And codeID=in_Offtype;  
   if isCnt=0 then
     insert into tCatcode
     (ltUser,ltPid,codeguid,OUguid,syscode,codeID,codeDesc) Values
     (in_ltUser,in_ltPid,uuid(),in_OUguid,'A00',in_Offtype,in_offDesc) ;
 end if;
   if err_code=0 && isCnt>0 && in_codeDesc!=in_offDesc then
     update tCatcode set 
	  CodeDesc=in_offDesc
     Where rwid=isCnt;
   end if;
end if; # 99

if err_code=0 && in_Rwid=0 then # 90 新增時
 
      insert into tOfftype(
      ltUser,ltpid
      ,offTypeGuid
      ,OffUnit,OffMin,Deduct_percent,CutFullDuty,IncludeHoliday,Can_Duplicate,QuotaCtrl)
      values
      (in_ltUser,in_ltpid
      ,(Select codeguid from tcatcode where syscode='A00' And OUguid=in_OUguid And codeID=in_offtype)
      ,in_OffUnit,in_OffMin,in_Deduct_percent,in_CutFullDuty,in_IncludeHoliday,in_Can_Duplicate,in_QuotaCtrl);
   set outMsg  = '新增成功';
   set outRwid = LAST_INSERT_ID() ; 

end if; # 90 新增

if 1 && err_code=0 && in_Rwid>0 then # 90 修改

   update tOfftype Set
      ltUser  =in_ltUser
     ,ltpid   =in_ltpid  
     ,OffUnit =in_OffUnit
     ,OffMin  =in_OffMin
	 ,Deduct_percent=in_Deduct_percent
 	 ,CutFullDuty   =in_CutFullDuty
     ,IncludeHoliday=in_IncludeHoliday
     ,Can_Duplicate =in_Can_Duplicate
     ,QuotaCtrl     =in_QuotaCtrl  
   Where rwid=in_Rwid;
   set outMsg  = "修改成功";
   set outRwid = in_Rwid; 

end if; # 90 修改



end;