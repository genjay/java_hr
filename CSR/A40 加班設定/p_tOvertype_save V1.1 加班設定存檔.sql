drop procedure if exists p_tOvertype_save;

delimiter $$

create procedure p_tOvertype_save
(
 in_OUguid varchar(36)
,in_LtUser varchar(36)
,in_ltPid  varchar(36)
,in_rwid   int(10)  
,in_overType varchar(36)
,in_overDesc varchar(50)
,in_OverAMins int(11)
,in_OverBMins int(11)
,in_OverCMins int(11)
,in_PayType_Z01 varchar(1)
,in_OverHPay decimal(5,3)
,in_OverAPay decimal(5,3)
,in_OverBPay decimal(5,3)
,in_OverCPay decimal(5,3)
,in_OverToOff_Rate decimal(5,3)
,in_AlarmHH int(11)
,in_LockHH  int(11)
,in_offtype varchar(36)
,in_Valid_Time int(11)
,in_Valid_Type_Z08 varchar(1)
,in_OverUnit int(11) 
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)

begin
declare isCnt int;
set err_code=0;
set outRwid=3; # 前端程式需要，回傳值，所以先塞一個給他

call p_tlog(in_ltUser,'p_tOvertype_save 開始');

if err_code=0 then # 05
  if in_OverUnit=0 then set err_code=1; set outMsg='加班累進單位不可為 0'; end if;
end if; # 05

if err_code=0 And in_Rwid=0 Then # 10
  set outMsg='10';
  Select rwid into isCnt From vtOvertype Where OUguid=in_OUguid And Overtype=in_overType;
  if isCnt>0 Then set err_code=1; set outMsg='加班代碼已被使用'; end if;
end if; # 10 

if err_code=0 Then # 20 加班說明為空白
   if in_overDesc='' Then set err_code=1; set outMsg="20 說明不能空白"; end if;
end if; # 20 

if err_code=0 And in_Rwid=0 && 1 Then # 90 新增 
  set isCnt=0;
  Select rwid into isCnt from tCatCode Where Syscode='A02' And OUguid=in_OUguid And CodeID=in_overType;
  if isCnt=0 Then # 90-1 若 tCatcode 未建立，則建立資料
    insert into tCatcode 
    (ltUser,ltpid,codeguid,OUguid,Syscode,CodeID,CodeDesc) Values
    (in_LtUser,'p_tOvertype_save',uuid()  ,in_OUguid,'A02',in_overType,in_overDesc);
  end if; # 90-1
 
  insert into tOvertype(
     ltUser,ltpid
     ,OverTypeGuid
     ,OverAMins,OverBMins,OverCMins,PayType_Z01,OverHPay
     ,OverAPay,OverBPay,OverCPay,OverToOff_Rate,AlarmHH,LockHH
     ,OffTypeGuid
     ,Valid_Time,Valid_Type_Z08,OverUnit)
     values
     (in_LtUser ,in_ltPid 
     ,(Select codeGuid OverTypeGuid from tcatcode Where Syscode='A02' And OUguid=in_OUguid And (CodeGuid=in_overType or CodeID=in_overType))
     ,in_OverAMins,in_OverBMins,in_OverCMins,in_PayType_Z01,in_OverHPay
     ,in_OverAPay,in_OverBPay,in_OverCPay,in_OverToOff_Rate,in_AlarmHH,in_LockHH
     ,(Select codeguid OffTypeGuid from tcatcode Where Syscode='A00' And OUguid=in_OUguid And (CodeGuid=in_offtype or CodeID=in_offtype))
     ,in_Valid_Time,in_Valid_Type_Z08,in_OverUnit);
  set outMsg='新增完成';
  set outRwid=LAST_INSERT_ID();
    
end if; # 90 新增
if err_code=0 And in_Rwid>0 && 1 Then # 90 修改  
  Update tCatCode set 
   CodeDesc=in_overDesc
  ,ltUser=in_LtUser,ltPid='p_tOvertype_save'
  Where OUguid=in_OUguid And SysCode='A02' And CodeID=in_overType;

    update tOvertype set 
     ltUser = in_LtUser
     ,ltpid  = in_ltPid
    # ,OverTypeGuid=OverTypeGuid
     ,OverAMins =in_OverAMins
     ,OverBMins =in_OverBMins
     ,OverCMins =in_OverCMins
     ,PayType_Z01=in_PayType_Z01
     ,OverHPay   =in_OverHPay
     ,OverAPay   =in_OverAPay
     ,OverBPay   =in_OverBPay
     ,OverCPay   =in_OverCPay
     ,OverToOff_Rate =in_OverToOff_Rate
     ,AlarmHH    =in_AlarmHH
     ,LockHH     =in_LockHH
     ,OffTypeGuid =(Select codeguid from tcatcode Where Syscode='A00' And ouguid=in_OUguid And codeid=in_offtype)
     ,Valid_Time  =in_Valid_Time
     ,Valid_Type_Z08=in_Valid_Type_Z08
     ,OverUnit =in_OverUnit
     Where rwid=in_Rwid;  
  set outMsg='修改完成';
  set outRwid=in_Rwid;
end if; # 90 修改
 
end; # Begin