drop procedure if exists p_Duty_MonthSum;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_Duty_MonthSum`(
 in_OUguid   varchar(36)
,in_ltUser   varchar(36)
,in_ltpid    varchar(36)  
,in_YYYYMM   varchar(36) # 年月 201406
,in_seq      varchar(36) # default 0 
,in_DateStart  varchar(36)  # 20140601
,in_DateEnd    varchar(36)  # 20140630
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out outError int  # err_code
)
begin
/*
call p_Duty_MonthSum(
'microjet','ltUser','PID'
,'201406' # in_YYYYMM   varchar(36) # 年月 201406
,'0'      # in_seq      varchar(36) # default 0 
,'20140601' # in_DateStart  varchar(36)  # 20140601
,'20140630' # in_DateEnd    varchar(36)  # 20140630
,@a,@b,@c
);

*/
DECLARE err_code int default '0'; 
DECLARE droptable int default '0'; # 0 代表測試中 1，正常使用

call p_SysSet(1);
set @in_OUguid = IFNULL(in_OUguid,'');
set @in_ltUser = IFNULL(in_ltUser,'');
set @in_ltpid  = IFNULL(in_ltpid,'');  
set @in_YYYYMM = '';
set @outRwid   = 0;
set @outMsg    =''; 

if err_code=0 Then # A 日期(起)判斷
  set @xx1 = f_DtimeCheck(f_removeX(concat(in_YYYYMM,'010000')));
  if @xx1 !='OK' Then set err_code=1; set @outMsg=concat("時間(起) ",@xx1); end if;
  if err_code=0 Then set @in_YYYYMM= f_removeX(in_YYYYMM) ; end if;
  if droptable=0 Then insert into t_log(ltpid,note) values ('p_Duty_MonthSum','日期(起)判斷'); end if;
end if; # A 

if err_code=0 Then # A 日期(起)判斷
  set @xx1 = f_DtimeCheck(f_removeX(concat(in_DateStart,'0000')));
  if @xx1 !='OK' Then set err_code=1; set @outMsg=concat("時間(起) ",@xx1); end if;
  if err_code=0 Then set @in_DateStart= str_to_date(concat(f_removeX(in_DateStart)),'%Y%m%d'); end if;
  if droptable=0 Then insert into t_log(ltpid,note) values ('p_Duty_MonthSum','日期(起)判斷'); end if;
end if; # A 
 
if err_code=0 Then # B 日期(迄)判斷
   set @xx2 = f_DtimeCheck(f_removeX(concat(in_DateEnd,'0000')));
   if @xx2 !='OK' Then set err_code=1;  set @outMsg=concat("時間(迄) ",@xx2); end if;
   if err_code=0 Then set @in_DateEnd  = str_to_date(concat(f_removeX(  in_DateEnd)),'%Y%m%d'); end if;
   if droptable=0 Then insert into t_log(ltpid,note) values ('p_Duty_MonthSum','日期(迄)判斷'); end if;
end if; # B 

if err_code=0 Then # B-1 判斷起迄
   if in_DateStart >= in_DateEnd Then set err_code=1; set @outMsg="時間起迄，錯誤"; end if; 
end if;

   if 1 Then # # ZZ End
      set outMsg=if(ifnull(@outMsg,'')='',"成功",@outMsg);
      set outError = 0;
   end if;




end # Begin