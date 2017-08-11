drop procedure if exists p_tOUset_paytype_list_save;

delimiter $$ 

create procedure p_tOUset_paytype_list_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_paytype_ID                varchar(36)
,in_Type_Z05                  varchar(36)
,in_Z05_Value                 tinyint(4)
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare is_paytype_Guid varchar(36);

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tOUset_paytype_list_save 執行中';


if err_code=0 then # 10
 set isCnt=0;
 Select paytype_guid into is_paytype_Guid 
 from tOUset_paytype
 where OUguid=in_OUguid
  And paytype_id=in_paytype_id;
 
end if; # 10 

if err_code=0 then # 判斷是否有無修改，需在抓取 10 is_paytype_Guid 之後執行
  set isCnt=0; 
  Select rwid into isCnt 
   From tOUset_paytype_list 
  Where rwid=in_Rwid And Paytype_Guid=is_Paytype_Guid And Type_Z05=in_Type_Z05 And Z05_Value=in_Z05_Value And note=in_note;
  if isCnt>0 then set err_code=1; set outMsg=''; # 故意用空白，資料無修改
  end if;
 end if;
 
if err_code=0 && Not in_Z05_Value in (0,1,-1) then
 set err_code=1; set outMsg='公式影響值，只能輸入0、1、-1';
end if;
 

if err_code=0 && in_Rwid=0 then # 90 新增
 Insert into tOUset_paytype_list
 (ltUser,ltPid,Paytype_Guid,Type_Z05,Z05_Value,note)
 values 
 (in_ltUser,in_ltPid,is_Paytype_Guid,in_Type_Z05,in_Z05_Value,in_note);
 set outRwid=last_insert_id();
 set outMsg=''; # 故意用空白
end if;
 
 if err_code=0 && in_Rwid>0 then # 90 修改
 Update tOUset_paytype_list Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid
 ,Paytype_Guid                  = is_Paytype_Guid
 ,Type_Z05                      = in_Type_Z05
 ,Z05_Value                     = in_Z05_Value
 ,note                          = in_note
  Where rwid=in_Rwid;
 
 set outMsg=concat('');# 故意用空白
 set outRwid=in_Rwid;
end if; # 90

end; # begin