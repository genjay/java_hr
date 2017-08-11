drop procedure if exists p_tSysCode_save; # 分類碼存檔

delimiter $$

create procedure p_tSysCode_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/ 
,in_syscode varchar(36) # syscode 
,in_codeDesc varchar(36) # codedesc
,in_Note text /*備註*/
,in_Rwid int  /*要修改的假單rwid*/
,out outMsg text /*回傳訊息，直接給user看的*/
,out outRwid int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin
/*

call p_tsyscode_save('microjet','user','pid'
,'A9d98' # syscode
,'Tsyscode' # codeDesc
,''  #Note 
,1    #rwid 0 代表新增
,@a,@b,@c);

*/
declare tlog_note text;
declare isCnt     int;
set err_code = 0;

set tlog_note= concat("call p_tSysCode_save(\n'"
,in_OUguid  ,"',\n'"
,in_ltUser  ,"',\n'"
,in_ltpid   ,"',\n'"  
,in_Syscode ,"',\n'"  
,in_codeDesc,"',\n'"  
,in_Note    ,"',\n'"  
,in_Rwid  ,"',\n"
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");");
call p_tlog(in_ltPid,tlog_note);
 
 IF err_code=0 Then # 10
    set isCnt=0; set outMsg="10 判斷是否存在其他，相同資料";
    Select rwid into isCnt from tSyscode Where syscode=in_syscode and rwid!=in_rwid;
    if isCnt > 0 Then set err_code=1; set outMsg="Exists"; set outRwid=isCnt; end if;
 end if;
 
IF err_code=0 Then # 20 值都無修改時，err_code=1 中斷執行、outMsg 空值
  set isCnt=0; set outMsg="20 判斷有無修改";
  Select rwid into isCnt from tSyscode Where rwid=in_Rwid and syscode=in_syscode and syscodeDesc=in_codeDesc and note=in_note;
  if isCnt > 0 Then set err_code=1; set outMsg=""; end if;
end if; # 20

if err_code=0 Then # 30 說明為空白，中斷執行及outMsg回傳
  IF ifnull(in_codeDesc,'')='' Then set err_code=1; set outMsg=concat('「',in_syscode,'」',"說明不能為空白"); end if;

end if;


 IF err_code=0 And in_Rwid=0 Then # 90 新增模式
    insert into tSyscode 
	(ltUser,ltPid,sysCode,SysCodeDesc,Note)
	Values
    (in_ltUser,in_ltPid,in_syscode,in_codeDesc,in_Note);

    set outMsg=concat('「',in_syscode,'」',"InsertSuccess");
 end if; # 90 新增模式

 IF err_code=0 And in_Rwid>0 Then # 修改模式
    Update tSyscode set
	 ltUser=in_LtUser
     ,ltPid=in_ltPid 
     ,SysCodeDesc=in_codeDesc
	,Note=in_Note
    Where rwid=in_rwid;
    set outMsg=concat('「',in_syscode,'」',"UpdateSuccess");
 end if;


end # Begin