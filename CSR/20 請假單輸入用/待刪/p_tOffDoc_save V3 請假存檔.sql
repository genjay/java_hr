drop procedure if exists p_tOffDoc_save;

delimiter $$

create procedure p_tOffDoc_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36)  
,in_EmpID varchar(36)
,in_Type varchar(36)
,in_DateStart  varchar(36)
,in_DateEnd    varchar(36)
,in_OffMins    int  
,in_Note text  
,in_Rwid int ,  
out outMsg text,
out outRwid int,
out outError int
)

begin

DECLARE err_code int default '0';

set @in_OUguid=ifnull(in_OUguid,'');
set @in_ltUser=ifnull(in_ltUser,'');
set @in_ltPid=ifnull(in_ltPid,'');
set @in_EmpID=ifnull(in_EmpID,'');
set @in_Type=ifnull(in_Type,''); 

set @xx1 = f_DtimeCheck(f_removeX(in_DateStart));
if @xx1 !='OK' Then set @err_code=1; set @outMsg=concat("時間(起) ",@xx1); end if;
 
set @xx2 = f_DtimeCheck(f_removeX(in_DateEnd));
if @xx2 !='OK' Then set @err_code=1;  set @outMsg=concat("時間(迄) ",@xx2); end if;


set @in_DateStart= str_to_date(concat(f_removeX(in_DateStart)),'%Y%m%d%H%i');
set @in_DateEnd  = str_to_date(concat(f_removeX(  in_DateEnd)),'%Y%m%d%H%i');
 

set @in_OffMins  = ifnull(in_OffMins,'0');
set @in_rwid  = ifnull(in_rwid,'0'); 
set @in_note  = ifnull(in_note,''); 
set @outMsg='';
set @outRwid='0';
set @outError='0';
set @in_EmpGuid='';
set @in_TypeGuid='';

set @debug='1';

 insert into t_log (ltpid,note) values ('p_toffdoc_save',
concat( "call p_toffdoc_save(\n'"
,@in_OUguid  ,"',\n'"
,@in_ltUser  ,"',\n'"
,@in_ltpid   ,"',\n'"
,@in_EmpID   ,"',\n'"
,@in_Type   ,"',\n'"
,@in_DateStart    ,"',\n'"
,@in_DateEnd     ,"',\n'"
,@in_OffMins     ,"',\n'"
,@in_Note   ,"',\n'"
,@in_Rwid  ,"',\n"
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");" )); 

if @in_DateStart > @in_DateEnd Then set err_code=1; set @outMsg="日期起迄錯誤"; end if;

if err_code=0 Then # A00 抓guid 
      set @in_OfftypeDesc='';
      Select empguid into @in_EmpGuid from tperson where OUguid=@in_OUguid and (EmpID=@in_EmpID or EmpGuid=@in_EmpID 
        or empguid =(select empguid from toffdoc where rwid=@in_rwid));
      Select codeguid,concat(codeid,' ',codeDesc) into @in_TypeGuid,@in_OfftypeDesc from tcatcode Where syscode='A00' and OUguid=@in_OUguid and (codeID=@in_Type or codeGuid=@in_Type);
 
end if; # A00 抓guid 

if err_code=0 Then # 00 判斷資料是否在 tOUset 關帳日之後
   select close_date into @in_Close_date from touset where ouguid=@in_OUguid;
   if date(@in_DateStart) < @in_Close_date Then
      set err_code=1; set @outMsg=concat("無法新增",cast(@in_Close_date as char),"以前的資料，因為已關帳");
   end if; #00-1
end if; # 00 


if err_code=0 Then  # 01 判斷關帳
   set @isCnt=0;
   select rwid into @isCnt from toffdoc where closeStatus_z07 > '0' and rwid=@in_Rwid;
   if @isCnt > 0 Then set err_code=1; set @outMsg="無法修改、該筆資料已關帳"; end if;   
end if; # 01 判斷關帳


IF err_code = 0 Then # A01 判斷是否有足夠特休
  set @QuotaCtrl='0';
  select QuotaCtrl into @QuotaCtrl #特休類假別，但不是加班補休時 
  from tofftype 
  Where OffTypeGuid=@in_TypeGuid 
   And offtypeguid Not in (select offtypeguid from tOverType where offTypeGuid=@in_TypeGuid ); 
 
  if @debug='1' Then insert into t_log (note) values (concat("特休管控：",@QuotaCtrl)); end if;
  
  if @QuotaCtrl='1' Then # 特休類假別
       select ifnull(sum(Off_Mins_left),0) into @OffLeft_Mins # 計算請假當時，可用的特休時數
       from voffquota_status
       Where 1=1
        And Off_Mins_left > 0
        And Empguid         = @in_EmpGuid
        And OffTypeGuid     = @in_TypeGuid
        And Quota_Valid_ST  < @in_DateStart 
        And Quota_Valid_End > @in_DateStart; 

      if @OffLeft_Mins < @in_OffMins 
         Then set err_code='1'; set @outMsg=concat(@in_OfftypeDesc,"剩餘：",round(@OffLeft_Mins/60,1),"hr","  不夠使用"); 
      end if; 

  end if;

