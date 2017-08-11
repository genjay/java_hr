drop procedure if exists p_EmpChange; # 人員異動

delimiter $$

create procedure p_EmpChange
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/ 
,in_type_z09  varchar(36)  # 報到類型 C1 異動
,in_EmpID  varchar(36)     # 工號
,in_DepID  varchar(36)     # 部門代號
,in_Title_Name varchar(36) # 職務稱號 
,in_Valid_St  varchar(36)  # 生效日
,in_Note text  
,out outMsg text /*回傳訊息，直接給user看的*/
,out outRwid int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

begin 

declare isCnt int;
declare in_Empguid,in_DepGuid varchar(36);
declare in_last_type_z09,in_last_Title_Name,in_last_DepGuid varchar(36);
declare in_last_valid_date date;
DECLARE EXIT HANDLER FOR SQLEXCEPTION#, SQLWARNING
BEGIN
    ROLLBACK;
 set outMsg='發生錯誤，rollback'; 
 set err_code=1;
END;

set err_code = 0;
 
set outMsg='p_EmpChange'; 
set outRwid='0';

if err_code=0 then # 09 判斷 in_type_z09
  if Not substring(in_type_z09,1,1)='C' then 
  set err_code=1; set outMsg='此程式只能處理C開頭類型'; end if;
end if;
 
if err_code=0 then # 10 判斷人員、及抓empguid
  set isCnt=0;
  Select Rwid,Empguid Into isCnt,in_Empguid 
  from tperson where ouguid=in_OUguid And Empid=in_EmpID;
  if isCnt=0 then set err_code=1; set outMsg='人員代號錯誤';
  end if;
  
end if; # 10

if err_code=0 then # 15 判斷depID、及抓depguid
  set isCnt=0;
  Select Rwid,codeguid Into isCnt,in_DepGuid from tcatcode 
  where OUguid=in_OUguid And Syscode='A07' And CodeID=in_DepID;
  if isCnt=0 then set err_code=1; set outMsg='部門錯誤'; end if;
end if; # 15 

if err_code=0 then # 20 判斷生效日、離職否
  set isCnt=0;
  Select rwid,valid_date,type_z09 ,Title_Name,A07_guid
  into isCnt,in_last_valid_date,in_last_type_z09,in_last_Title_Name,in_last_DepGuid
  from temp_hirelog
  Where empguid=in_Empguid
  order by valid_date desc,ltdate desc limit 1;
  if err_code=0 && isCnt>0 && in_Valid_St<in_last_valid_date 
   then set err_code=1; set outMsg='生效日不可小於最後一筆資料'; end if;
  if err_code=0 && substring(in_last_type_z09,1,1)='Q' 
   then set err_code=1; set outMsg='該員工已離職'; end if; 
  if err_code=0 && (in_last_DepGuid=in_DepGuid && in_last_Title_Name=in_Title_Name)
   then set err_code=1; set outMsg='部門、職稱沒異動'; end if;
 
end if; # 20

if err_code=0 && 1 then # 90 修改資料
  start transaction;
  Insert into temp_hirelog
  (empguid,valid_date,type_z09,note,a07_guid,title_name)
  Values
  (in_Empguid,in_Valid_St,in_type_z09,in_note,in_DepGuid,in_Title_Name);
  
  if in_Valid_St < now() then # 90-1 若生效日小於今天，馬上生效
    update tperson set
     depguid=in_DepGuid,title_name=in_Title_Name
    where empguid=in_Empguid;
  end if; # 90-1
 commit;
end if; # 90 

end # Begin