drop procedure if exists p_tOverDoc_save; # 加班單存檔

delimiter $$

create procedure p_tOverDoc_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/
,in_EmpID varchar(36)
,in_Type  varchar(36)
,in_Dutydate varchar(36)
,in_DateStart  varchar(36)
,in_DateEnd    varchar(36)
,in_OverBefore  int
,in_OverHoliday int
,in_OverAfter   int 
,in_Note text /*備註*/
,in_Rwid int  /*要修改的假單rwid*/
,out outMessage text /*回傳訊息，直接給user看的*/
,out outDupRWID int  /*重疊的請假單*/
,out outErr_code int /*成功失敗代碼*/
)

begin
/*
執行範例 
call p_tOverDoc_save
(
 'microjet'
,'ltuser'
,'ltpid'
,'a00514'
,'c' # 加班類別
,'20140707'
,'2014-07-07 08:00'
,'2014-07-07 21:00'
,0 # 提早加班
,0 # 假日加班
,120 # 延後加班
,'Note'
,0 # rwid 0為新增
,@a # 執行訊息
,@b # duprwid
,@c #errcode
);

select * from vtoverdoc
order by rwid desc;
select @a,@b,@c;
*/

DECLARE err_code int default '0'; 

call p_SysSet(1);

set @in_OUguid =in_OUguid;
set @in_ltUser =in_ltUser ;
set @in_ltpid  =in_ltpid;
set @in_EmpID  =in_EmpID  ;
set @in_Type  =in_Type  ;
set @in_Dutydate=in_Dutydate;
set @in_DateStart   =  in_DateStart  ;
set @in_DateEnd     =  in_DateEnd  ;
set @in_OverBefore  =  in_OverBefore   ;
set @in_OverHoliday =  in_OverHoliday ;
set @in_OverAfter   =  in_OverAfter  ;
set @in_Note =  in_Note  ;
set @in_Rwid =  in_Rwid  ;

set @in_EmpGuid='';
set @in_TypeGuid='';

set @xx1 = f_DtimeCheck(f_removeX(in_DateStart));
if @xx1 !='OK' Then set err_code=1; set @outMsg=concat("時間(起) ",@xx1); end if;
 
set @xx2 = f_DtimeCheck(f_removeX(in_DateEnd));
if @xx2 !='OK' Then set err_code=1;  set @outMsg=concat("時間(迄) ",@xx2); end if;

set @xx3 = f_DtimeCheck(f_removeX(concat(in_Dutydate,'0000'))); 
if @xx3 !='OK' Then set err_code=1;  set @outMsg=concat("出勤日  ",@xx3); end if; 

if err_code=0 Then 
set @in_DateStart= str_to_date(concat(f_removeX(in_DateStart)),'%Y%m%d%H%i');
set @in_DateEnd  = str_to_date(concat(f_removeX(  in_DateEnd)),'%Y%m%d%H%i');  
set @in_Dutydate = str_to_date(concat(f_removeX(  in_Dutydate)),'%Y%m%d'); 

end if;


if err_code=0 And ifnull(in_OUguid,'')='' Then set err_code=1; set outMessage="OUguid 為必要輸入條件"; end if;
if err_code=0 And ifnull(in_EmpID,'')='' And ifnull(in_Rwid,0)=0 Then set err_code=1; set outMessage="工號及rwid不可同時為空值或零"; end if;
if err_code=0 And ifnull(in_Type,'')='' Then set err_code=1; set outMessage="type為必要輸入";end if;


if err_code=0 Then # B01 抓guid 

      Select empguid into @in_EmpGuid from tperson where OUguid=@in_OUguid and (EmpID=@in_EmpID or EmpGuid=@in_EmpID);
      Select codeguid into @in_TypeGuid from tcatcode Where syscode='A02' and OUguid=@in_OUguid and (codeID=@in_Type or codeGuid=@in_Type);
 
end if; # B01

if err_code=0 And @in_TypeGuid='' Then set err_code=1; set outMessage="加班類別錯誤"; end if;

if err_code=0 Then
   SELECT rwid into @isCnt FROM csrhr.toverdoc 
