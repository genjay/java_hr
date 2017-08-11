drop procedure if exists p_tOfftype_save;

delimiter $$ 

create procedure p_tOfftype_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_Offtype_ID                varchar(36)
,in_Offtype_Desc              varchar(36)
,in_OffUnit                   smallint(6) 
,in_OffMin                    smallint(6) 
,in_Deduct_percent            decimal(10,4) 
,in_CutFullDuty               int(1)
,in_IncludeHoliday            int(1)
,in_Can_Duplicate             int(1)
,in_QuotaCtrl                 int(1)
,in_Stop_used                 int(1)
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare is_offtype_ID varchar(36);
/*
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
 */
set err_code=0; set outRwid=0; set outMsg='xxxxxp_tOfftype_save 執行中';

if err_code=0 then # 判斷是否有無修改
  set isCnt=0; 
  Select rwid into isCnt 
   From tOfftype 
  Where rwid=in_Rwid And Offtype_ID=in_Offtype_ID And Offtype_Desc=in_Offtype_Desc And OffUnit=in_OffUnit And OffMin=in_OffMin And Deduct_percent=in_Deduct_percent And CutFullDuty=in_CutFullDuty And IncludeHoliday=in_IncludeHoliday And Can_Duplicate=in_Can_Duplicate And QuotaCtrl=in_QuotaCtrl And Stop_used=in_Stop_used And note=in_note;
 if isCnt>0 then set err_code=1; set outMsg='資料無修改'; end if;
 end if;
 
if err_code=0 && in_Rwid >0 then # 10
  set isCnt=0;
  Select rwid,offtype_ID into isCnt,is_offtype_ID from tOfftype where  ouguid=in_ouguid And rwid =  in_Rwid;
  if isCnt=0 then set err_code=1; set outMsg='資料不存在'; end if;
end if; # 10

if err_code=0 then # 20 判斷是否存在其他筆資料
 set isCnt=0;
 Select rwid into isCnt from tOfftype where OUguid = in_OUguid And Offtype_ID=in_Offtype_ID And rwid != in_Rwid limit 1;
 if isCnt>0 then set err_code=1; set outMsg='已存在其他相同資料'; end if;
end if; # 20

if err_code=0 && in_Deduct_percent not between 0 And 100 then # 21 判斷扣薪比例是否在 0~100 間
 set err_code=1; set outMsg='扣薪比率需在0~100間';  
end if; # 

if err_code=0 && in_OffUnit <1 then # 22 判斷 累進最小為 1
 set err_code=1; set outMsg='請假單位(累進) 範圍 1~999，此值30，代表每半小時增加';  
end if; #  

if err_code=0 && in_OffMin <0 then # 23 判斷 in_OffMin 是否 >0
 set err_code=1; set outMsg='請假單位(最小) 範圍1~999，此值代表每次請假最少請幾分鐘 ';  
end if; #  


if err_code=0 && in_Rwid=0 then # 90 新增
Insert into tofftype
 (offType_Guid,OUguid,Offtype_ID,Offtype_Desc,OffUnit,OffMin,Deduct_percent,CutFullDuty,IncludeHoliday,Can_Duplicate,QuotaCtrl,Stop_used,note)
 values 
 (uuid(),in_OUguid,in_Offtype_ID,in_Offtype_Desc,in_OffUnit,in_OffMin,in_Deduct_percent,in_CutFullDuty,in_IncludeHoliday,in_Can_Duplicate,in_QuotaCtrl,in_Stop_used,in_note);
 set outMsg=concat('「',in_Offtype_ID,'」','新增成功');
set outRwid=last_insert_id();
end if; # 

if err_code=0 && in_Rwid>0 then # 90 修改
Update tofftype Set
  ltUser              = in_ltUser
 ,ltpid               = in_ltpid
 ,Offtype_ID          = in_Offtype_ID
 ,Offtype_Desc        = in_Offtype_Desc
 ,OffUnit             = in_OffUnit
 ,OffMin              = in_OffMin
 ,Deduct_percent      = in_Deduct_percent
 ,CutFullDuty         = in_CutFullDuty
 ,IncludeHoliday      = in_IncludeHoliday
 ,Can_Duplicate       = in_Can_Duplicate
 ,QuotaCtrl           = in_QuotaCtrl
 ,Stop_used           = in_Stop_used
 ,note                = in_note
  Where  ouguid=in_ouguid And rwid=in_Rwid;
  set outMsg=concat('「',in_Offtype_ID,'」','修改成功');
  set outRwid=in_Rwid;
end if; # 90 修改

end; # begin