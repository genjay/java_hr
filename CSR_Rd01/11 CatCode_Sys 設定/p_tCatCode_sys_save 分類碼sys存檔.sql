drop procedure if exists p_tCatCode_Sys_save; # 分類碼存檔

delimiter $$

create procedure p_tCatCode_Sys_save
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
 
/*
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
  set outMsg='RollBack';
END;   
 */
set err_code=0; set outRwid=0; set outMsg='p_tCatCode_Sys_save 執行中';

if err_code=0 && in_Rwid>0 then # 10 判斷要修改的值，是否存在
 set isCnt=0;
 Select rwid into isCnt from tcatcode_sys where ouguid=in_ouguid And rwid = in_Rwid;
 if isCnt=0 then set err_code=1; set outMsg='資料不存在'; end if;
end if; # 10

if err_code=0 then # 20 判斷要修改值，是否與其他資料一樣
  set isCnt=0;
  Select rwid into isCnt from tcatcode_sys 
  where rwid != in_Rwid And OUguid=in_OUguid And syscode=in_syscode And codeID=in_codeID;
  if isCnt>0 then set err_code=1; set outMsg='已存在其他一樣資料'; end if;
end if; # 20 

if err_code=0 then # 30 判斷是否修改 syscode
 set isCnt=0;
 Select rwid into isCnt from tcatcode_sys
 Where rwid =  in_Rwid And syscode != in_syscode;
 if isCnt>0 then set err_code=1; set outMsg='syscode 不能修改'; end if;
end if; # 30 

if err_code=0 then # 40 判斷是否修改 codeID
 set isCnt=0;
 Select rwid into isCnt from tcatcode_sys
 Where rwid =  in_Rwid And codeID != in_codeID;
 if isCnt>0 then set err_code=1; set outMsg='codeID 不能修改'; end if;
end if; # 40 

if err_code=0 && in_Rwid > 0 then # 90
  Update tCatcode_Sys set
  ltUser   = in_ltUser  
,ltPid = in_ltpid    
# ,syscode=in_syscode  不要給user改syscode，真的需要用刪除，再新增
# ,codeID=in_codeID    不要給user改syscode，真的需要用刪除，再新增
,codeDesc=in_codeDesc  
,codeSEQ=in_codeSeq   
,stop_used=in_stop_used  
,note=in_Note 
 Where  ouguid=in_ouguid And rwid = in_Rwid;
  set outMsg=concat('「',in_CodeID,'」',' 修改完成');
  set outRwid=in_Rwid;
end if; # 90

if err_code=0 && in_Rwid=0 then # 90 新增
  Insert into tCatcode_Sys
  (ltUser,ltpid,OUguid,SysCode,CodeID,CodeDesc,CodeSEQ,Stop_used,Note)
  values
  (in_ltUser,in_ltpid,in_OUguid,in_SysCode,in_CodeID,in_CodeDesc,in_CodeSEQ,in_Stop_used,in_Note);
  set outRwid=last_insert_id();
  set outMsg=concat('「',in_CodeID,'」',' 新增完成');
end if; # 90 新增

end # Begin