Where empGuid = @in_EmpGuid
and overStart < @in_DateEnd
and overEnd   > @in_DateStart limit 1;
   if @isCnt > 0 Then set err_code=1; set outMessage=concat("已存在其他加班單,單號",@isCnt); set outDupRWID=@isCnt; end if;

end if;

if err_code=0 Then 
   select close_date into @in_Close_Date from tOUset where ouguid=@in_OUguid;
   if @in_Dutydate < @in_Close_Date Then 
     set err_code=1; 
     set outMessage=concat("無法新增，輸入資料在關帳日之前",cast(@in_Close_date as char),"之前"); 
   end if;
end if;

if err_code=0 Then
   set @isCnt=0;
   select rwid into @isCnt from tOverdoc where closeStatus_z07>0 and rwid=@in_Rwid;
   IF @isCnt>0 Then set err_code=1; set outMessage=concat("此單據已關帳，不能修改 單據：",@in_Rwid);  end if;
end if;

if err_code=0 then # 檢查該加班單是否已經使用補休
   set  @isCnt = 0;
   Select offdocguid,rwid into  @offdocguid,@isCnt from tOffQuota_used
   Where QuotaDocGuid in (select OverDocGuid from tOverDoc Where rwid=@in_Rwid) limit 1;

   if @isCnt > 0 Then 
    Select rwid into @isCnt from tOffdoc where offdocguid=@offdocguid;
    set err_code=1; set outMessage=concat("此單據已使用補休，不能修改 請假單據：",@isCnt); end if;
 
end if;


 if err_code=0 And @in_rwid = 0 then # 新增模式
  insert into toverdoc
  (ltUser,ltpid,overdocguid,empguid,dutydate,overtypeguid
   ,overStart,overEnd,overMins_before,overMins_after,overMins_holiday,note)
  values
  (@in_ltUser,@in_ltpid,uuid(),@in_empguid,@in_dutydate,@in_typeGuid
   ,@in_DateStart,@in_DateEnd,@in_OverBefore,@in_OverAfter,@in_OverHoliday,@in_Note);
  
  set @lastID=LAST_INSERT_ID();
  set outMessage= concat("新增完成 單號：",@lastID);

  update tOverDoc A,tOvertype B
  set 
  a.Offtypeguid=b.offtypeguid
  ,a.Valid_time=b.Valid_time
  ,a.Valid_Type_Z08=b.Valid_Type_Z08
  ,a.OverToOff_Rate=b.OverToOff_Rate
  Where a.overtypeguid=b.overtypeguid and a.rwid= @lastID; 

 call p_tOffQuota_save(@in_OUguid,@in_LtUser,@in_Pid,@lastID,@in_Note,@a,@b,@c); 
 end if;

if err_code=0 And @in_rwid > 0 Then # 修改模式
   delete from tOffQuota Where QuotaDocguid in (select OverdocGuid from tOverdoc Where rwid=@in_Rwid);
update toverdoc set
 ltUser=@in_ltUser
,ltPid=@in_ltPid
,dutydate=@in_Dutydate
,overTypeGuid=@in_typeGuid
,overStart=@in_DateStart
,overEnd=@in_DateEnd
,overMins_before=@in_OverBefore
,overMins_After=@in_OverAfter
,overMins_holiday=@in_OverHoliday
,note=@in_note
Where closestatus_z07='0' And rwid=@in_rwid;

  update tOverDoc A,tOvertype B
  set 
  a.Offtypeguid=b.offtypeguid
  ,a.Valid_time=b.Valid_time
  ,a.Valid_Type_Z08=b.Valid_Type_Z08
  ,a.OverToOff_Rate=b.OverToOff_Rate
  Where a.overtypeguid=b.overtypeguid and a.rwid= @in_rwid;

  set @lastID=@in_rwid;
  set outMessage= concat("修改完成 單號：",@lastID);
  call p_tOffQuota_save(@in_OUguid,@in_LtUser,@in_Pid,@lastID,@in_Note,@a,@b,@c);

end if; 

   set outDupRWID=if(outDupRWID=0,@in_Rwid,outDupRWID);
   set outErr_code=err_code;

end; # begin



