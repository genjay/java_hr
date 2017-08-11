drop procedure if exists p_tCatCode_save; # 分類碼存檔

delimiter $$

create procedure p_tCatCode_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/ 
,in_syscode varchar(36) # syscode
,in_codeID varchar(36) # codeID
,in_codeDesc varchar(36) # codedesc
,in_codeSeq int # codeseq
,in_stop_used int # 0 正常/1 停用
,in_Note text /*備註*/
,in_Rwid int  /*要修改的假單rwid*/
,out outMessage text /*回傳訊息，直接給user看的*/
,out outDupRWID int  /*重疊的請假單*/
,out outErr_code int /*成功失敗代碼*/
)

begin
/*
call p_tCatCode_save
(
 'microjet'
,'ltUser'
,'ltpid'
,'a00' #syscode
,'a'   # codeid
,'事假' # codedesc
,'2'    # codeseq
,'0'    # stopused
,'note' # note
,'0'    # rwid
,@outMessage  
,@outDupRWID  
,@outErr_code  
);

*/
DECLARE err_code int default '0';

set @in_OUguid=in_OUguid;
set @in_ltUser =in_ltUser;
set @in_ltpid = in_ltpid;
set @in_syscode = in_syscode;
set @in_codeID = in_codeID;
set @in_codeDesc = in_codeDesc;
set @in_codeSeq = in_codeSeq;
set @in_stop_used = in_stop_used;
set @in_Note = in_Note;
set @in_Rwid =in_Rwid;

   IF err_code=0 and in_syscode='' Then set err_code=1; set outMessage="syscode 為必要輸入條件"; end if;
   IF err_code=0 and in_OUguid='' Then set err_code=1; set outMessage="OUguid 為必要輸入條件"; end if;
   IF err_code=0 and in_CodeID='' Then set err_code=1; set outMessage="CodeID 為必要輸入條件"; end if; 
   IF err_code=0 and in_codeDesc='' Then set err_code=1; set outMessage="CodeDesc 為必要輸入條件"; end if; 


IF err_code=0  Then # 新增/修改 模式時，判斷是否有存在相同資料
   set @isCnt = 0;
   SELECT RWID into @isCnt FROM TCATCODE 
   WHERE SYSCODE=@in_syscode and ouguid=@in_ouguid
   and codeID=@in_codeID
   and rwid != @in_Rwid;
   set outDupRWID = @isCnt;
   IF @isCnt > 0 Then set err_code=1; set outMessage="已存在相同資料"; end if;
END IF;

IF err_code=0 Then # Z99 完全無誤，存檔
   
   if @in_Rwid = 0 Then # 新增模式

      set @in_CodeSeq=(select ifnull(max(codeseq),0)+1 from tcatcode where syscode=@in_Syscode and ouguid=@in_OUguid);
      set @in_stopused=0; # 新增模式，不可以輸入停用
      INSERT INTO TCATCODE
      (ltUser,ltPid,CodeGuid,OUguid,SysCode,CodeID,CodeDesc,CodeSeq,Note)
      values
      (@in_ltUser,@in_ltPid,uuid(),@in_OUguid,@in_SysCode,@in_CodeID,@in_CodeDesc,@in_CodeSeq,@in_Note);
      set outMessage="新增成功";
   end if;

   if @in_Rwid > 0 Then # 修改模式      
      
      if in_CodeSeq=0 Then # 因為 codeseq=0 為syscode 用，所以不能為 0
	   set @in_CodeSeq=(select ifnull(max(codeseq),0)+1 from tcatcode where syscode=@in_Syscode and ouguid=@in_OUguid);
      end if;
      update tcatcode set
       ltUser=@in_ltUser
      ,ltpid=@in_ltPid
      ,CodeID=@in_CodeID
      ,CodeDesc=@in_CodeDesc
      ,CodeSeq=@in_CodeSeq
      ,Stop_used=@in_Stop_used
      ,Note=@in_Note
      Where rwid=@in_rwid and ouguid=@in_OUguid;
       set outMessage="修改成功";
   end if;
 
end if; # Z99

 set outErr_code=err_code;
  
end