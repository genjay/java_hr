drop procedure if exists p_tSchEmp_save;

delimiter $$

create procedure p_tSchEmp_save
(
 in_OUguid   varchar(36)
,in_ltUser   varchar(36)
,in_ltpid    varchar(36) 
,in_EmpID    varchar(36) 
,in_Dutydate varchar(36) 
,in_holiday  varchar(36) 
,in_WorkID   varchar(36) 
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out outError int  # err_code
)

begin
/*
執行範例 
call p_tSchEmp_save
(
 'microjet','ltuser','ltpid'
,'A00514'    #in_EmpID    varchar(36) 
,'20140701' #in_Dutydate varchar(36) 
,'1'        #in_holiday  varchar(36) 
,'B'        #in_WorkID   varchar(36) 
,@a,@b,@c
);

select @a,@b,@c;

*/

DECLARE err_code int default '0'; 
DECLARE droptable int default '0'; # 0 代表測試中 1，正常使用

set @in_OUguid = IFNULL(in_OUguid,'');
set @in_ltUser = IFNULL(in_ltUser,'');
set @in_ltpid  = IFNULL(in_ltpid,''); 
set @in_EmpID  = IFNULL(in_EmpID,'');
set @in_Dutydate = IFNULL(in_Dutydate,'');
set @in_holiday  = IFNULL(in_holiday,'');
SET @in_WorkID   = IFNULL(in_WorkID,'');
set @outRwid   = 0;
set @outMsg    =''; 

if err_code=0 Then  # C 出勤日判斷
   set @xx3 = f_DtimeCheck(f_removeX(concat(in_Dutydate,'0000'))); 
   if @xx3 !='OK' Then set err_code=1;  set @outMsg=concat("出勤日  ",@xx3); end if; 
   if err_code=0 Then set @in_Dutydate = str_to_date(concat(f_removeX(  in_Dutydate)),'%Y%m%d'); end if;
   if droptable=0 Then insert into t_log(ltpid,note) values ('p_tSchEmp_save','出勤日判斷'); end if;
end if; # C

if err_code=0 Then # 10 抓 EmpGuid
   set @Empguid='';
   Select Empguid into @Empguid From tperson Where OUguid=@in_OUguid And EmpID=@in_EmpID;
   if ifnull(@Empguid,'')='' then set err_code=1; set @outMsg="人員代號錯誤"; end if;
end if;

if err_code=0 then # 20 jei workGuid
   set @workguid='';
   Select codeGuid into @workguid From tcatcode Where Syscode='A01' And OUguid=@in_OUguid And CodeID=@in_WorkID;
   if ifnull(@workguid,'')='' then set err_code=1; set @outMsg="班別代號錯誤"; end if;
end if;

if err_code=0 Then # 30 班別上班時間重疊檢查
   set @isCnt=0;
   set @listduty='';
   Select count(*),group_concat(a.dutydate order by 1) into @iscnt,@listduty
   from vdutystd_Emp a
   left join vdutystd_Emp b on a.Empguid=b.Empguid and a.dutydate != b.dutydate
      and b.dutydate between (a.dutydate- interval 1 day) And (a.dutydate+interval 1 day)  
   Where 1=1
    And a.OUguid =@in_OUguid
    And a.Empguid=@Empguid
    And a.dutydate=@in_dutydate
    And a.Std_ON  < b.Std_Off 
    And a.Std_Off > b.Std_On;
    if @isCnt>0 Then set err_code=1; set @outMsg=concat("班別錯誤，上班時間重疊",@listduty) ; end if;

end if; # 30


if err_code=0 Then # End

  insert into tSchEmp (Empguid,dutydate,holiday,workguid)
   values (@Empguid,@in_dutydate,@in_holiday,@workguid)
   On duplicate key update
   holiday=@in_holiday
   ,workguid=@workguid;

   set outMsg  =if(@outMsg='','成功',@outMsg);
   set outRwid =if(@outRwid=0,LAST_INSERT_ID(),@outRwid);
   set outError=err_code;
Else # 錯誤時 err_code > 0
   set outMsg=@outMsg;
   set outRwid=@outRwid;
   set outError=err_code;
end if; # End 

end;