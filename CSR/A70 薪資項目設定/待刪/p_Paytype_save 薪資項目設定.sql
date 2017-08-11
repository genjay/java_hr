drop procedure if exists p_tPaytype_save;

delimiter $$

create procedure p_tPaytype_save
( 
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36),
in_rwid   int(10)  , 
in_Paytype varchar(36),
in_Z05_ID  varchar(36),
in_Z10_ID  varchar(36),
in_PaytypeDesc varchar(36),
out outMsg text,
out outRwid int,
out err_code int
)
begin

declare tlog_note text; 
declare isCnt int;  
set err_code=0;set outRwid=0; set outMsg='';

/*
set tlog_note= concat("call p_tworkinfo_save(\n'"
,in_OUguid         ,"',\n'"
,in_ltUser         ,"',\n'"
,in_ltpid          ,"',\n'"  
,in_rwid           ,"',\n'"  
,in_type           ,"',\n'"  
,in_OnNext_Z04     ,"',\n'"  
,in_OnDutyHHMM     ,"',\n'"  
,in_OffNext_Z04    ,"',\n'"  
,in_OffDutyHHMM    ,"',\n'"  
,in_DelayBuffer    ,"',\n'"  
,in_OverNext_Z04   ,"',\n'"  
,in_OverSTHHMM     ,"',\n'"  
,in_OverBeforMin   ,"',\n'"  
,in_OverAfterMin   ,"',\n'"  
,in_OverHolidayMin ,"',\n'"  
,in_RangeSt        ,"',\n'"  
,in_RangeEnd       ,"',\n'"  
,in_WorkMinutes    ,"',\n" 
,'@a'              ,","
,'@b'              ,","
,'@c' 
,");");
*/

 call p_tlog(in_rwid,tlog_note);
set outMsg='paytype 設定執行中'; #'p_tworkinfo_save,開始'; 

set err_code=0;
set outMsg=in_Paytype;

if err_code=0 && in_Paytype='' then set err_code=1; set outMsg='paytype 不能空白'; end if;
if err_code=0 && in_PaytypeDesc='' then set err_code=1; set outMsg='paytypedesc 不能空白'; end if;

if err_code=0 then # 10 新增時，判斷
  set isCnt=0;
  Select rwid into isCnt from tcatcode 
  Where syscode='A06' and ouguid=in_OUguid And codeID=in_Paytype
   and codeguid != (select paytypeguid from tpaytype where rwid=in_Rwid);
  if isCnt>0 then set err_code=1; set outMsg='此代碼已被使用'; end if;
end if;


if err_code=0 && in_Rwid>0 Then # 90A 修改
  set isCnt=0;
  Select rwid into isCnt From tcatcode 
  Where codeguid = (select paytypeguid from tpaytype where rwid=in_Rwid);
  if isCnt>0 Then # 90A-1
   update tcatcode set
   ltUser=in_ltUser,ltPid='p_tPaytype_save'
   ,codeid=in_Paytype,codedesc=in_PaytypeDesc
   Where Rwid=isCnt 
    And Not (codeid=in_Paytype And codedesc=in_PaytypeDesc);
  end if; # 90A-1

  update tpaytype set
   type_z05=in_Z05_ID
  ,type_z10=in_Z10_ID 
  Where rwid=in_Rwid;
end if; # 90A 修改

if err_code=0 && in_Rwid=0 Then # 90B 新增
  set isCnt=0;
  Select rwid into isCnt from tcatcode where syscode='A06' and ouguid=in_OUguid 
  and codeid=in_Paytype;
  if isCnt=0 Then # 90B-1 tcatcode 不存在建立
  insert into tcatcode
  (OUguid,ltUser,ltPid,Codeguid,Syscode,CodeID,CodeDesc,CodeSEQ)
  Select in_OUguid,in_ltUser,in_ltPid,uuid(),'A06',in_Paytype,in_PaytypeDesc,0;
  end if; # 90B-1

  insert into tpaytype
  (ltUser,ltpid,PayTypeguid,Type_Z05,Type_Z10)
  values
  (in_ltUser,in_ltPid
  ,(select codeguid from tcatcode where syscode='A06' and ouguid=in_OUguid and codeid=in_Paytype)
  ,in_Z05_ID
  ,in_Z10_ID);
end if; # 90B 新增

end # Begin