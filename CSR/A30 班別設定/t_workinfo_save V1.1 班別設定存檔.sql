drop procedure if exists p_tworkinfo_save;

delimiter $$

create procedure p_tworkinfo_save
( 
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36),
in_rwid   int(10)  ,
in_type varchar(36) ,
in_OnNext_Z04 tinyint(4) ,
in_OnDutyHHMM time ,
in_OffNext_Z04 tinyint(4) ,
in_OffDutyHHMM time ,
in_DelayBuffer int(11) ,
in_OverNext_Z04 tinyint(4) ,
in_OverSTHHMM time ,
in_OverBeforMin int(11) ,
in_OverAfterMin int(11) ,
in_OverHolidayMin int(11) ,
in_RangeSt int(11) ,
in_RangeEnd int(11) ,
in_WorkMinutes int(11) ,
out outMsg text,
out outRwid int,
out err_code int
)
begin

declare tlog_note text; 
declare isCnt int; 
declare in_WorkGuid varchar(36); 
set err_code=0;

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

call p_tlog(in_rwid,tlog_note);
set outMsg=in_rwid; #'p_tworkinfo_save,開始'; 

if err_code=0 && 1 then # 判斷有無修改
  set isCnt=0;
  Select rwid into isCnt From tworkinfo 
  Where
   # ltUser=in_ltUser And 
   -- ltpid =in_ltpid And  
   Rwid=in_Rwid And
   OnNext_Z04=in_OnNext_Z04 And 
   OnDutyHHMM=in_OnDutyHHMM And 
   OffNext_Z04=in_OffNext_Z04 And 
   OffDutyHHMM=in_OffDutyHHMM And 
   DelayBuffer=in_DelayBuffer And 
   OverNext_Z04=in_OverNext_Z04 And 
   OverSTHHMM=in_OverSTHHMM And 
   OverBeforMin=in_OverBeforMin And 
   OverAfterMin=in_OverAfterMin And 
   OverHolidayMin=in_OverHolidayMin And 
   RangeSt=in_RangeSt And 
   RangeEnd=in_RangeEnd And 
   WorkMinutes=in_WorkMinutes ;
  if isCnt>0 then set err_code=1; set outMsg='';/*不需修改*/ end if;
end if;
 
if err_code='0' And in_Rwid=0 Then # 新增
  set isCnt=0;
  SELECT rwid into isCnt FROM TCATCODE WHERE syscode='A01' and OUGUID=in_OUguid 
  and (CODEID=in_type);
  if isCnt=0 Then # tcatcode 不存在時，建立
    insert into tCatcode 
    (ltUser,ltpid,codeguid,OUguid,Syscode,CodeID,CodeDesc) Values
    (in_LtUser,'p_tOvertype_save',uuid()  ,in_OUguid,'A01',in_overType,in_overDesc); 
  end if;

   insert into tworkinfo
   (
   LtUser ,ltPid 
   ,WorkGuid
   ,OnNext_Z04,OnDutyHHMM,OffNext_Z04,OffDutyHHMM,DelayBuffer,OverNext_Z04,OverSTHHMM,OverBeforMin,OverAfterMin,OverHolidayMin,RangeSt,RangeEnd,WorkMinutes)
   values 
   (in_LtUser ,in_ltPid 
   ,(Select codeGuid from tcatcode Where Syscode='A01' And OUguid=in_OUguid And codeID=in_Type)  
   ,in_OnNext_Z04,in_OnDutyHHMM,in_OffNext_Z04,in_OffDutyHHMM,in_DelayBuffer,in_OverNext_Z04,in_OverSTHHMM,in_OverBeforMin,in_OverAfterMin,in_OverHolidayMin,in_RangeSt,in_RangeEnd,in_WorkMinutes 
   );
   set outMsg="新增完成"; set outRwid=LAST_INSERT_ID();
   call p_tlog(in_ltPid,'新增完成'); 
end if;


if err_code='0' And in_Rwid>0 Then # 90 修改
   update tworkinfo set  
   ltUser=in_ltUser,
   ltpid =in_ltpid, 
   OnNext_Z04=in_OnNext_Z04,
   OnDutyHHMM=in_OnDutyHHMM,
   OffNext_Z04=in_OffNext_Z04,
   OffDutyHHMM=in_OffDutyHHMM,
   DelayBuffer=in_DelayBuffer,
   OverNext_Z04=in_OverNext_Z04,
   OverSTHHMM=in_OverSTHHMM,
   OverBeforMin=in_OverBeforMin,
   OverAfterMin=in_OverAfterMin,
   OverHolidayMin=in_OverHolidayMin,
   RangeSt=in_RangeSt,
   RangeEnd=in_RangeEnd,
   WorkMinutes=in_WorkMinutes  
   Where rwid=in_Rwid;
  set outMsg='修改完成'; set outRwid=in_Rwid;
  call p_tlog(in_ltPid,'修改完成');
end if; # 90 修改

end # Begin