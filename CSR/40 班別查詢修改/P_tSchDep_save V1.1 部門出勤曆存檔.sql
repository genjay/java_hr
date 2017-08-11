drop procedure if exists p_tSchDep_save;

delimiter $$

create procedure p_tSchDep_save
(
 in_OUguid   varchar(36)
,in_ltUser   varchar(36)
,in_ltpid    varchar(36) 
,in_DepID    varchar(36) 
,in_Dutydate varchar(36) 
,in_holiday  varchar(36) 
,in_WorkID   varchar(36) 
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)

begin
/*
執行範例 
call p_tSchDep_save
(
 'microjet','ltuser','ltpid'
,'A00514'    #in_DepID    varchar(36) 
,'20140701' #in_Dutydate varchar(36) 
,'1'        #in_holiday  varchar(36) 
,'B'        #in_WorkID   varchar(36) 
,@a,@b,@c
);

select @a,@b,@c;

*/

declare tlog_note text;
declare isCnt int;
declare tmpXX1 text;
declare in_WorkGuid varchar(36);
declare in_DepGuid  varchar(36);
declare droptable int default 1; # 1 drop temptable /0 不drop 除錯用 
set err_code = 0;
set tlog_note= concat("call p_tSchDep_save(\n'"
,in_OUguid   ,"',\n'"
,in_ltUser   ,"',\n'"
,in_ltpid    ,"',\n'"
,in_DepID    ,"',\n'"
,in_Dutydate ,"',\n'"
,in_holiday  ,"',\n'" 
,in_WorkID   ,"',\n" 
,'@a'  ,","
,'@b'  ,","
,'@c' 
,");");
call p_tlog(in_ltPid,tlog_note);
call p_SysSet(1);
set outMsg='p_tSchEmp_save,開始';

if err_code=0 Then  # C 出勤日判斷
   set tmpXX1  = f_DtimeCheck(f_removeX(concat(in_Dutydate,'0000'))); 
   if  tmpXX1 !='OK' Then set err_code=1;  set outMsg=concat("出勤日  ",tmpXX1); end if; 
   if err_code=0 Then set in_Dutydate = str_to_date(concat(f_removeX(  in_Dutydate)),'%Y%m%d'); end if;
   if droptable=0 Then insert into t_log(ltpid,note) values ('p_tSchEmp_save','出勤日判斷'); end if;
end if; # C

if err_code=0 Then # 50 產生使用者要修改的班別，上下班時間
  drop table if exists tmp_p_tSchDep_save_01;
  create temporary table tmp_p_tSchDep_save_01 as
  Select  
   str_to_date(concat(in_Dutydate,d.OnDutyHHMM),'%Y-%m-%d%H:%i:%s')
   + interval d.OnNext_z04 day As Std_ON
  ,str_to_date(concat(in_Dutydate,d.OffDutyHHMM),'%Y-%m-%d%H:%i:%s')
   + interval d.OffNext_Z04 day As Std_Off 
  from vtworkinfo d where ouguid=in_OUguid And workID=in_WorkID; 
  call p_tlog('','產生tmp_p_tSchDep_save_01');
end if;

IF err_code=0 then # 60 跟昨天判斷，上班時間有無重疊 
  set isCnt=0; 
  Select count(*) into isCnt
  from tmp_p_tSchDep_save_01 a
  left join vdutystd_dep b on b.ouguid=in_OUguid and b.depid=in_DepID
  and b.dutydate =(in_dutydate - interval 1 day)
  Where a.Std_on < b.Std_Off And a.Std_Off > b.Std_On;
  if isCnt>0 Then set err_code=1; set outMsg=concat(in_Dutydate,' 時間發生重疊'); end if;
end if; # 60

if err_code=0 Then # 抓班別guid
  set in_Workguid='';
  Select codeguid into in_Workguid From tcatcode Where OUguid=in_OUguid And CodeID=in_WorkID And Syscode='A01';
  if in_Workguid='' Then set err_code=1; set outMsg='抓workguid,錯誤'; end if;
end if;

if err_code=0 Then # 抓部門guid
  set in_DepGuid='';
  Select codeguid into in_DepGuid From tcatcode Where syscode='A07' And OUguid=in_OUguid And CodeID=in_DepID ;
  if in_DepGuid='' Then set err_code=1; set outMsg='抓depguid，錯誤'; end if;
end if;

if err_code=0 and 1 then # 90 修改班別
   insert into tSchdep (Depguid,dutydate,holiday,workguid)
   values (in_DepGuid,in_dutydate,in_holiday,in_workguid)
   On duplicate key update
    holiday=in_holiday
   ,workguid=in_workguid;
  set outMsg=concat(in_Dutydate,' 修改成功');
end if; # 90 

if 1=1 then # 結束 刪除tmp table 
  drop table if exists tmp_p_tSchDep_save_01;
  drop table if exists tmp_p_tSchDep_save_02;
end if;
 

end;