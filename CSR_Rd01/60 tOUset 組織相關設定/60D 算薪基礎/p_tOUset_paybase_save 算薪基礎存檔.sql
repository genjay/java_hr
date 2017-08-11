drop procedure if exists p_tOUset_paybase_save;

delimiter $$ 

create procedure p_tOUset_paybase_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_type_z06                  varchar(36)
,in_PayType_ID                varchar(36)
,in_Paytype_Value             tinyint(4)
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare in_PayType_Guid varchar(36);

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;   
 
set err_code=0; set outRwid=0; set outMsg='p_tOUset_paybase_save 執行中';

if err_code=0 then
 set isCnt=0;
 Select rwid,paytype_Guid into isCnt,in_PayType_Guid 
 from tOUset_paytype 
 Where OUguid=in_OUguid
   And paytype_ID=in_PayType_ID;
 if isCnt=0 then set err_code=1; set outMsg='paytype_guid錯誤'; end if;
end if;

if err_code=0 then # 判斷是否有無修改
  set isCnt=0; 
  Select rwid into isCnt 
   From tOUset_paybase 
  Where rwid=in_Rwid And type_z06=in_type_z06 And PayType_Guid=in_PayType_Guid And Paytype_Value=in_Paytype_Value And note=in_note;
  if isCnt>0 then set err_code=1; set outMsg=''; # 資料無修改,故意空白
  end if;
 end if;

if err_code=0 && in_Rwid=0 then # 90 新增
  Insert into tOUset_paybase
 (ltUser,ltPid,OUguid,type_z06,PayType_Guid,Paytype_Value,note)
 values 
 (in_ltUser,in_ltPid,in_OUguid,in_type_z06,in_PayType_Guid,in_Paytype_Value,in_note);
  set outMsg=concat('');
 set outRwid=last_insert_id();
 end if; # 90 
 
 if err_code=0 && in_Rwid>0 then # 90 修改 
 Update tOUset_paybase Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid
 ,type_z06                      = in_type_z06
 ,PayType_Guid                  = in_PayType_Guid
 ,Paytype_Value                 = in_Paytype_Value
 ,note                          = in_note
  Where rwid=in_Rwid;
 set outMsg=concat('');
 set outRwid=in_Rwid;
 end if; # 90 修改
 

end; # begin