drop procedure if exists p_tovertype_save;

delimiter $$ 

create procedure p_tovertype_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_Overtype_ID               varchar(36)
,in_Overtype_Desc             varchar(36)
,in_Paytype_Z01               varchar(36)
,in_OverA_Mins                int(11)
,in_OverB_Mins                int(11)
,in_OverA_Rate                decimal(10,4)
,in_OverB_Rate                decimal(10,4)
,in_OverC_Rate                decimal(10,4)
,in_OverH_Rate                decimal(10,4)
,in_OverA_Money               decimal(10,4)
,in_OverB_Money               decimal(10,4)
,in_OverC_Money               decimal(10,4)
,in_OverH_Money               decimal(10,4)
,in_Over_Unit                 int(11)
,in_Valid_time                int(11)
,in_Valid_time_Z08            varchar(36)
,in_Stop_used                 int(1)
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare is_overtype_id varchar(36);
/*
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
*/
/*
call p_tovertype_save
(
'microjet','',''
,'0' #in_rwid                      int(10) unsigned
,'A' #in_Overtype_ID               varchar(36)
,'A' # in_Overtype_Desc             varchar(36)
,'' #in_Paytype_Z01               varchar(36)
,'120' #in_OverA_Mins                int(11)
,'240' #in_OverB_Mins                int(11)
,'1.333' #in_OverA_Rate                decimal(10,4)
,'1.666' #in_OverB_Rate                decimal(10,4)
,'2.000' #in_OverC_Rate                decimal(10,4)
,'2.000' #in_OverH_Rate                decimal(10,4)
,'0' #in_OverA_Money               decimal(10,4)
,'0' #in_OverB_Money               decimal(10,4)
,'0' #in_OverC_Money               decimal(10,4)
,'0' #in_OverH_Money               decimal(10,4)
,'60' #in_Over_Unit                 int(11)
,'2' #in_Valid_time                int(11)
,'a' #in_Valid_time_Z08            varchar(36)
,'0'
,'' #in_note                      text
,@a,@b,@c
)  
;

*/
 
set err_code=0; set outRwid=0; set outMsg='p_tovertype_del 執行中';

if err_code=0 then # 判斷是否有無修改
  set isCnt=0; 
  Select rwid into isCnt 
   From tovertype 
  Where rwid=in_Rwid And Overtype_ID=in_Overtype_ID And Overtype_Desc=in_Overtype_Desc And Paytype_Z01=in_Paytype_Z01 And OverA_Mins=in_OverA_Mins And OverB_Mins=in_OverB_Mins And OverA_Rate=in_OverA_Rate And OverB_Rate=in_OverB_Rate And OverC_Rate=in_OverC_Rate And OverH_Rate=in_OverH_Rate And OverA_Money=in_OverA_Money And OverB_Money=in_OverB_Money And OverC_Money=in_OverC_Money And OverH_Money=in_OverH_Money And Over_Unit=in_Over_Unit And Valid_time=in_Valid_time And Valid_time_Z08=in_Valid_time_Z08 And Stop_used=in_Stop_used And note=in_note;
 if isCnt>0 then set err_code=1; set outMsg='資料無修改'; end if;
 end if;
 
if err_code=0 && in_Rwid>0 then # 10 
 set isCnt=0;
 Select rwid,overtype_id into isCnt,is_overtype_id from tovertype where  ouguid=in_ouguid And rwid = in_Rwid;
 if isCnt=0 then set err_code=1; set outMsg='資料不存在'; end if;
end if; # 10

if err_code=0 then # 20 
 if err_code=0 && in_OverA_Mins<1 then set err_code=1; set outMsg='A時段需大於0，且需整數(預設：120)'; end if;
 if err_code=0 && in_OverB_Mins<=in_OverA_Mins then set err_code=1; set outMsg='B時段需大於A時段，且需整數(預設：240)'; end if;

 if err_code=0 && in_OverA_Rate<0 then set err_code=1; set outMsg='比率必需大於0'; end if;
 if err_code=0 && in_OverB_Rate<0 then set err_code=1; set outMsg='比率必需大於0'; end if;
 if err_code=0 && in_OverC_Rate<0 then set err_code=1; set outMsg='比率必需大於0'; end if;
 if err_code=0 && in_OverH_Rate<0 then set err_code=1; set outMsg='比率必需大於0'; end if;
 if err_code=0 && in_OverA_Money<0 then set err_code=1; set outMsg='A時段 金額不可為負數'; end if;
 if err_code=0 && in_OverB_Money<0 then set err_code=1; set outMsg='B時段 金額不可為負數'; end if;
 if err_code=0 && in_OverC_Money<0 then set err_code=1; set outMsg='C時段 金額不可為負數'; end if;
 if err_code=0 && in_OverH_Money<0 then set err_code=1; set outMsg='假日加班比率 金額不可為負數'; end if;


 if err_code=0 && in_Over_Unit=0 then set err_code=1; set outMsg='加班累進單位，最小1(預設：30)'; end if;

 if err_code=0 && in_Valid_time<0 then set err_code=1; set outMsg='補休期限，不可為負數'; end if;

 if err_code=0 && ifnull(in_Valid_time_Z08,'')='' then set err_code=1; set outMsg='補休期限，單位未選擇'; end if;


end if; # 20




if err_code=0 && in_Rwid=0 then # 90
Insert into tovertype
 (OverType_Guid,OUguid,Overtype_ID,Overtype_Desc,Paytype_Z01,OverA_Mins,OverB_Mins,OverA_Rate,OverB_Rate,OverC_Rate,OverH_Rate,OverA_Money,OverB_Money,OverC_Money,OverH_Money,Over_Unit,Valid_time,Valid_time_Z08,Stop_used,note)
 values 
 (uuid(),in_OUguid,in_Overtype_ID,in_Overtype_Desc,in_Paytype_Z01,in_OverA_Mins,in_OverB_Mins,in_OverA_Rate,in_OverB_Rate,in_OverC_Rate,in_OverH_Rate,in_OverA_Money,in_OverB_Money,in_OverC_Money,in_OverH_Money,in_Over_Unit,in_Valid_time,in_Valid_time_Z08,in_Stop_used,in_note);
 set outMsg=concat('「',in_Overtype_ID,'」','新增成功');
 set outRwid=last_insert_id();
end if; # 90

if err_code=0 && in_Rwid>0 then # 90 修改
Update tovertype Set
  ltUser              = in_ltUser
 ,ltpid               = in_ltpid
 ,Overtype_ID         = in_Overtype_ID
 ,Overtype_Desc       = in_Overtype_Desc
 ,Paytype_Z01         = in_Paytype_Z01
 ,OverA_Mins          = in_OverA_Mins
 ,OverB_Mins          = in_OverB_Mins
 ,OverA_Rate          = in_OverA_Rate
 ,OverB_Rate          = in_OverB_Rate
 ,OverC_Rate          = in_OverC_Rate
 ,OverH_Rate          = in_OverH_Rate
 ,OverA_Money         = in_OverA_Money
 ,OverB_Money         = in_OverB_Money
 ,OverC_Money         = in_OverC_Money
 ,OverH_Money         = in_OverH_Money
 ,Over_Unit           = in_Over_Unit
 ,Valid_time          = in_Valid_time
 ,Valid_time_Z08      = in_Valid_time_Z08
 ,Stop_used           = in_Stop_used
 ,note                = in_note
  Where rwid=in_Rwid;
 set outMsg=concat('「',in_Overtype_ID,'」','修改成功');
 set outRwid=in_Rwid;
end if; # 90 修改

end; # begin