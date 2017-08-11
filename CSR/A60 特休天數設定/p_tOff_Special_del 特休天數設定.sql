drop procedure if exists p_tOff_Special_del;

delimiter $$

create procedure p_tOff_Special_del
( 
in_OUguid  varchar(36),
in_LtUser  varchar(36),
in_ltPid   varchar(36), 
in_Rwid    int, # 0 新增 > 0 該資料的rwid 
out outMsg text,
out outRwid int,
out err_code int
)
begin

declare tlog_note text; 
declare in_OffDay text;
declare in_JobAges_m text;
declare isCnt int;  
set err_code=0;
/*
call p_tOff_Special_del
( 
'microjet'
,'ltUser'
,'ltPid'
, 0  #in_Rwid    int, 
,@a,@b,@c
);

select @a,@b,@c;
*/

set tlog_note= concat("call p_tOff_Special_del(\n'"
,in_OUguid         ,"',\n'"
,in_ltUser         ,"',\n'"
,in_ltpid          ,"',\n'"  
,in_Rwid           ,"',\n" 
,'@a'              ,","
,'@b'              ,","
,'@c' 
,");"); 

call p_tlog(in_ltpid,tlog_note);
set outMsg='p_tOff_Special_del,開始'; 

if err_code=0 Then # 10
  set isCnt=0;
  Select rwid into isCnt from tOff_special Where OUguid=in_OUguid And Rwid=in_Rwid;
  if isCnt=0 Then set err_code=1; set outMsg='無此資料'; end if;
end if; # 10

if err_code=0 Then # 90
  Select OffDays,JobAges_m into in_OffDay,in_JobAges_m from tOff_special Where Rwid=in_Rwid;
  set outMsg=concat(in_OffDay,':',in_JobAges_m,' 刪除中'); 
  delete from tOff_special Where rwid=in_Rwid;
end if; # 90 
  
end # Begin