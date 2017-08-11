drop procedure if exists p_tOUset_save;

delimiter $$ 

create procedure p_tOUset_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_ouID                      varchar(36)
,in_ouName                    varchar(255)
,in_OU_URL                    text
,in_Over_FreeTax_perMonth     int(11)
,in_Days_per_Month            int(11)
,in_Hours_per_Day             int(11)
,in_Close_Date                date
,in_WorkType_ID               varchar(36)
,in_Welfare_Rate              decimal(5,3)
,in_Tax1_Rate                 decimal(5,3)
,in_SEQ                       int(11)
,in_LP_Rate                   decimal(5,3)
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare in_WorkType_Guid varchar(36);
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

if err_code=0 then # 判斷是否有無修改
  set isCnt=0; 
  Select rwid into isCnt 
   From tOUset 
  Where rwid=in_Rwid And ouID=in_ouID And ouName=in_ouName And OU_URL=in_OU_URL And Over_FreeTax_perMonth=in_Over_FreeTax_perMonth And Days_per_Month=in_Days_per_Month And Hours_per_Day=in_Hours_per_Day And Close_Date=in_Close_Date 
  And WorkType_Guid=(Select Worktype_Guid from tWorktype Where OUguid=in_OUguid And Worktype_ID=in_WorkType_ID)
  And Welfare_Rate=in_Welfare_Rate And Tax1_Rate=in_Tax1_Rate And SEQ=in_SEQ And LP_Rate=in_LP_Rate And note=in_note;
 if isCnt>0 then set err_code=1; set outMsg='資料無修改'; end if;
 end if;



if err_code=0 then # 10 抓取班別，因班別可能未設定，所以沒撈到，也可以往下執行
 set in_WorkType_Guid='';
 Select Worktype_Guid into in_WorkType_Guid from tworktype where ouguid=in_OUguid and worktype_id=in_WorkType_ID;
end if; # 10

if err_code=0 && in_Over_FreeTax_perMonth<0 then # 20
 set err_code=1; set outMsg='免稅加班不可為負數，請輸入正整數，預設(46)'; 
end if; # 20

if err_code=0 && Not in_Days_per_Month in ('0','30') then # 21
 set err_code=1; set outMsg='計薪天數，只能為 0、30(0 代表以實際天數計算)'; 
end if;

if err_code=0 && Not in_Hours_per_Day between 1 and 12 then # 22
 set err_code=1; set outMsg='計薪時數，只能輸入1~12間，預設(8)';
end if; # 22

if err_code=0 && in_Close_Date >sysdate() then
 set err_code=1; set outMsg='關帳日不能超過今日';
end if;

if err_code=0 && Not in_Welfare_Rate between 0 and 10 then # 23
 set err_code=1; set outMsg='福利金，只能輸入0~10間，預設(0.5)';
end if; # 23

if err_code=0 && Not in_Tax1_Rate between 0 and 99 then # 24
 set err_code=1; set outMsg='所得稅，只能輸入0~99間，預設(5)';
end if; # 24

if err_code=0 && Not in_LP_Rate between 0 and 99 then # 25
 set err_code=1; set outMsg='勞退比率(雇主)，只能輸入0~99間，預設(6)';
end if; # 25


if err_code=0 && in_Rwid=0 then # 90 新增 
 set outMsg=concat('「',in_ouID,'」','此程式不處理新增');
end if; # 90 
 
 if err_code=0 && in_Rwid>0 then # 90 
Insert into tlog_proc (ltpid,note) values ('90 修改',in_note);
Update tOUset Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid
 ,ouID                          = in_ouID
 ,ouName                        = in_ouName
 ,OU_URL                        = in_OU_URL
 ,Over_FreeTax_perMonth         = in_Over_FreeTax_perMonth
 ,Days_per_Month                = in_Days_per_Month
 ,Hours_per_Day                 = in_Hours_per_Day
 ,Close_Date                    = in_Close_Date
 ,WorkType_Guid                 = in_WorkType_Guid
 ,Welfare_Rate                  = in_Welfare_Rate
 ,Tax1_Rate                     = in_Tax1_Rate
 ,SEQ                           = in_SEQ
 ,LP_Rate                       = in_LP_Rate
 ,note                          = in_note
  Where rwid=in_Rwid;
 set outMsg=concat('「',in_ouID,'」','存檔成功');
 set outRwid=in_Rwid;
end if; # 90

end; # begin