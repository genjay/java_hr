drop procedure if exists p_tCatCode_save; # 分類碼存檔

delimiter $$

create procedure p_tCatCode_save
(
 in_OUguid   varchar(36)
,in_ltUser   varchar(36)
,in_ltpid    varchar(36) /*程式代號*/ 
,in_syscode  varchar(36) # syscode
,in_codeID   varchar(36) # codeID
,in_codeDesc varchar(36) # codedesc
,in_codeSeq   int # 排序用，預設給 0 
,in_stop_used int # 0 正常/1 停用
,in_Note text /*備註*/
,in_Rwid int  /*要修改的rwid*/
,out outMsg   text /*回傳訊息，直接給user看的*/
,out outRwid  int  /*修改或新增的rwid*/
,out err_code int /*成功失敗代碼*/
)

begin
declare isCnt int;  
 
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
  set outMsg='RollBack';
END;   
 
set err_code=0; set outRwid=0; set outMsg='p_tCatCode_save 執行中';

if err_code=0 Then # 10 判斷是否存在相同資料
   set isCnt=0; set outMsg='10 判斷是否存在其他相同資料';
   Select Rwid into isCnt From tcatcode
   Where Syscode=in_Syscode And OUguid=in_OUguid
    And codeID=in_CodeID
    And rwid != in_Rwid limit 1;
   Set outRwid = isCnt;
   IF isCnt > 0 Then set err_code=1; set outMsg=concat('「',in_CodeID,'」'," 已存在"); set outRwid=in_Rwid; end if;
end if; #10

if err_code=0 Then # 20 判斷是否需要修改、不需要則中斷，outMsg傳空值
  set isCnt=0; set outMsg='20 判斷是否需要修改';
  Select Rwid into isCnt From tcatcode
  Where Syscode=in_Syscode And OUguid=in_OUguid
    And codeID=in_CodeID And CodeDesc=in_codeDesc And Note=in_Note
    And codeSeq=in_codeSeq
    And Stop_Used=in_stop_used
    And rwid = in_Rwid limit 1;
  IF isCnt>0 Then set err_code=1; set outMsg=''; end if;
end if;

 if err_code=0 then # 25 判斷是否修改 syscode
 set isCnt=0;
 Select rwid into isCnt from tcatcode
 Where rwid =  in_Rwid And syscode != in_syscode;
 if isCnt>0 then set err_code=1; set outMsg='syscode 不能修改'; end if;
end if; # 25 

if err_code=0 Then # 30 說明不能為空
  set outMsg='30';
  if ifnull(in_codeDesc,'')='' Then set err_code=1; set outMsg=concat('「',in_CodeID,'」','說明不能為空值'); end if;
end if; # 30



if err_code=0 && in_Rwid=0 then # 90 新增
 set outMsg='Insert ing...';
  Insert into tCatCode
  (ltUser,ltPid,CodeGuid,OUguid,Syscode,CodeID,CodeDesc,CodeSeq,stop_used,Note)
  values
  (in_ltUser,in_ltPid,uuid(),in_OUguid,in_Syscode,in_CodeID,in_CodeDesc,in_CodeSeq,in_stop_used,in_Note);
  set outMsg=concat('「',in_CodeID,'」',' 新增成功');
  set outRwid=last_insert_id();
end if; # 90 新增

if err_code=0 && in_Rwid>0 then # 90 修改
  update tCatCode set
   ltUser=in_ltUser
  ,ltpid=in_ltPid
  ,codeID=in_CodeID
  ,codeDesc=in_CodeDesc
  ,CodeSeq=in_CodeSeq
  ,Stop_used=in_Stop_used
  ,Note=in_Note
  Where  ouguid=in_ouguid And rwid = in_Rwid ;
  set outMsg=concat('「',in_CodeID,'」',' 修改成功');
  set outRwid=in_Rwid;
end if; # 90 修改



end # Begin