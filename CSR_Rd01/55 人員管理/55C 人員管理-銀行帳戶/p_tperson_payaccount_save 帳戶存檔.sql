drop procedure if exists p_tperson_payaccount_save;

delimiter $$ 

create procedure p_tperson_payaccount_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_Emp_ID                    varchar(36)
,in_payAccount_default        tinyint(4)
,in_Bank_ID                   varchar(45)
,in_Account_ID                varchar(45)
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare in_Emp_Guid varchar(36);
/*
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
*/
 
set err_code=0; set outRwid=0; set outMsg='p_tperson_payaccount_save 執行中';

Insert into tlog_proc (ltpid,note) values ('rwid',in_rwid);
Insert into tlog_proc (ltpid,note) values ('Emp_ID',in_Emp_id);
Insert into tlog_proc (ltpid,note) values ('payAccount_default',in_payAccount_default);
Insert into tlog_proc (ltpid,note) values ('Bank_ID',in_Bank_ID);
Insert into tlog_proc (ltpid,note) values ('Account_ID',in_Account_ID);
Insert into tlog_proc (ltpid,note) values ('note',in_note);



if err_code=0 then # 10
 set isCnt=0;
 Select rwid,Emp_Guid into isCnt,in_Emp_Guid 
 from tperson where OUguid=in_OUguid And Emp_ID=in_Emp_ID;
  if isCnt=0 then set err_code=1; set outMsg='員工資料不存在'; end if;
end if; # 10

if err_code=0 then # 判斷是否有無修改
  set isCnt=0; 
  Select rwid into isCnt 
   From tperson_payaccount 
  Where rwid=in_Rwid And Emp_Guid=in_Emp_Guid And payAccount_default=in_payAccount_default And Bank_ID=in_Bank_ID And Account_ID=in_Account_ID And note=in_note;
 if isCnt>0 then set err_code=1; set outMsg='資料無修改'; end if;
 end if;
 
 if err_code=0 then # 判斷存在其他筆相同資料
  set isCnt=0; 
  Select rwid into isCnt 
   From tperson_payaccount 
  Where rwid!=in_Rwid And Emp_Guid=in_Emp_Guid And payAccount_default=in_payAccount_default And Bank_ID=in_Bank_ID And Account_ID=in_Account_ID And note=in_note
  limit 1;
 if isCnt>0 then set err_code=1; set outMsg='資料已存在'; end if; 
 end if;
 
if err_code=0 && in_payAccount_default='1' then # 89 新增&修改前執行，將預設清空
 # tperson_payaccount 的 payAccount_default 只能存 null及 1
 # 有設 unique index 所以也不能存 0
 Update tperson_payaccount 
 set payAccount_default=NULL
 Where Emp_Guid=in_Emp_Guid;
end if;
 
if err_code=0 && in_Rwid=0 then # 90 新增
  Insert into tperson_payaccount
 (ltUser,ltPid,Emp_Guid,payAccount_default,Bank_ID,Account_ID,note)
 values 
 (in_ltUser,in_ltPid,in_Emp_Guid,in_payAccount_default,in_Bank_ID,in_Account_ID,in_note);
 set outMsg=concat('「',in_Rwid,'」','新增完成');
 set outRwid=last_insert_id();
 end if; # 90 
 
 if err_code=0 && in_Rwid>0 then # 90 修改 
 Update tperson_payaccount Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid
 ,Emp_Guid                      = in_Emp_Guid
 ,payAccount_default            = if(in_payAccount_default='1','1',NULL)
 ,Bank_ID                       = in_Bank_ID
 ,Account_ID                    = in_Account_ID
 ,note                          = in_note
  Where rwid=in_Rwid;
 set outMsg=concat('「',in_Rwid,'」','修改成功');
 set outRwid=in_Rwid;
 end if; # 90 修改
 
 
 

end; # begin