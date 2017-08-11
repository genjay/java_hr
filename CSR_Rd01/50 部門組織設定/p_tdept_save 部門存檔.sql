drop procedure if exists p_tdept_save;

delimiter $$ 

create procedure p_tdept_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_Dep_ID                    varchar(36)
,in_Dep_Desc                  varchar(36)
,in_Up_Dep_ID                 varchar(36)
,in_WorkType_ID               varchar(36)
,in_stop_used                 int(1)
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare is_dep_iD        varchar(36);
declare is_dep_Guid      varchar(36);
declare in_WorkType_Guid varchar(36);
declare in_Up_Dep_Guid   varchar(36);

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
/*
call  p_tdept_save
(
'microjet','',''
,'0' #,in_rwid                      int(10) unsigned
,'0000' #,in_Dep_ID                    varchar(36)
,'0000說明' #,in_Dep_Desc                  varchar(36)
,'' #,in_Up_Dep_Guid               varchar(36)
,'' #,in_WorkType_Guid             varchar(36)
,'0' #,in_stop_used                 int(1)
,@a,@b,@c
)  ;

*/

set err_code=0; set outRwid=0; set outMsg='p_tdept_save 執行中';

if err_code=0 then # 判斷是否有無修改
  set isCnt=0; 
  Select rwid into isCnt 
   From vtdept 
  Where rwid=in_Rwid And dep_id=in_dep_id And Dep_Desc=in_Dep_Desc And ifnull(Up_Dep_ID,'')=in_Up_Dep_ID And ifnull(worktype_ID,'')=in_worktype_ID And stop_used=in_stop_used And note=in_note;
 if isCnt>0 then set err_code=1; set outMsg='資料無修改'; end if;
 end if;

if err_code=0 && in_Rwid>0 then # 10 用rwid抓出 dep_ID,dep_Guid及判斷是否存在資料
 set isCnt=0;
 Select rwid,dep_ID,dep_Guid into isCnt,is_dep_ID,is_dep_Guid from tdept where  ouguid=in_ouguid And rwid = in_Rwid;
 if isCnt=0 then set err_code=1; set outMsg='資料不存在'; end if;
end if; # 10

if err_code=0 && in_Up_Dep_ID!='' then # 20 判斷及抓取上層部門的guid,in_UP_Dep_ID不處理(可以不需上層部門)
 set isCnt=0;
 Select rwid,dep_Guid into isCnt,in_Up_Dep_Guid from tdept where ouguid=in_ouguid and dep_ID=in_Up_Dep_ID;
 if isCnt=0 then set err_code=1; set outMsg='上層部門錯誤'; end if;
end if; # 20

if err_code=0 then # 20-1 判斷上層部門是不是自己，上層部門不能為自己
 if is_dep_Guid=in_Up_Dep_Guid then set err_code=1; set outMsg='上層部門不可設自己'; end if;
end if; # 20-1

if err_code=0 && in_WorkType_ID!='' then # 21 判斷及抓取預設班別guid
 set isCnt=0;
 Select rwid,worktype_Guid into isCnt,in_WorkType_Guid from tworktype where ouguid=in_ouguid and WorkType_ID=in_WorkType_ID;
 if isCnt=0 then set err_code=1; set outMsg='預設班別錯誤'; end if;
end if; # 22

if err_code=0 then # 23 判斷有無其他相同ID
 set isCnt=0;
 Select rwid into iscnt from tdept where OUguid=in_OUguid and dep_ID=in_Dep_ID and rwid!=in_Rwid limit 1;
 if isCnt>0 then set err_code=1; set outMsg='已存在其他相同資料'; end if;
end if; # 23

if err_code=0 then # 50 判斷上層部門，有沒有發生無限回圈(上層部門的上層部門，設成自己)
 set isCnt=0;
 # 還沒想到怎麼寫比較好，想到時補上去
end if; # 50 

if err_code=0 && in_Rwid=0 then # 90 
Insert into tdept
 (Dep_Guid,OUguid,Dep_ID,Dep_Desc,Up_Dep_Guid,WorkType_Guid,stop_used,note)
 values 
 (uuid(),in_OUguid,in_Dep_ID,in_Dep_Desc,in_Up_Dep_Guid,in_WorkType_Guid,in_stop_used,in_note);
 set outMsg=concat('「',is_dep_ID,'」','新增成功');
 set outRwid=last_insert_id();
end if; # 90

if err_code=0 && in_Rwid>0 then # 90 修改
Update tdept Set
  ltUser              = in_ltUser
 ,ltpid               = in_ltpid
 ,Dep_ID              = in_Dep_ID
 ,Dep_Desc            = in_Dep_Desc
 ,Up_Dep_Guid         = in_Up_Dep_Guid
 ,WorkType_Guid       = in_WorkType_Guid
 ,stop_used           = in_stop_used
 ,note                = in_note
  Where rwid=in_Rwid;
 set outMsg=concat('「',is_dep_ID,'」','修改成功');
 set outRwid=in_Rwid;
end if; # 90 修改
 
end; # begin