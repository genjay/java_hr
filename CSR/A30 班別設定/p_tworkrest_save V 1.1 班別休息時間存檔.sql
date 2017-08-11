drop procedure if exists p_tworkrest_save;

delimiter $$

create procedure p_tworkrest_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) 
,in_WorkID varchar(36)
,in_holiday int
,in_stHHMM time
,in_stNext int
,in_enHHMM time
,in_enNext int
,in_CutTime int
,in_Note text /*備註*/
,in_Rwid int  /*要修改的單據rwid*/
,out outMsg text /*回傳訊息，直接給user看的*/
,out outRwid int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin
/*
執行範例 
call p_tworkrest_save
(
 'microjet' #ouguid
,'in_ltUser' # ltUser
,'in_ltpid' # ltpid 
,'A' # workID
,'0' # holiday
,'07:00:00' # in_stHHMM time
,'0' # in_stNext int -1/0/1
,'07:10:00' # in_enHHMM time
,'0' #in_enNext int -1/0/1
,'0' # cuttime 0/1
,'Note ' # 備註
,'0' # inRwid int  要修改的單據，放 0，就可以
,@outMessage #回傳訊息，直接給user看的
,@outDupRWID #重疊的請假單
,@outErr_code #成功失敗代碼
);

*/

declare tlog_note text; 
declare isCnt int;
declare in_WorkGuid text;
set err_code =0;

set tlog_note= concat("call p_tworkrest_save(\n'"
,in_OUguid    ,"',\n'"
,in_ltUser    ,"',\n'"
,in_ltpid     ,"',\n'"  
,in_WorkID    ,"',\n'"  
,in_holiday   ,"',\n'"  
,in_stHHMM    ,"',\n'"  
,in_stNext    ,"',\n'"  
,in_enHHMM    ,"',\n'"  
,in_enNext    ,"',\n'"  
,in_CutTime   ,"',\n'"  
,in_Note      ,"',\n'"     
,in_Rwid      ,"',\n"
,'@a'         ,","
,'@b'         ,","
,'@c' 
,");");

call p_tlog(in_ltPid,tlog_note);
set outMsg='p_tworkrest_save,開始';

if err_code=0 then # 10
  set outMsg='10 判斷班別及抓取班別guid';
  Select codeGuid into in_WorkGuid From tcatcode Where syscode='A01' and ouguid=in_OUguid and codeID=in_WorkID;  
  if ifnull(in_Workguid,'')='' Then set err_code=1; set outMsg="班別錯誤"; end if;
end if; # 10

if err_code=0 Then # 20 判斷是否需要存檔
  set isCnt=0; set outMsg='20 判斷是否需要存檔'; 
  select rwid into isCnt from tworkrest
  Where 1=1  
   and rwid = in_Rwid
   and holiday=in_holiday
   and stNext_Z04=in_stNext And stHHMM=in_stHHMM
   and enNext_Z04=in_enNext And enHHMM=in_enHHMM
   and cuttime=in_cuttime ;
  if isCnt>0 Then set err_code=1; set outMsg=''/*資料都無異動，前端也不要有訊息*/; end if;
end if;

if err_code=0 Then # 25 判斷起迄
  if f_OffsetDtime(in_stNext,now(),in_stHHMM)>=f_OffsetDtime(in_enNext,now(),in_enHHMM)
  Then set err_code=1; set outMsg="時間起迄不合理"; end if; 
end if;

if err_code=0  Then # 30 判斷修改值，是否重疊其他資料
  set isCnt=0; set outMsg='30 判斷修改值，是否重疊其他資料';
  Select rwid into isCnt
  from vtworkrest a
  Where 1=1 
  And rwid != in_Rwid 
  And OUguid=in_OUguid And workID=in_WorkID And holiday=in_holiday
  And f_OffsetDtime(stNext_Z04,now(),stHHMM) < f_OffsetDtime(in_enNext,now(),in_enHHMM)
  And f_OffsetDtime(enNext_Z04,now(),enHHMM) > f_OffsetDtime(in_stNext,now(),in_stHHMM) limit 1 ;
  if isCnt>0 Then set err_code=1; set outMsg="時間重疊，請確認"; end if;
end if;


IF err_code = 0 and in_Rwid =0 Then # 90 新增
  set outMsg='90 準備新增';
  insert into tworkrest
   (ltUser,ltpid,
    Workguid,holiday,stNext_Z04,stHHMM,enNext_z04,enHHMM,cuttime)
   select 
   in_ltUser,in_ltpid
  ,in_Workguid,in_Holiday,in_stNext,in_stHHMM,in_EnNext,in_enHHMM,in_Cuttime
  From tworkrest a
  Where 
   Not exists (select * from tworkrest b where b.workguid=in_Workguid and b.holiday=in_holiday
   and b.stNext_z04=in_stNext and b.stHHMM=in_stHHMM
   and b.enNext_z04=in_enNext and b.enHHMM=in_enHHMM) limit 1;
  set outMsg='新增成功';
 
end if; # B01

if err_code=0 And in_Rwid>0 Then # 90 修改
   update tworkrest set
     ltUser     = in_ltUser
    ,ltpid      = in_ltpid
    ,holiday    = in_holiday
    ,stNext_z04 = in_stNext
    ,stHHMM     = in_stHHMM
    ,enNext_z04 = in_enNext
    ,enHHMM     = in_enHHMM
    ,cuttime    = in_cuttime
    where rwid=in_rwid; 
  set outMsg=concat('修改完成');

end if; # 90 

end; # Begin