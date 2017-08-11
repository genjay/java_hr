drop procedure if exists p_tworktype_save;

delimiter $$ 

create procedure p_tworktype_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_worktype_ID               varchar(36)
,in_worktype_Desc             varchar(36)
,in_OnNext_Z04                tinyint(4) # 無作用，改上下班時間判斷，產生
,in_OnDutyHHMM                time
,in_OffNext_Z04               tinyint(4) # 無作用，改上下班時間判斷，產生
,in_OffDutyHHMM               time
,in_BeforeBuffer              int(11)
,in_DelayBuffer               int(11)
,in_OverBeforMin              int(11)
,in_OverAfterMin              int(11)
,in_OverHolidayMin            int(11)
,in_RangeSt                   int(11)
,in_RangeEnd                  int(11)
,in_Working_Mins              int(11)
,in_Stop_used                 int(1)
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare is_worktype_id varchar(36);
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
/*
call p_tworktype_save
(
 'microjet','',''
,0 #in_rwid                      int(10) unsigned 
,'A' #in_worktype_ID               varchar(36)
,'A 說明' #in_worktype_Desc             varchar(36)
,'0' #in_OnNext_Z04                tinyint(4)
,'080000' #in_OnDutyHHMM                time
,'0' #in_OffNext_Z04               tinyint(4)
,'172000' #in_OffDutyHHMM               time
,'0' #in_BeforeBuffer              int(11)
,'30' #in_DelayBuffer               int(11)
,'60' #in_OverBeforMin              int(11)
,'120' #in_OverAfterMin              int(11)
,'120' #in_OverHolidayMin            int(11)
,'360' #in_RangeSt                   int(11)
,'480' #in_RangeEnd                  int(11)
,'480' #in_Working_Mins              int(11)
,'' #in_note                      text 
,@a,@b,@c
)  ;

*/
 
set err_code=0; set outRwid=0; set outMsg='p_demo 執行中'; 

if err_code=0 then # 判斷是否有無修改
  set isCnt=0; 
  Select rwid into isCnt 
   From tworktype 
  Where rwid=in_Rwid And worktype_ID=in_worktype_ID And worktype_Desc=in_worktype_Desc And OnNext_Z04=in_OnNext_Z04 And OnDutyHHMM=in_OnDutyHHMM And OffNext_Z04=in_OffNext_Z04 And OffDutyHHMM=in_OffDutyHHMM And BeforeBuffer=in_BeforeBuffer And DelayBuffer=in_DelayBuffer And OverBeforMin=in_OverBeforMin And OverAfterMin=in_OverAfterMin And OverHolidayMin=in_OverHolidayMin And RangeSt=in_RangeSt And RangeEnd=in_RangeEnd And Working_Mins=in_Working_Mins And Stop_used=in_Stop_used And note=in_note;
 if isCnt>0 then set err_code=1; set outMsg='資料無修改'; end if;
 end if;

if err_code=0 && in_Rwid>0 then # 10
  set isCnt=0;
  Select rwid,worktype_id into isCnt,is_worktype_id from tworktype where  ouguid=in_ouguid And rwid = in_Rwid;
  if isCnt=0 then set err_code=1; set outMsg='資料不存在'; end if;
end if; # 10

if err_code=0 then # 判斷上下班時間合理性
 set  in_OnNext_Z04=0;
 set in_OffNext_Z04=0;
 set  @dayOn = str_to_date(concat(date(sysdate()),' ',  in_OnDutyHHMM),'%Y-%m-%d %H:%i:%s') ;
 set  @dayOff= str_to_date(concat(date(sysdate()),' ',  in_OffDutyHHMM),'%Y-%m-%d %H:%i:%s') ;
 insert into tlog_proc (note) values (@dayOff);
 if @dayOn>=@dayOff then set in_OffNext_Z04=1; end if;
 set  @dayOff=@dayOff + interval in_OffNext_Z04 day; 

 set @t_min=f_strIndex(timediff(@dayOff,@dayOn),':',1);
 if @t_min>13 then set err_code=1; set outMsg='上下班時間超過 13小時'; end if; 

