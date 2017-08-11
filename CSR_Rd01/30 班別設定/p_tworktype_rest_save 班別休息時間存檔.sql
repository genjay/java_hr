drop procedure if exists p_tworktype_rest_save;

delimiter $$ 

create procedure p_tworktype_rest_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_worktype_ID               varchar(36)
,in_Holiday                   tinyint(4)
,in_rest_stHHMM               time
,in_rest_time                 smallint(6)
,in_cuttime                   int(1)
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare is_worktype_Guid varchar(36);
declare varDate date default CURRENT_DATE ;
declare varDateST,varDateEnd datetime;

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tworktype_rest_save 執行中';

if err_code=0 && in_Rwid=0 then # 10 抓取及判斷班別
 set isCnt=0;
Select 
    rwid, worktype_Guid
into isCnt , is_Worktype_guid from
    tworktype
where
    ouguid = in_OUguid
        and worktype_id = in_worktype_ID;
 if isCnt=0 then set err_code=1; set outMsg='無此班別'; end if;
end if;

if err_code=0 && in_Rwid>0 then # 11 判斷有無異動
 set isCnt=0;
 Select rwid into isCnt 
 from vtworktype_rest a
 where a.ouguid=in_OUguid and a.rwid=in_Rwid
 And a.holiday=in_Holiday 
 And a.rest_stHHMM=in_rest_stHHMM
 And a.rest_time=in_rest_time
 And a.cuttime=in_cuttime
 And a.note=in_note;
 if isCnt>0 then set err_code=1; set outMsg=''; end if; # 無修改，所以不顯示
end if; # 11

if err_code=0 then # 21 判斷是否休息時間重疊
 # 已含休息(起)相同的錯誤
 Set isCnt=0;
 Set varDateST =str_to_date(concat(vardate,in_rest_stHHMM),'%Y-%m-%d%H:%i:%s') ;
 Set varDateEnd=str_to_date(concat(vardate,in_rest_stHHMM),'%Y-%m-%d%H:%i:%s') + interval in_rest_time minute;
 
Select 
    rwid
into isCnt from
    vtworktype_rest a
Where
    rwid != in_Rwid And OUguid = in_OUguid
        And holiday = in_Holiday
        And varDateST < (str_to_date(concat(vardate, a.rest_stHHMM),
            '%Y-%m-%d%H:%i:%s') + interval a.rest_time minute)
        And varDateEnd > str_to_date(concat(vardate, a.rest_stHHMM),
            '%Y-%m-%d%H:%i:%s')
limit 1;
if isCnt>0 then set err_code=1; set outMsg=concat(in_rest_stHHMM,'時間重疊'); end if;
 
end if;

if err_code=0 && in_Rwid=0 then # 90 新增
Insert into tworktype_rest
 (Worktype_Guid,Holiday,rest_stHHMM,rest_time,cuttime,note)
 values 
 (is_Worktype_guid,in_Holiday,in_rest_stHHMM,in_rest_time,in_cuttime,in_note);
 set outMsg=concat(date_format(in_rest_stHHMM,'%h:%i'),'新增完成');
 set outRwid=last_insert_id();
end if; # 90 新增
 
if err_code=0 && in_Rwid>0 then # 90 修改
 Update tworktype_rest Set
  ltUser              = in_ltUser
 ,ltpid               = in_ltpid 
 ,Holiday             = in_Holiday
 ,rest_stHHMM         = in_rest_stHHMM
 ,rest_time           = in_rest_time
 ,cuttime             = in_cuttime
 ,note                = in_note
  Where rwid=in_Rwid;
 set outMsg=concat(date_format(in_rest_stHHMM,'%h:%i'),'修改完成');
 set outRwid=in_Rwid;
end if; # 90 修改 

end; # begin