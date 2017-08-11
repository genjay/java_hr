drop procedure if exists p_tperson_salary_item_save;

delimiter $$ 

create procedure p_tperson_salary_item_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_Emp_ID                    varchar(36)
#,in_type_Z16                  varchar(45) # 月薪、時薪，Table已無用，因前端修改麻煩，所以暫時保留
,in_Paytype_ID                varchar(36)
,in_Paytype_Amt               decimal(10,4)
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare in_Emp_Guid varchar(36);
declare in_Paytype_Guid varchar(36);
declare isEnd int default 0;


DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  

set err_code=0; set outRwid=0; set outMsg='p_tperson_salary_item_save 未完成';

if err_code=0 # 00 
 && in_Rwid=0 && in_Paytype_Amt=0 && ifnull(in_note,'')='' then
 set isEnd=1;
 set err_code=0; set outMsg=''; # 新增時，金額 0及備註空白，不需要新增，也不用顯示訊息
end if;

if err_code=0 && isEnd=0 then # 01 抓Emp_Guid 必要
 set isCnt=0;
 Select rwid,Emp_Guid into isCnt,in_Emp_Guid
 from tperson
 Where OUguid=in_OUguid 
   And Emp_ID=in_Emp_ID;
 if isCnt=0 then set err_code=1; set outMsg='Emp_Guid 錯誤'; end if;
end if;

if err_code=0 && isEnd=0 then # 02 抓 paytype_guid 必要
 set isCnt=0;
 Select rwid,Paytype_Guid into isCnt,in_Paytype_Guid
 from tOUset_paytype
 Where OUguid=in_OUguid 
   And paytype_ID=in_Paytype_ID;
 if isCnt=0 then set err_code=1; set outMsg='Paytype_Guid 錯誤'; end if;
end if;

if err_code=0 && in_Rwid>0 && isEnd=0 then # 03 非必要(防範用)判斷該資料是否在該OUguid內
 set isCnt=0;
 Select rwid into isCnt
 from tperson_salary_item
 Where rwid=in_Rwid 
   And Emp_Guid=in_Emp_Guid limit 1;
 if isCnt=0 then set err_code=1; set outMsg='資料不在OUguid內'; end if;
end if;

if err_code=0 && in_Paytype_Amt!=0 && isEnd=0 then # 判斷是否有無修改
  set isCnt=0; 
  Select rwid into isCnt 
   From tperson_salary_item 
  Where rwid=in_Rwid And Emp_Guid=in_Emp_Guid And Paytype_Guid=in_Paytype_Guid And Paytype_Amt=in_Paytype_Amt And note=in_note;
 if isCnt>0 then set err_code=0; set outMsg=''; end if; #資料無修改
 end if;

if err_code=0 && in_Rwid=0 && isEnd=0 then # 90 新增
  Insert into tperson_salary_item
 (ltUser,ltPid,Emp_Guid,Paytype_Guid,Paytype_Amt,note)
 values 
 (in_ltUser,in_ltPid,in_Emp_Guid,in_Paytype_Guid,in_Paytype_Amt,in_note);
 set outMsg=concat('「',in_Paytype_ID,'」','新增完成');
 set outRwid=last_insert_id();
 end if; # 90 
 
if err_code=0 && in_Rwid>0 && isEnd=0 
  && Not (in_Paytype_Amt=0 && ifnull(in_note,'')='') then # 90 修改 
 Update tperson_salary_item Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid
 ,Emp_Guid                      = in_Emp_Guid
 ,Paytype_Guid                  = in_Paytype_Guid
 ,Paytype_Amt                   = in_Paytype_Amt
 ,note                          = in_note
  Where rwid=in_Rwid;
 set outMsg=concat('「',in_Paytype_ID,'」','修改成功');
 set outRwid=in_Rwid;
 end if; # 90 修改
 
if err_code=0 && in_Rwid>0 && isEnd=0 
 && in_Paytype_Amt=0 && ifnull(in_note,'')='' then # 90 刪除 
 Delete from tperson_salary_item 
 Where rwid=in_Rwid; 
 set outMsg=concat('「',in_Paytype_ID,'」','刪除成功');
 set outRwid=in_Rwid;
end if;

if err_code=1 && in_Rwid=0 && in_Paytype_Amt=0 then
 set isEnd=1;
 set err_code=1; set outMsg='代號空白或金額為0'; # 新增時，金額 0及備註空白，不需要新增，也不用顯示訊息
end if;


end; # begin