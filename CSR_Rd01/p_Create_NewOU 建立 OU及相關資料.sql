drop procedure if exists p_Create_NewOU;

delimiter $$ 

create procedure p_Create_NewOU
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/ 
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
# 此程式架構在已產生 tOUset , 產生該 OU 必要 Table 的值
/*
call p_Create_NewOU
(
 'ABC'
,'',''
,@a,@b,@c
)  
; 
*/
declare isCnt int;  

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_demo 執行中';

if 0 && err_code=0 then # 檢查有無此OUguid
  set isCnt=0;
  Select count(*) into isCnt from tOUset Where OUguid = in_OUguid;
  if isCnt=0 then set err_code=1; set outMsg='無此OUguid'; end if;
end if; 
 
if err_code=0 then # 90A 新增假別
  set isCnt=0;
  Select count(*) Into isCnt from tOfftype Where OUguid = in_OUguid;
  if isCnt=0 Then  # 該OU無假別資料，才新增
	  insert into tOfftype
	 (ltUser,ltpid,offTypeGuid,OUguid
	 ,Offtype_ID,Offype_Desc,OffUnit,OffMin,Deduct_percent,CutFullDuty,IncludeHoliday,Can_Duplicate,QuotaCtrl)
	 Select in_ltUser,in_ltPid,uuid() offtypeguid,in_OUguid
	 ,Offtype_ID,Offype_Desc,OffUnit,OffMin,Deduct_percent,CutFullDuty,IncludeHoliday,Can_Duplicate,QuotaCtrl
	 from tOfftype
	 where ouguid='**common**';
	set outMsg='假別新增完成';
 end if;
end if; # 90A
 
end; # begin