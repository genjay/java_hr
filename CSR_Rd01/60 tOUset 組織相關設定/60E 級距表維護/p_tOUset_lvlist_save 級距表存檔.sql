drop procedure if exists p_tOUset_lvlist_save;

delimiter $$ 

create procedure p_tOUset_lvlist_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
-- ,in_rwid                      int(10) unsigned
,in_type_z18                  varchar(36)
,in_Data                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END; 

set err_code=0; set outRwid=0; set outMsg='p_tOUset_lvlist_save 執行中';

if err_code=0 then # 輸入置入tmp01中
 drop table if exists tmp01;
 create temporary table tmp01 (rwid int,m_amt int) engine=myisam;
 set @sql=concat('insert into tmp01 (rwid,m_amt) values ',
 in_Data,';'); 
 
 prepare s1 from @sql;
 execute s1;
 insert into tmp01 (rwid,m_amt) values (0,0); # 不管使用者有沒有輸入，都加一筆 0 的級距
 alter table tmp01 add index i01 (m_amt);
 # 0 級距用途在於，若原本投保金額，與級距表完全不同時
 # 較容易發現
 -- 除錯時用 insert into tlog_proc (note) values (@sql);
end if;

if err_code=0 then # 90 資料更新，統一刪除再新增
-- start transaction;
 delete from tOUset_lvlist
 where OUguid=in_OUguid
   And type_Z18=in_type_z18;
 insert into tOUset_lvlist 
 (OUguid,LtUser,ltPid,type_z18,m_amt)
 Select distinct in_OUguid,in_LtUser,in_ltPid,in_type_z18,a.m_amt 
 from tmp01 a  
 where a.m_amt>=0 ;
 drop table if exists tmp01;
 set outMsg='修改完成';
-- commit;
end if; 

end; # begin