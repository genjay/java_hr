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
,out outMessage text /*回傳訊息，直接給user看的*/
,out outDupRWID int  /*重疊的請假單*/
,out outErr_code int /*成功失敗代碼*/
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
DECLARE err_code int default '0';

set @in_OUguid=in_OUguid;
set @in_ltUser =in_ltUser;
set @in_ltpid = in_ltpid;
set @in_syscode = in_syscode;  
set @in_codeDesc=in_codeDesc;
set @in_Note = in_Note;
set @in_Rwid =in_Rwid;

   IF err_code=0 and ifnull(in_syscode,'')='' Then set err_code=1; set outMessage="syscode 為必要輸入條件"; end if;
   IF err_code=0 and ifnull(in_OUguid,'')='' Then set err_code=1; set outMessage="OUguid 為必要輸入條件"; end if;
   IF err_code=0 and ifnull(in_codeDesc,'')='' Then set err_code=1; set outMessage="CodeDesc 為必要輸入條件"; end if; 
   IF err_code=0 and ifnull(in_rwid,0)=0 And ifnull(in_syscode,'')='' Then set err_code=1; set outMessage="rwid與syscode不可同時為空白或零"; end if;

 IF err_code=0 Then
    set @isCnt=0;
    Select rwid into @isCnt from tSyscode Where syscode=@in_syscode and rwid!=@in_rwid;
    if @isCnt > 0 Then set err_code=1; set outMessage="Exists"; set outDupRWID=@isCnt; end if;
 end if;
 IF err_code=0 And ifnull(in_rwid,0)=0 Then # 新增模式
    insert into tSyscode 
	(ltUser,ltPid,sysCode,SysCodeDesc,Note)
	Values
    (@in_ltUser,@in_ltPid,@in_syscode,@in_codeDesc,@in_Note);

    set outMessage="InsertSuccess";

    end if;

 IF err_code=0 And ifnull(in_rwid,0)>0 Then # 修改模式
    Update tSyscode set
	 ltUser=@in_LtUser
     ,ltPid=@in_ltPid 
     ,SysCodeDesc=@in_codeDesc
	,Note=@in_Note
    Where rwid=@in_rwid;
    set outMessage="UpdateSuccess";
 end if;

 set outErr_code=err_code;
  
end