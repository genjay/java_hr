drop procedure if exists p_tdoc_forget_save;

delimiter $$ 

create procedure p_tdoc_forget_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_Emp_id                    varchar(36)
,in_dutydate                  date
,in_forgetOn                  varchar(36) # 前面可以輸入空白，所以不能用datetime
,in_forgetOff                 varchar(36) # 前面可以輸入空白，所以不能用datetime
,in_note               		  text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code                    text
)  

begin
declare isCnt int;  
declare in_Emp_Guid varchar(36);
declare in_forgetDocGuid varchar(36);
declare in_CloseDate date;
declare in_Range_On,in_Range_Off datetime;
declare in_DateA,in_DateB datetime;

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
    set outMsg='sql error';
    set err_code=1;
  end if;
END;  

insert into tlog_proc (note) values (in_forgetOn),(in_forgetOff);
 
set err_code=0; set outRwid=0; set outMsg='p_tdoc_forget_save 執行中';

if err_code=0 && in_forgetOn='' && in_forgetOff='' then
	set err_code=1; set outMsg='時間起迄不可同時空白';
end if;

if err_code=0 && 1 then # 檢查起迄時間，空白或錯誤日期時間將變成 null
  set in_forgetOn =f_datetime(in_forgetOn,'');
  set in_forgetOff=f_datetime(in_forgetOff,'');
end if;

if err_code=0 then # 20 判斷關帳日
	Select Close_date into in_CloseDate
	from tOUset
	Where OUguid=in_OUguid;
	if in_dutydate<=in_CloseDate then set err_code=1; 
	set outMsg=concat('不能新增關帳日之前資料，關帳日：',in_CloseDate); end if;
end if; # 20 判斷關帳日

if err_code=0 then # 21 判斷及抓Emp_Guid
	set isCnt=0;
	Select rwid,Emp_Guid into isCnt,in_Emp_Guid 
	from tperson
	Where OUguid=in_OUguid
	  And Emp_id=in_Emp_id;
	if isCnt=0 then set err_code=1; set outMsg='工號錯誤'; end if;
end if; # 21 判斷及抓Emp_Guid

if err_code=0 then # 21-1 判斷出勤日報是否已關帳
	set isCnt=0;
	Select Rwid into isCnt from tduty_emp a
	Where a.Emp_Guid=in_Emp_Guid
	  and a.dutydate=in_dutydate 
	  and ifnull(a.CloseStatus,'0')!='0';
	if isCnt>0 then set err_code=1; set outMsg='此單據已關帳'; end if;
end if;# 21-1 判斷出勤日報是否已關帳

if err_code=0 then # 22 判斷是否存在相同單據資料
	set isCnt=0;
	Select rwid into isCnt
	from tdoc_forget
	Where rwid!=in_Rwid and Emp_Guid=in_Emp_Guid And Dutydate=in_dutydate;
	if isCnt>0 then set err_code=1; set outMsg='資料已存在'; end if;
end if;# 22 判斷是否存在相同單據資料 


if err_code=0 && 1 then # 23 判斷時間是否在rangeOn rangeOff 之間
	Select 
	 Range_on  - interval 6 hour
	,Range_off + interval 6 hour
	into in_Range_On,in_Range_Off
	from vtsch_emp
	where ouguid=in_OUguid
	and emp_id=in_Emp_id
	and caldate=in_Dutydate
	;

	if err_code=0 && not (in_forgetOn between in_Range_On and in_Range_Off) then
	set err_code=1; set outMsg=concat('時間錯誤，不在應出勤時間範圍內',in_Range_On,'~',in_Range_Off);
	end if;

	if err_code=0 && not (in_forgetOff between in_Range_On and in_Range_Off) then
	set err_code=1; set outMsg=concat('時間錯誤，不在應出勤時間範圍內',in_Range_On,'~',in_Range_Off);
end if;


end if; # 23

if err_code=0 && in_Rwid=0 then # 90 新增
set in_forgetDocGuid=uuid();
  Insert into tdoc_forget
 (ltUser,ltPid,forgetDocGuid,Emp_Guid,dutydate,forgetOn,forgetOff,note)
 values 
 (in_ltUser,in_ltPid,in_forgetDocGuid,in_Emp_Guid,in_dutydate,in_forgetOn,in_forgetOff,in_note);
 set outMsg=concat('「',in_Emp_id,'」','新增完成');
 set outRwid=last_insert_id();
 end if; # 90 

 if err_code=0 && in_Rwid>0 then # 90 修改 
 Update tdoc_forget Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid
 ,Emp_Guid                      = in_Emp_Guid
 ,dutydate                      = in_dutydate
 ,forgetOn                      = in_forgetOn
 ,forgetOff                     = in_forgetOff 
 ,note                          = in_note
  Where rwid=in_Rwid;
 set outMsg=concat('「',in_Emp_id,'」','修改成功');
 set outRwid=in_Rwid;
 end if; # 90 修改
 

end; # begin