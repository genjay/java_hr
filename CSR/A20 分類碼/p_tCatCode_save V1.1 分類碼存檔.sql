drop procedure if exists p_tCatCode_save; # 分類碼存檔

delimiter $$

create procedure p_tCatCode_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/ 
,in_syscode varchar(36) # syscode
,in_codeID varchar(36) # codeID
,in_codeDesc varchar(36) # codedesc
,in_codeSeq int # codeseq
,in_stop_used int # 0 正常/1 停用
,in_Note text /*備註*/
,in_Rwid int  /*要修改的假單rwid*/
,out outMsg text /*回傳訊息，直接給user看的*/
,out outRwid int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin
declare tlog_note text;
declare isCnt int;
set err_code = 0;

set tlog_note= concat("call p_tCatCode_save(\n'"
,in_OUguid  ,"',\n'"
,in_ltUser  ,"',\n'"
,in_ltpid   ,"',\n'"  
,in_Syscode ,"',\n'"   
,in_codeID  ,"',\n'"   
,in_codeDesc ,"',\n'"   
,in_codeSeq ,"',\n'"   
,in_stop_used ,"',\n'"   
,in_Note ,"',\n'"     
,in_Rwid  ,"',\n"
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");");
call p_tlog(in_ltPid,tlog_note);
set outMsg='p_tCatCode_save,開始';
set in_codeID=trim(in_codeID); # 去除頭尾空白 

if err_code=0 && in_Rwid>0 && Substring(in_Syscode,1,1)='Z' Then # 05 判斷 Syscode like 'Z%'時
  set isCnt=0; set outMsg='05 Syscode為Z開頭時，只能修改說明、新增';
  Select rwid into isCnt from tCatcode 
  Where rwid=in_Rwid  
   And OUguid=in_OUguid And SysCode=in_Syscode And CodeID=in_codeID;
  if isCnt=0 Then set err_code=1; set outMsg='Sysocde為Z開頭，系統用不能修改'; end if;
end if; # 05

if err_code=0 Then # 10 判斷是否存在相同資料
   set isCnt=0; set outMsg='10 判斷是否存在其他相同資料';
   Select Rwid into isCnt From tcatcode
   Where Syscode=in_Syscode And OUguid=in_OUguid
    And codeID=in_CodeID
    And rwid != in_Rwid limit 1;
   Set outRwid = isCnt;
   IF isCnt > 0 Then set err_code=1; set outMsg="已存在相同資料"; set outRwid=in_Rwid; end if;
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
 
if err_code=0 Then # 30 說明不能為空
  set outMsg='30';
  if ifnull(in_codeDesc,'')='' Then set err_code=1; set outMsg=concat('「',in_CodeID,'」','說明不能為空值'); end if;
end if; # 30

if err_code=0 And in_Rwid > 0 Then # 90 修改模式
      set outMsg='90';
/*
      if in_CodeSeq=0 Then # 90-1 因為 codeseq=0 為syscode 用，所以不能為 0
	   set in_CodeSeq=(select ifnull(max(codeseq),0)+1 from tcatcode where syscode=in_Syscode and ouguid=in_OUguid);
      end if; # 20-1 
*/
      update tcatcode set
       ltUser=in_ltUser
      ,ltpid =in_ltPid
      ,CodeID=in_CodeID
      ,CodeDesc=in_CodeDesc
      ,CodeSeq=in_CodeSeq
      ,Stop_used=in_Stop_used
      ,Note=in_Note
      Where rwid=in_rwid and ouguid=in_OUguid;
       set outMsg=concat('「',in_CodeID,'」',"修改成功");  
end if; # 90

if err_code=0 And in_Rwid = 0 Then # 90 新增
      if in_CodeSeq=0 Then # 20-1 因為 codeseq=0 為syscode 用，所以不能為 0
	   set in_CodeSeq=(select ifnull(max(codeseq),0)+1 from tcatcode where syscode=in_Syscode and ouguid=in_OUguid);
      end if; # 20-1  
      INSERT INTO TCATCODE
      (ltUser,ltPid,CodeGuid,OUguid,SysCode,CodeID,CodeDesc,CodeSeq,Note)
      values
      (in_ltUser,in_ltPid,uuid(),in_OUguid,in_SysCode,in_CodeID,in_CodeDesc,in_CodeSeq,in_Note);
      set outMsg=concat('「',in_CodeID,'」',"新增成功");
end if; # 90 
  
end # Begin