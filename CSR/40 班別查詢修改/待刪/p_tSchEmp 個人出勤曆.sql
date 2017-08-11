drop procedure if exists p_tSchEmp; # 個人出勤曆存檔

delimiter $$

create procedure p_tSchEmp
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/
,in_EmpID varchar(36) /*員工工號*/
,in_DutyDate date /*出勤日*/
,in_Holiday int /*平日 0/假日1*/
,in_WorkID varchar(36) /*班別代號,syscode='A01'*/
,inNote text /*備註*/
,inRwid int  /*修改資料的rwid，在此程式用不帶，給0，就好*/
,out outMessage text /*回傳訊息，直接給user看的*/
,out outDupRWID int  /*重疊的請假單*/
,out outErr_code int /*成功失敗代碼*/
)

begin
/*
執行範例 
call p_tschemp
(
 'microjet' # ouguid
,'a00514-login' # ltUser 登入人員guid
,'in_ltpid'  # 程式代號
,'a00514' # 人員工號或empguid
,20140601 # 出勤日
,0 # 0=平日，1=假日
,'B' # 班別代號或其Workguid
,'' # Note
,'0' # rwid 此處無用，給 0   
,@outMessage # 訊息回傳  
,@outDupRWID # 重疊的rwid   
,@outErr_code # 錯誤碼 0 正常，> 0 錯誤 
)
;

*/

DECLARE err_code int default '0'; 

set @in_OUguid = in_OUguid;
set @in_ltUser = in_ltUser;
set @in_ltpid = if(trim(in_ltpid)='','p_tSchEmp',in_ltpid);
set @in_DutyDate = in_DutyDate;
set @in_Holiday = in_Holiday; 
set @inNote = inNote;
set @inRwid = inRwid; 

Case 
/*不需連資料庫的錯誤類型*/
When IFNULL(in_OUguid,'')=''  
 Then set outMessage="請輸入ouGuid，此為必要條件";
      set err_code= 1;


Else /*需要連資料庫判斷的錯誤類型*/
###################################################################
 IF err_code = 0  Then # A01 判斷人員輸入，是否正確
  select count(*) into @isCnt from tperson where empguid=in_empid and ouguid=in_OUguid;
   IF @isCnt > 0 Then # A02 代表 in_empid 為 guid 格式
    set @in_EmpGuid = in_Empid ;
  Else # A02
   select count(*) into @isCnt from tperson where ouguid=in_OUguid and empid=in_EmpID;
	IF @isCnt > 0 Then # A03
     set @in_EmpGuid = (select empguid from tperson where ouguid=in_OUguid and empid=in_EmpID);
    Else # A03
	 set err_code =1;
     set outMessage="人員輸入錯誤";
    end if; # A03
  end if; # A02

 end if; # A01 判斷人員輸入，是否正確

######################################################################################
 IF err_code = 0  Then # B01 判斷班別，是否正確
  select count(*) into @isCnt from tcatcode where Syscode='A01' and ouguid=in_OUguid and codeGuid=in_WorkID ; # workguid
   IF @isCnt > 0 Then # B02 代表 in_WORKid 為 guid 格式
    set @in_WorkGuid = in_WorkID;
  Else # B02
   select count(*) into @isCnt from tcatcode where Syscode='A01' and ouguid=in_OUguid and codeid=in_WorkID; # workid
	IF @isCnt > 0 Then # B03
     set @in_WorkGuid = (select codeguid from tcatcode where Syscode='A01' and ouguid=in_OUguid and codeid=in_WorkID);
    Else # B03
	 set err_code =1;
     set outMessage="班別輸入錯誤";
    end if; # B03
  end if; # B02
 end if; # B01 判斷班別，是否正確

end  case ;

###### 以下為判斷正確性後，進入新增、修改階段
IF err_code = 0 Then # 新增資料至 toffdoc

insert into tSchemp
(ltUser,ltpid,empguid,dutydate,holiday,workguid)
select 
 @in_ltUser
,@in_ltpid
,@in_empguid
,@in_dutydate
,@in_holiday
,@in_workguid
from vDutystd_emp
where 
    empGuid  =@in_empguid 
and dutydate =@in_dutydate 
and Not (workGuid =@in_WorkGuid and holiday=@in_holiday)
on duplicate key update
 ltUser=@in_ltuser
,ltpid=@in_ltpid
,workguid=@in_workguid
,holiday =@in_holiday;

  set @Change_RWID = LAST_INSERT_ID(); /*新增時，尚無rwid，所以新增後需取得*/

  set outMessage = "新增/修改成功";
  
end if; # IF err_code = 0 Then # 新增資料至  

set outErr_code = err_code;

IF err_code = 0 Then # 錯誤碼為 0時，執行相關程式用
  set @x=1;  # 無意義，可刪除，若語法無錯時
end if;
 

end;