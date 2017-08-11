drop procedure if exists p_Get_NewEmpID;

delimiter $$ 

create procedure p_Get_NewEmpID
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_PreChar   varchar(36) # 前置輸入
,out outEmpID text # 新員工工號
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;   
declare isMaxEmpID     varchar(36);
declare isMaxEmpID_Sno varchar(255);
declare isEmpID_Pre    varchar(255);
declare i,j int default 1;
declare isSno_length int;

/*
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
 */
set err_code=0; set outRwid=0; set outMsg='p_demo 執行中';

set in_PreChar=trim(in_PreChar);

if err_code=0 && length(in_PreChar)>1 then
 set isCnt=0;
 Select rwid into isCnt from tperson
 Where OUguid=in_OUguid 
   and emp_id=in_PreChar;
 if isCnt>0 
 then set err_code=1; set outMsg=concat(in_PreChar,'已被使用'); 
 else set outEmpID=in_PreChar; set err_code=0; set outMsg=concat(in_PreChar,'可以使用'); 
 end if;
end if;

if err_code=0 && length(in_PreChar)<=1 then # 計算新的工號
/* 不能用max(emp_id) 取最後工號
 因為 A03、A00514同時存在時，會抓到A03
*/
 set @sql=concat("
 Select emp_id into @isMaxEmpID
 from tperson 
 where ouguid='",in_OUguid,"'
   and emp_id like '",in_PreChar,"%'"
," order by length(emp_id) desc,emp_id desc limit 1;");
 insert into tlog_proc (note) values (@sql);
 prepare s1 from @sql;
 execute s1; 
 set isMaxEmpID=@isMaxEmpID;
 -- set @isMaxEmpID=null;
  
 set j=length(isMaxEmpID); # 工號長度

While i>0 && i<j do # 
 if right(isMaxEmpID,i) regexp '^[0-9]*$' 
 then 
  set isMaxEmpID_Sno = right(isMaxEmpID,i); # 抓右邊數字
  set isSno_length=i; # 數字的長度
  set isEmpID_Pre=substring(isMaxEmpID,1,j-i); # 前置符號長度
  set i=i+1;
 Else set i=0; # 遇到非數字，停止往前找
 end if;
end While;

set outEmpID=concat(isEmpID_Pre,lpad(isMaxEmpID_Sno+1,isSno_length,0));

Case 
When isMaxEmpID_Sno>0 Then 
set outEmpID=concat(isEmpID_Pre,lpad(isMaxEmpID_Sno+1,isSno_length,0));
set outMsg=concat(outEmpID,'可以使用');

When length(in_PreChar)>=1 && isMaxEmpID_Sno is null then
 set outEmpID=in_PreChar;
 set outMsg=concat('無',in_PreChar,'開頭的工號');
 set err_code=1;
When  length(in_PreChar)=0 && isMaxEmpID_Sno is null then 
 # 若前置輸入空白，及isMaxEmpID_Sno空白，代表尚無資料
 # 讓user 從 0001 開始編號
 set outEmpID='0001';
 set outMsg=concat('第一筆，預設：',outEmpID);
else set err_code=1; set outMsg='error'; # 不應該出現此狀況
end case; 

end if;# 計算新的工號

end; # begin