drop procedure if exists p_Get_dutyinfo_STD;

delimiter $$ 

create procedure p_Get_dutyinfo_STD
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_Emp_ID varchar(36)
,in_Dutydate  date # 出勤日
,out out_WorkID  varchar(36)  # 出勤日的班別
,out out_Holiday int          # 是否假日
,out out_STDOn   varchar(36)  # 應上班時間 
,out out_STDOff  varchar(36)  # 應下班時間
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
 
if err_code=0 then
	set out_WorkID='A';
	Select std_On,std_Off,worktype_id 
	into out_STDOn,out_STDOff,out_WorkID
	from vtsch_emp
	where OUguid=in_OUguid
	and emp_id=in_Emp_ID
	and caldate=in_Dutydate;  
end if;

end; # begin