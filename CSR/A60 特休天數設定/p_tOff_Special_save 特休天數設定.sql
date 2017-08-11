drop procedure if exists p_tOff_Special_save;

delimiter $$

create procedure p_tOff_Special_save
( 
in_OUguid  varchar(36),
in_LtUser  varchar(36),
in_ltPid   varchar(36), 
in_Rwid    int, # 0 新增 > 0 該資料的rwid
in_Ages    int, # 年資(月)
in_OffDay  int, # 特休(天)
in_Note   text,
out outMsg text,
out outRwid int,
out err_code int
)
begin

declare tlog_note text; 
declare isCnt int;  
set err_code=0;

set tlog_note= concat("call p_tOff_Special_save(\n'"
,in_OUguid         ,"',\n'"
,in_ltUser         ,"',\n'"
,in_ltpid          ,"',\n'"  
,in_Rwid           ,"',\n'" 
,in_Ages           ,"',\n'" 
,in_OffDay          ,"',\n'" 
,in_Note            ,"',\n" 
,'@a'              ,","
,'@b'              ,","
,'@c' 
,");"); 

call p_tlog(in_ltpid,tlog_note);
set outMsg='p_tOff_Special_save,開始'; 

if err_code=0 Then # 05 判斷是否需要修改
  set isCnt=0; set outMsg='判斷是否需要修改'; 
  Select rwid into isCnt from tOff_Special Where OUguid=in_OUguid And JobAges_m=in_Ages And Note=in_Note And Rwid=in_Rwid;
  if isCnt>0 Then set err_code=1; set outMsg=''; end if; # 不需修改，outMsg

end if; # 05

if err_code=0 Then # 10
  set isCnt=0; set outMsg='10 判斷有無資料與要修改的值一樣';
  Select rwid into isCnt from tOff_Special Where OUguid=in_OUguid And JobAges_m=in_Ages And Rwid!=in_Rwid;
  if isCnt>0 Then set err_code=1; set outMsg='已存在相同設定資料'; end if;
end if; # 10

if err_code=0 && in_Rwid=0 Then # 90
  Set outMsg='新增中';
  Insert into tOff_Special
  (OUguid,JobAges_m,OffDays,Note)
  Values
  (in_OUguid,in_Ages,in_OffDay,in_Note);
  set outRwid=LAST_INSERT_ID();
end if; # 90

if err_code=0 && in_Rwid>0 Then # 90-2
  set outMsg='修改中';
  Update tOff_Special Set 
  JobAges_m=in_Ages
  ,OffDays=in_OffDay
  ,Note=in_Note Where rwid=in_Rwid;
  
  set outRwid=in_Rwid;set outMsg=concat(in_OffDay,' 修改完成');
end if; # 90-2
 
end # Begin