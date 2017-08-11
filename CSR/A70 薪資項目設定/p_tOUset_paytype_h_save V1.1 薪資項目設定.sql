drop procedure if exists p_tOUset_paytype_h_save;

delimiter $$

create procedure p_tOUset_paytype_h_save
( 
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36),
in_rwid       int(10), 
in_A06_ID   varchar(36), 
in_A06_Desc varchar(36),
in_Z10_ID   varchar(36), 
in_Note    text,
out outMsg text,
out outRwid int,
out err_code int
)
begin

declare tlog_note text; 
declare in_A06_Guid,in_Desc varchar(36);
declare isCnt int;  
set err_code=0;set outRwid=0; set outMsg='p_tOUset_paytype_h_save';

if err_code=0 then # 10 判斷tcatcode
  set isCnt=0; set in_Desc='';
  Select rwid,codeguid,codeDesc into isCnt,in_A06_Guid,in_Desc
  from tcatcode 
  where syscode='A06' and OUguid=in_OUguid and codeid=in_A06_ID;

  if isCnt>0 && in_A06_Desc!=in_Desc then
   update tcatcode set codeDesc=in_A06_Desc
   where rwid=isCnt; 
  end if;
  
  if isCnt=0 then # 若tcatcode 未建立，建立tcatcode
   set in_A06_Guid=uuid();
   insert into tCatcode
   (OUguid,syscode,codeID,codeDesc,codeguid)
   values
   (in_OUguid,'A06',in_A06_ID,in_A06_Desc,in_A06_Guid);
  end if;

end if; # 10 
 
if err_code=0 then # 90 修改
 insert into tOUset_paytype_h
 (a06_guid,type_z10,note)
 values
 (in_A06_Guid,in_Z10_ID,in_Note)
 on duplicate key update
 type_z10=in_Z10_ID,
 note=in_Note;
 set outMsg='修改完成';
end if; # 90 修改
 
end # Begin