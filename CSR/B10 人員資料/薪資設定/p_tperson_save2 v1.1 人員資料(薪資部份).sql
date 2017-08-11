drop procedure if exists p_tperson_save2; # 人員資料存檔(薪資部份)

delimiter $$

create procedure p_tperson_save2
(
 in_OUguid varchar(36)
,in_LtUser varchar(36)
,in_ltPid  varchar(36) 
,in_EmpID  varchar(36)     # 工號
,in_Type_Z15 varchar(36)   # 薪資發放方式，轉帳/現金
,in_Type_Z16 varchar(36)   # 計薪方式 月薪/日薪
,in_Type_Z17 varchar(36)   # 所得稅代扣
,in_Z17_Rate  decimal(5,3)  # 所得稅代扣 比率
,in_Z17_Money decimal(12,5) # 所得稅金額
,in_Type_A02  varchar(36)   # 
,in_Welfare_Rate decimal(5,3)
,out outMsg text
,out outRwid int
,out err_code int
)

begin
declare tlog_note text;
declare isCnt int;
DECLARE EXIT HANDLER FOR SQLEXCEPTION#, SQLWARNING
BEGIN
    ROLLBACK;
END;
set err_code = 0;
set outRwid=0;

 
call p_tlog(in_ltPid,tlog_note);
set outMsg='p_tperson_save,人員資料開始'; 

if err_code=0 then
  set outMsg=concat(in_EmpID  ,' '
,in_Type_Z15 ,' '
,in_Type_Z16 ,' '
,in_Type_Z17 ,' '
,in_Z17_Rate ,' '
,in_Z17_Money , ' '
,in_Type_A02 ,' '
,in_Welfare_Rate);   
end if;

if  err_code=0 && in_Type_Z17='C' && in_Z17_Rate=0 then
  set err_code=1; set outMsg='請輸入所得稅代扣金額';
end if;

if 0 && err_code=0 && Not (in_Welfare_Rate between 0 and 100) then
  set err_code=1; set outMsg='福利金代扣輸入範圍 0-100(％)';
end if;

if err_code=0 then # 90 修改資料，此程式不需要新增
 
Update tperson Set
 type_z15=in_Type_Z15,
 type_z16=in_Type_Z16,
 type_z17=in_Type_Z17,
 tax1_Rate=if(in_Z17_Rate>0,in_Z17_Rate,in_Z17_Money),
 Welfare_Rate=in_Welfare_Rate,
 overtypeguid=(select codeguid from tcatcode where syscode='a02' and ouguid=in_OUguid and codeid=in_Type_A02)
Where OUguid=in_OUguid And EmpID=in_EmpID;
set outMsg='90';
end if;
 
 
end # Begin