end if ; # A01 判斷特休

IF err_code = 0 Then # A02 判斷補休
 set @Is_Change=0;
 select count(*) into @Is_Change  
 from tovertype 
 Where OfftypeGuid=@in_TypeGuid ;  
 if @Is_Change>0 Then # A02-1 計算請假當時，剩餘補休
	select 
     ifnull(sum(off_mins_left),0) into @OffLeft_Mins 
     from `vovertooff_status` a
     Where 
          a.Off_Mins_Left > 0
      and a.empGuid     = @in_EmpGuid
      and a.offtypeguid = @in_TypeGuid 
      and a.OverEnd     < @in_DateStart  
      and a.Valid_end   > @in_DateStart  ;

      if @OffLeft_Mins < @in_OffMins 
         Then set err_code='1'; set @outMsg=concat(@in_OfftypeDesc,"剩餘：",round(@OffLeft_Mins/60,1),"hr","  不夠使用"); 
      end if; 
 end if;

end if; # A02 判斷補休

if err_code=0 Then # B01 班別錯誤出現上班時間重疊
    set @isCnt=0;
    set @dutyList='';
    select count(*),group_concat(a.dutydate order by 1) into @isCnt,@dutyList
    from vdutystd_emp a
     left join vdutystd_emp b on a.empguid=b.empguid 
      and a.dutydate != b.dutydate
      and b.dutydate between (a.dutydate- interval 1 day) And (a.dutydate+interval 1 day)  
    Where a.empguid=@in_Empguid
      and a.std_On < b.std_Off
      and a.std_Off > b.std_On
      and a.std_on <   @in_DateEnd
      and a.std_Off >  @in_DateStart  ;
    if @isCnt > 0 Then # 代表班別錯誤
       set err_code='1'; set @outMsg=concat("班別錯誤，請先檢查班別,錯誤日期：",@dutyList);   
    end if;

end if;


if err_code=0 Then # A03 多日假單，無法用於請半天
  select count(*),min(std_on),max(std_off) into @Cnt,@in_ST,@in_End
  from vdutystd_emp
  where empguid=@in_empguid
  and std_On <   @in_DateEnd
  and std_Off >  @in_DateStart  ;
  if @Cnt>1 And Not (@in_DateStart=@in_ST And  @in_DateEnd = @in_End) Then # A03-1
	 set err_code=1;
     set @outMsg="請假多日，起迄需等於該日上下班時間";
  end if; # A03-1
end if;  # A03



IF err_code = 0 And @in_Rwid = 0 Then # X01 新增資料至 toffdoc

  Insert into tOffDoc
  (offdocguid,empguid,offtypeguid,offdoc_start,offdoc_end,offdoc_mins,Note,ltuser,ltpid)
  select 
  uuid(),@in_EmpGuid,@in_TypeGuid,@in_DateStart,@in_DateEnd,@in_OffMins,@in_Note,@in_ltUser,@in_ltpid;

  set @Change_RWID = LAST_INSERT_ID(); /*新增時，尚無rwid，所以新增後需取得*/

  set @outMsg = "請假單新增成功";
  
end if; # IF err_code = 0 Then # 新增資料至 toffdoc

IF err_code = 0 And in_Rwid > 0 Then # X02 修改資料至 toffdoc

   update toffdoc set
	 offtypeguid= @in_TypeGuid
    ,offdoc_start= @in_DateStart
    ,offdoc_end= @in_DateEnd
    ,offdoc_mins= @in_OffMins
    ,Note= @in_Note
    ,ltuser= @in_ltUser
    ,ltpid= @in_ltpid
   Where closeStatus_z07='0' and rwid = @in_Rwid;  
   set @Change_RWID = @in_Rwid ; /*修改時，rwid等於 in_Rwid*/
   set @outMsg = "請假單修改成功";   


end if; # X02 

   set outMsg=@outMsg; 
   set outError=err_code;

IF err_code = 0 && 1 Then 
  call p_tovertooff_used_save(@in_OUguid,@in_ltUser,@in_ltpid,@Change_RWID); 
  call  p_toffquota_used_save(@in_OUguid,@in_ltUser,@in_ltpid,@Change_RWID);
  call    p_toffdoc_duty_save(@in_OUguid,@in_ltUser,@in_ltpid,@Change_RWID);
   
end if;

end