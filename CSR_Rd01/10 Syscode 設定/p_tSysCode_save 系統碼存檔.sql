drop procedure if exists p_tSysCode_save; # 分類碼存檔

delimiter $$

create procedure p_tSysCode_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/ 
,in_syscode varchar(36) # syscode 
,in_codeDesc varchar(36) # codedesc
,in_who_used  varchar(36) # 使用範圍 tperson,tdoc_forget... 自定欄位使用
,in_Note text /*備註*/
,in_Rwid int  /*要修改的假單rwid*/
,out outMsg text /*回傳訊息，直接給user看的*/
,out outRwid int  /*修改資料的rwid*/
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

declare isCnt     int;

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
insert into tlog_proc (note) values ('sql error');
  end if;
END;  

set err_code = 0; 


 IF err_code=0 Then # 10
    set isCnt=0; set outMsg="10 判斷是否存在其他，相同資料";
    Select rwid into isCnt from tSyscode Where syscode=in_syscode and rwid!=in_rwid;
    if isCnt > 0 Then set err_code=1; set outMsg=concat('「',in_syscode,'」',"資料已存在"); set outRwid=isCnt; end if;
 end if;

if err_code=0 && in_Rwid >0 then # 15
  set isCnt=0;
  Select Rwid into isCnt from tSyscode Where rwid = in_Rwid;
  if isCnt=0 Then set err_code=1; set outMsg='資料不存在'; end if;
end if; #15
 
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
	(ltUser,ltPid,sysCode,SysCodeDesc,Note,who_used)
	Values
    (in_ltUser,in_ltPid,in_syscode,in_codeDesc,in_Note,in_who_used);

    set outMsg=concat('「',in_syscode,'」',"InsertSuccess");
  set outRwid=last_insert_id();
 end if; # 90 新增模式

 IF err_code=0 And in_Rwid>0 Then # 修改模式
    Update tSyscode set
	 ltUser=in_LtUser
     ,ltPid=in_ltPid 
     ,SysCodeDesc=in_codeDesc
     ,who_used=in_who_used
	 ,Note=in_Note
    Where rwid=in_rwid;
    set outMsg=concat('「',in_syscode,'」',"UpdateSuccess");
  set outRwid=in_Rwid;
 end if;


end # Begin