end if;

if err_code=0 && in_BeforeBuffer not between 0 And 999 then # 21 檢查彈性時間 上班前
 set err_code=1 ; set outMsg='彈性時間，範圍 0~999';
end if; # 22

if err_code=0 && in_DelayBuffer not between 0 And 999 then # 22 檢查彈性時間 下班前
 set err_code=1 ; set outMsg='彈性時間，範圍 0~999';
end if; # 22

if err_code=0 && in_OverBeforMin not between 1 And 999 then # 23 檢查提前加班，可申報最小值
 set err_code=1 ; set outMsg='加班最小申報數，範圍 1~999';
end if; # 23
if err_code=0 && in_OverAfterMin not between 1 And 999 then # 24
 set err_code=1 ; set outMsg='加班最小申報數，範圍，範圍 1~999';
end if; # 24
if err_code=0 && in_OverHolidayMin not between 1 And 999 then # 25
 set err_code=1 ; set outMsg='假日加班最小申報數，範圍 1~999';
end if; # 25

if err_code=0 && in_RangeSt not between 1 And 999 then # 26 刷卡範圍起
 set err_code=1 ; set outMsg='刷卡抓取，範圍 1~999，預設360/480';
end if; # 25
if err_code=0 && in_RangeEnd not between 1 And 999 then # 27 刷卡範圍迄
 set err_code=1 ; set outMsg='刷卡抓取，範圍 1~999，預設360/480';
end if; # 25

if err_code=0 && in_Rwid=0 then # 90 
Insert into tworktype
 (Worktype_Guid,OUguid,worktype_ID,worktype_Desc,OnNext_Z04,OnDutyHHMM,OffNext_Z04,OffDutyHHMM,BeforeBuffer,DelayBuffer,OverBeforMin,OverAfterMin,OverHolidayMin,RangeSt,RangeEnd,Working_Mins,Stop_used,note)
 values 
 (uuid(),in_OUguid,in_worktype_ID,in_worktype_Desc,in_OnNext_Z04,in_OnDutyHHMM,in_OffNext_Z04,in_OffDutyHHMM,in_BeforeBuffer,in_DelayBuffer,in_OverBeforMin,in_OverAfterMin,in_OverHolidayMin,in_RangeSt,in_RangeEnd,in_Working_Mins,in_Stop_used,in_note);
set outMsg=concat('「',in_worktype_ID,'」','新增完成');
 set outRwid=last_insert_id();
end if; # 90 

if err_code=0 && in_Rwid>0 then # 90 修改
Update tworktype Set
  ltUser              = in_ltUser
 ,ltpid               = in_ltpid
 ,worktype_ID         = in_worktype_ID
 ,worktype_Desc       = in_worktype_Desc
 ,OnNext_Z04          = in_OnNext_Z04
 ,OnDutyHHMM          = in_OnDutyHHMM
 ,OffNext_Z04         = in_OffNext_Z04
 ,OffDutyHHMM         = in_OffDutyHHMM
 ,BeforeBuffer        = in_BeforeBuffer
 ,DelayBuffer         = in_DelayBuffer
 ,OverBeforMin        = in_OverBeforMin
 ,OverAfterMin        = in_OverAfterMin
 ,OverHolidayMin      = in_OverHolidayMin
 ,RangeSt             = in_RangeSt
 ,RangeEnd            = in_RangeEnd
 ,Working_Mins        = in_Working_Mins
 ,Stop_used           = in_Stop_used
 ,note                = in_note
  Where  ouguid=in_ouguid And rwid=in_Rwid;
  set outMsg=concat('「',in_worktype_ID,'」','修改完成');
 set outRwid=in_Rwid;
end if; # 90 修改
 
 
end; # begin