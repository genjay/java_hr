drop procedure if exists p_tOUset_paytype_save;

delimiter $$ 

create procedure p_tOUset_paytype_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_Paytype_ID                varchar(36)
,in_Paytype_Desc              varchar(36)
,in_Break_Month_Z22           varchar(36)
,in_type_z16                  varchar(36)
,in_Stop_used                 int(1)
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tOUset_paytype_save 執行中';

if 0 && err_code=0 then
Insert into tlog_proc (ltpid,note) values ('rwid',in_rwid);
Insert into tlog_proc (ltpid,note) values ('Paytype_ID',in_Paytype_ID);
Insert into tlog_proc (ltpid,note) values ('Paytype_Desc',in_Paytype_Desc);
Insert into tlog_proc (ltpid,note) values ('Break_Month_Z22',in_Break_Month_Z22);
Insert into tlog_proc (ltpid,note) values ('Stop_used',in_Stop_used);
Insert into tlog_proc (ltpid,note) values ('note',in_note);
end if;

if err_code=0 && in_Rwid>0 then # 10 用rwid 判斷資料是否存在
 set isCnt=0;
 Select rwid into isCnt from tOUset_paytype 
 Where OUguid=in_OUguid And rwid=in_Rwid;
 if isCnt=0 then set err_code=1; set outMsg='資料不存在'; end if;
end if; # 10

if err_code=0 then # 20 判斷是否有無其他資料 
 set isCnt=0;
 Select rwid into isCnt from tOUset_paytype 
 Where OUguid=in_OUguid And paytype_id=in_Paytype_ID and rwid!=in_Rwid limit 1;
 if isCnt>0 then set err_code=1; set outMsg='已存在其他相同資料'; end if;
end if; # 20 

if err_code=0 && in_Rwid=0 then # 90 新增 
 Insert into tOUset_paytype
 (Paytype_Guid,OUguid,Paytype_ID,Paytype_Desc,Break_Month_Z22,Stop_used,type_z16,note)
 values 
 (uuid(),in_OUguid,in_Paytype_ID,in_Paytype_Desc,in_Break_Month_Z22,in_Stop_used,in_type_z16,in_note);
 set outRwid=last_insert_id();
 set outMsg=concat('「',in_Paytype_ID,'」','新增完成');
end if; # 90 新增
 
 if err_code=0 && in_Rwid>0 then # 90 
Update tOUset_paytype Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid
 ,Paytype_ID                    = in_Paytype_ID
 ,Paytype_Desc                  = in_Paytype_Desc
 ,Break_Month_Z22               = in_Break_Month_Z22
 ,Stop_used                     = in_Stop_used
 ,type_z16                      = in_type_z16
 ,note                          = in_note
  Where rwid=in_Rwid;
 set outMsg=concat('「',in_Paytype_ID,'」','修改完成');
 set outRwid=in_Rwid;
end if; # 90

end; # begin