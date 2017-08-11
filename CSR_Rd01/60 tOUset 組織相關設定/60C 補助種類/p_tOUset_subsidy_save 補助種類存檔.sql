drop procedure if exists p_tOUset_subsidy_save;

delimiter $$ 

create procedure p_tOUset_subsidy_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_Subsidy_ID                varchar(36)
,in_Subsidy_Desc              varchar(36)
,in_subsidy_rate              decimal(10,4)
,in_Note                      text
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
 
set err_code=0; set outRwid=0; set outMsg='p_demo 執行中';

if err_code=0 then # 判斷是否有無修改
  set isCnt=0; 
  Select rwid into isCnt 
  From tOUset_subsidy 
  Where rwid=in_Rwid And Subsidy_ID=in_Subsidy_ID And Subsidy_Desc=in_Subsidy_Desc And subsidy_rate=in_subsidy_rate And Note=in_Note;
 if isCnt>0 then set err_code=1; set outMsg='資料無修改'; end if;
 end if;
 
 if err_code=0 && not in_subsidy_rate between 0 And 100 then
  set err_code=1; set outMsg='補助比率只能輸入 0~100';
 end if;
 
 if err_code=0 && in_Rwid=0 then # 90 新增
  Insert into tOUset_subsidy
 (ltUser,ltPid,OUguid,Subsidy_ID,Subsidy_Desc,subsidy_rate,Note)
 values 
 (in_ltUser,in_ltPid,in_OUguid,in_Subsidy_ID,in_Subsidy_Desc,in_subsidy_rate,in_Note);
 set outRwid=last_insert_id();
 set outMsg='新增完成';
 end if; # 90

if err_code=0 && in_Rwid>0 then # 90 修改
Update tOUset_subsidy Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid
 ,Subsidy_ID                    = in_Subsidy_ID
 ,Subsidy_Desc                  = in_Subsidy_Desc
 ,subsidy_rate                  = in_subsidy_rate
 ,Note                          = in_Note
  Where rwid=in_Rwid;
 set outMsg=concat('「',in_Subsidy_ID,'」','修改成功');
 set outRwid=in_Rwid;
end if; # 90

end; # begin